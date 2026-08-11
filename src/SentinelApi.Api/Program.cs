using System;
using System.Text;
using System.Threading.RateLimiting;
using SentinelApi.Api.Middlewares;
using SentinelApi.Core.Security;
using SentinelApi.Core.Services;
using SentinelApi.Infrastructure.Data;
using SentinelApi.Infrastructure.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;

var builder = WebApplication.CreateBuilder(args);

// 1. Database Configuration (Uses PostgreSQL when connection string is provided, or in-memory if specified)
bool useInMemory = builder.Configuration.GetValue<bool>("UseInMemoryDatabase", false);
string rawConnectionString = builder.Configuration.GetConnectionString("DefaultConnection") 
    ?? "Host=localhost;Port=5433;Database=sentinel_db;Username=secuser;Password=SecLabPass2026!";
string connectionString = NormalizePostgresConnectionString(rawConnectionString);

builder.Services.AddDbContext<AppDbContext>(options =>
{
    if (useInMemory)
    {
        options.UseInMemoryDatabase("SentinelApiDb");
    }
    else
    {
        options.UseNpgsql(connectionString);
    }
});

// 2. Register Security Core & Cryptography Services
builder.Services.AddSingleton<JwtTokenSettings>(sp => new JwtTokenSettings
{
    SecretKey = builder.Configuration["Jwt:SecretKey"] ?? "SUPER_SECRET_SECURITY_LAB_KEY_AT_LEAST_256_BITS_LONG!",
    Issuer = builder.Configuration["Jwt:Issuer"] ?? "SentinelApi",
    Audience = builder.Configuration["Jwt:Audience"] ?? "SentinelApiUsers",
    AccessTokenExpirationMinutes = 15,
    RefreshTokenExpirationDays = 7
});

builder.Services.AddSingleton<IEncryptionService, AesGcmEncryptionService>();
builder.Services.AddSingleton<IPasswordHasher, Argon2PasswordHasher>();
builder.Services.AddSingleton<IJwtTokenService, JwtTokenService>();
builder.Services.AddSingleton<IFileSanitizer, FileSanitizerService>();
builder.Services.AddSingleton<IXssSanitizer, XssSanitizerService>();
builder.Services.AddScoped<ISecureFileStorageService, SecureFileStorageService>();
builder.Services.AddScoped<IAuditLogService, AuditLogService>();
builder.Services.AddSingleton<IEmailService, BrevoEmailService>();

// 3. Configure JWT Authentication & Authorization
var jwtSettings = builder.Services.BuildServiceProvider().GetRequiredService<JwtTokenSettings>();
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSettings.SecretKey)),
        ValidateIssuer = true,
        ValidIssuer = jwtSettings.Issuer,
        ValidateAudience = true,
        ValidAudience = jwtSettings.Audience,
        ValidateLifetime = true,
        ClockSkew = TimeSpan.Zero
    };
});

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy => policy.RequireRole("Admin"));
    options.AddPolicy("AuditorOrAdmin", policy => policy.RequireRole("Admin", "SecurityAuditor"));
});

// 4. Configure ASP.NET Core Rate Limiting
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

    options.AddFixedWindowLimiter("StrictPolicy", opt =>
    {
        opt.PermitLimit = 5;
        opt.Window = TimeSpan.FromSeconds(30);
        opt.QueueLimit = 0;
    });

    options.OnRejected = async (context, token) =>
    {
        context.HttpContext.Response.StatusCode = StatusCodes.Status429TooManyRequests;
        context.HttpContext.Response.ContentType = "application/json";
        await context.HttpContext.Response.WriteAsync(
            "{\"Success\": false, \"Message\": \"SECURITY ALERT: Rate limit threshold exceeded. HTTP 429 Too Many Requests.\", \"RetryAfterSeconds\": 30}", token);
    };
});

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

// 5. Configure Swagger OpenAPI with Bearer Token Auth
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "API Security Lab",
        Version = "v1",
        Description = "ASP.NET Core .NET 10 API Security Lab demonstrating JWT, AES-256-GCM, Argon2id, Magic Byte file validation, SQLi/XSS defense, and Rate Limiting."
    });

    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Enter JWT Bearer token"
    });

    var securityRequirement = new OpenApiSecurityRequirement
    {
        { new OpenApiSecuritySchemeReference("Bearer", null), new List<string>() }
    };
    options.AddSecurityRequirement((doc) => securityRequirement);
});

var app = builder.Build();

// Auto-create database & apply tables safely
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
    try
    {
        if (useInMemory)
        {
            db.Database.EnsureCreated();
            logger.LogInformation("In-Memory database initialized.");
        }
        else
        {
            // For PostgreSQL / Supabase
            try
            {
                db.Database.EnsureCreated();
                logger.LogInformation("PostgreSQL schema validated/created successfully.");
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Database.EnsureCreated encountered an issue (tables may already exist or pooler in transaction mode). Continuing startup...");
            }
        }
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Error during DB initialization: {Message}", ex.Message);
    }
}

// 6. Middleware Pipeline Order
app.UseMiddleware<GlobalExceptionHandlerMiddleware>();
app.UseMiddleware<SecurityHeadersMiddleware>();

app.UseDefaultFiles();
app.UseStaticFiles();

app.UseSwagger();
app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "API Security Lab v1"));

app.UseRouting();
app.UseCors();

app.UseAuthentication();
app.UseAuthorization();

app.UseMiddleware<AuditLoggingMiddleware>();
app.UseRateLimiter();

app.MapControllers();

app.Run();

static string NormalizePostgresConnectionString(string connStr)
{
    if (string.IsNullOrWhiteSpace(connStr)) return connStr;
    connStr = connStr.Trim();
    if (connStr.StartsWith("postgresql://", StringComparison.OrdinalIgnoreCase) ||
        connStr.StartsWith("postgres://", StringComparison.OrdinalIgnoreCase))
    {
        try
        {
            var uri = new Uri(connStr);
            var userInfo = uri.UserInfo.Split(':');
            string username = Uri.UnescapeDataString(userInfo[0]);
            string password = userInfo.Length > 1 ? Uri.UnescapeDataString(userInfo[1]) : "";
            string database = uri.AbsolutePath.TrimStart('/');
            if (string.IsNullOrEmpty(database)) database = "postgres";
            int port = uri.Port > 0 ? uri.Port : 5432;

            return $"Host={uri.Host};Port={port};Database={database};Username={username};Password={password};SSL Mode=Require;Trust Server Certificate=true;Timeout=15;Command Timeout=30;";
        }
        catch
        {
            return connStr;
        }
    }
    return connStr;
}
