using System;
using System.Security.Claims;
using System.Threading.Tasks;
using ApiSecurityLab.Core.Models;
using ApiSecurityLab.Core.Services;
using Microsoft.AspNetCore.Http;

namespace ApiSecurityLab.Api.Middlewares;

public class AuditLoggingMiddleware
{
    private readonly RequestDelegate _next;

    public AuditLoggingMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context, IAuditLogService auditService)
    {
        var request = context.Request;
        string path = request.Path.Value ?? "";

        // Skip static file assets like css/js/images from spamming audit logs
        if (path.StartsWith("/css") || path.StartsWith("/js") || path.StartsWith("/favicon") || path.EndsWith(".ico"))
        {
            await _next(context);
            return;
        }

        string clientIp = context.Connection.RemoteIpAddress?.ToString() ?? "127.0.0.1";
        string userAgent = request.Headers["User-Agent"].ToString();
        string method = request.Method;

        await _next(context);

        int statusCode = context.Response.StatusCode;
        string? userId = context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        string? username = context.User?.FindFirst(ClaimTypes.Name)?.Value;

        RiskLevel riskLevel = statusCode switch
        {
            401 => RiskLevel.Medium, // Unauthorized
            403 => RiskLevel.High,   // Forbidden access attempt
            429 => RiskLevel.High,   // Rate limit exceeded / abuse
            >= 500 => RiskLevel.Critical, // Internal Server Error
            _ => RiskLevel.Info
        };

        string action = $"{method} {path}";
        string details = $"Request completed with HTTP {statusCode}. Client IP: {clientIp}.";

        // Log asynchronously
        try
        {
            await auditService.LogAsync(userId, username, clientIp, userAgent, path, method, action, statusCode, riskLevel, details);
        }
        catch
        {
            // Do not break main request pipeline if audit logging fails
        }
    }
}
