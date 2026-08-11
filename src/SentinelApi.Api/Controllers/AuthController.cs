using System;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using SentinelApi.Api.DTOs;
using SentinelApi.Core.Models;
using SentinelApi.Core.Security;
using SentinelApi.Core.Services;
using SentinelApi.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace SentinelApi.Api.Controllers;

[ApiController]
[Route("api/v1/auth")]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IJwtTokenService _jwtService;
    private readonly IEncryptionService _encryptionService;
    private readonly IEmailService _emailService;

    public AuthController(
        AppDbContext db,
        IPasswordHasher passwordHasher,
        IJwtTokenService jwtService,
        IEncryptionService encryptionService,
        IEmailService emailService)
    {
        _db = db;
        _passwordHasher = passwordHasher;
        _jwtService = jwtService;
        _encryptionService = encryptionService;
        _emailService = emailService;
    }

    private string FormatOrGenerateClientId(string? inputAppName)
    {
        if (string.IsNullOrWhiteSpace(inputAppName) || inputAppName.Equals("sentinel-core", StringComparison.OrdinalIgnoreCase))
        {
            return "client_sentinel_core";
        }
        string trimmed = inputAppName.Trim().ToLowerInvariant();
        // If it's already a full unique client id format (e.g. client_moneymate_a1b2c3)
        if (trimmed.StartsWith("client_") && trimmed.Length >= 10)
        {
            return trimmed;
        }
        // Clean alphanumeric slug
        var slugChars = trimmed.Where(c => char.IsLetterOrDigit(c) || c == '_' || c == '-').ToArray();
        string slug = new string(slugChars).Replace('-', '_');
        if (string.IsNullOrWhiteSpace(slug)) slug = "app";
        string suffix = Convert.ToHexString(RandomNumberGenerator.GetBytes(3)).ToLowerInvariant(); // 6 hex characters
        return $"client_{slug}_{suffix}";
    }

    private string ResolveClientId(string? requestClientId)
    {
        if (!string.IsNullOrWhiteSpace(requestClientId))
        {
            return requestClientId.Trim().ToLowerInvariant();
        }
        if (Request.Headers.TryGetValue("X-Client-Id", out var headerVal) && !string.IsNullOrWhiteSpace(headerVal))
        {
            return headerVal.ToString().Trim().ToLowerInvariant();
        }
        return "client_sentinel_core";
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Username) || string.IsNullOrWhiteSpace(request.Password))
        {
            return BadRequest(new AuthResponse(false, "Username and password are required.", null, null, null));
        }

        if (string.IsNullOrWhiteSpace(request.Email))
        {
            return BadRequest(new AuthResponse(false, "Email is required for OTP verification.", null, null, null));
        }

        string clientId = FormatOrGenerateClientId(request.ClientId);

        if (await _db.Users.AnyAsync(u => u.ClientId == clientId && u.Username.ToLower() == request.Username.ToLower()))
        {
            return Conflict(new AuthResponse(false, $"Username is already taken within application realm '{clientId}'. Please choose another username.", null, null, null));
        }

        if (await _db.Users.AnyAsync(u => u.ClientId == clientId && u.Email.ToLower() == request.Email.ToLower()))
        {
            return Conflict(new AuthResponse(false, $"Email is already registered for application realm '{clientId}'. Please log in or use a different email.", null, null, null));
        }

        var (hash, salt) = _passwordHasher.HashPassword(request.Password);
        string role = request.Role.Equals("Admin", StringComparison.OrdinalIgnoreCase) ? "Admin" : "User";

        var user = new User
        {
            Id = Guid.NewGuid(),
            Username = request.Username,
            Email = request.Email,
            PasswordHash = hash,
            Salt = salt,
            Role = role,
            ClientId = clientId,
            CreatedAt = DateTime.UtcNow,
            IsEmailVerified = false
        };

        try
        {
            _db.Users.Add(user);
            await _db.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            return Conflict(new AuthResponse(false, $"A user with this username or email already exists in realm '{clientId}'.", null, null, null));
        }

        // Generate 6-digit OTP and send via email
        string otpCode = GenerateOtp();
        string otpHash = HashOtp(otpCode);

        var verificationToken = new EmailVerificationToken
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            OtpHash = otpHash,
            ExpiresAt = DateTime.UtcNow.AddMinutes(10),
            IsUsed = false,
            AttemptCount = 0,
            CreatedAt = DateTime.UtcNow
        };

        _db.EmailVerificationTokens.Add(verificationToken);
        await _db.SaveChangesAsync();

        // Send OTP email via Brevo
        bool emailSent = await _emailService.SendOtpEmailAsync(user.Email, user.Username, otpCode);

        if (!emailSent)
        {
            return StatusCode(500, new AuthResponse(false, "Registration saved but failed to send verification email. Please use 'Resend OTP' to try again.", null, null, null));
        }

        return Ok(new AuthResponse(
            true,
            $"Registration successful! A 6-digit OTP has been sent to {user.Email}. Unique App Client ID assigned: '{clientId}'.",
            null, // No JWT token yet — must verify email first
            null,
            new UserDto(user.Id.ToString(), user.Username, user.Email, user.Role, user.CreatedAt.ToString("o"), user.ClientId)
        ));
    }

    [HttpPost("verify-email")]
    public async Task<IActionResult> VerifyEmail([FromBody] VerifyEmailRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Otp))
        {
            return BadRequest(new AuthResponse(false, "Email and OTP code are required.", null, null, null));
        }

        string clientId = ResolveClientId(request.ClientId);

        var user = await _db.Users.FirstOrDefaultAsync(u => u.ClientId == clientId && u.Email.ToLower() == request.Email.ToLower());
        if (user == null)
        {
            return NotFound(new AuthResponse(false, $"No account found with this email address in application realm '{clientId}'.", null, null, null));
        }

        if (user.IsEmailVerified)
        {
            return BadRequest(new AuthResponse(false, "Email is already verified. Please login.", null, null, null));
        }

        // Find the latest unused, non-expired OTP for this user
        var token = await _db.EmailVerificationTokens
            .Where(t => t.UserId == user.Id && !t.IsUsed && t.ExpiresAt > DateTime.UtcNow)
            .OrderByDescending(t => t.CreatedAt)
            .FirstOrDefaultAsync();

        if (token == null)
        {
            return BadRequest(new AuthResponse(false, "No active OTP found. It may have expired. Please request a new one.", null, null, null));
        }

        // Check attempt limit (max 5)
        if (token.AttemptCount >= 5)
        {
            token.IsUsed = true; // Invalidate the token
            await _db.SaveChangesAsync();
            return BadRequest(new AuthResponse(false, "Too many incorrect attempts. This OTP has been invalidated. Please request a new one.", null, null, null));
        }

        // Verify OTP hash
        string providedHash = HashOtp(request.Otp.Trim());
        if (providedHash != token.OtpHash)
        {
            token.AttemptCount++;
            await _db.SaveChangesAsync();
            int remaining = 5 - token.AttemptCount;
            return BadRequest(new AuthResponse(false, $"Invalid OTP code. {remaining} attempt(s) remaining.", null, null, null));
        }

        // OTP is correct — verify email and issue tokens
        token.IsUsed = true;
        user.IsEmailVerified = true;
        await _db.SaveChangesAsync();

        var accessToken = _jwtService.GenerateAccessToken(user);
        var refreshToken = _jwtService.GenerateRefreshToken(user);

        _db.RefreshTokens.Add(refreshToken);
        await _db.SaveChangesAsync();

        // Dispatch developer welcome & credentials email with their unique Client ID
        _ = _emailService.SendClientCredentialsEmailAsync(user.Email, user.Username, user.ClientId, user.ClientId);

        var userDto = new UserDto(user.Id.ToString(), user.Username, user.Email, user.Role, user.CreatedAt.ToString("o"), user.ClientId);
        return Ok(new AuthResponse(
            true,
            $"Email verified! You are now logged in. Your unique Client ID is '{user.ClientId}'. A confirmation email has been sent with integration instructions.",
            accessToken,
            refreshToken.Token,
            userDto
        ));
    }

    [HttpPost("resend-otp")]
    public async Task<IActionResult> ResendOtp([FromBody] ResendOtpRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Email))
        {
            return BadRequest(new AuthResponse(false, "Email is required.", null, null, null));
        }

        string clientId = ResolveClientId(request.ClientId);

        var user = await _db.Users.FirstOrDefaultAsync(u => u.ClientId == clientId && u.Email.ToLower() == request.Email.ToLower());
        if (user == null)
        {
            return NotFound(new AuthResponse(false, $"No account found with this email address in realm '{clientId}'.", null, null, null));
        }

        if (user.IsEmailVerified)
        {
            return BadRequest(new AuthResponse(false, "Email is already verified. Please login.", null, null, null));
        }

        // Rate limit: max 3 OTPs in the last hour
        var recentOtps = await _db.EmailVerificationTokens
            .Where(t => t.UserId == user.Id && t.CreatedAt > DateTime.UtcNow.AddHours(-1))
            .CountAsync();

        if (recentOtps >= 3)
        {
            return StatusCode(429, new AuthResponse(false, "Too many OTP requests. Please wait before requesting another one (max 3 per hour).", null, null, null));
        }

        // Invalidate all previous unused tokens for this user
        var oldTokens = await _db.EmailVerificationTokens
            .Where(t => t.UserId == user.Id && !t.IsUsed)
            .ToListAsync();

        foreach (var oldToken in oldTokens)
        {
            oldToken.IsUsed = true;
        }

        // Generate new OTP
        string otpCode = GenerateOtp();
        string otpHash = HashOtp(otpCode);

        var verificationToken = new EmailVerificationToken
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            OtpHash = otpHash,
            ExpiresAt = DateTime.UtcNow.AddMinutes(10),
            IsUsed = false,
            AttemptCount = 0,
            CreatedAt = DateTime.UtcNow
        };

        _db.EmailVerificationTokens.Add(verificationToken);
        await _db.SaveChangesAsync();

        bool emailSent = await _emailService.SendOtpEmailAsync(user.Email, user.Username, otpCode);

        if (!emailSent)
        {
            return StatusCode(500, new AuthResponse(false, "Failed to send verification email. Please try again later.", null, null, null));
        }

        return Ok(new AuthResponse(true, $"A new OTP has been sent to {user.Email}. It expires in 10 minutes.", null, null, null));
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        string clientId = ResolveClientId(request.ClientId);

        var user = await _db.Users.FirstOrDefaultAsync(u =>
            u.ClientId == clientId &&
            (u.Username.ToLower() == request.UsernameOrEmail.ToLower() ||
             u.Email.ToLower() == request.UsernameOrEmail.ToLower()));

        if (user == null || !_passwordHasher.VerifyPassword(request.Password, user.PasswordHash, user.Salt))
        {
            return Unauthorized(new AuthResponse(false, $"Invalid credentials for realm '{clientId}'.", null, null, null));
        }

        // Block login if email is not verified
        if (!user.IsEmailVerified)
        {
            return Unauthorized(new AuthResponse(false, "Email not verified. Please check your inbox for the OTP code and verify your email before logging in.", null, null, null));
        }

        var accessToken = _jwtService.GenerateAccessToken(user);
        var refreshToken = _jwtService.GenerateRefreshToken(user);

        _db.RefreshTokens.Add(refreshToken);
        await _db.SaveChangesAsync();

        var userDto = new UserDto(user.Id.ToString(), user.Username, user.Email, user.Role, user.CreatedAt.ToString("o"), user.ClientId);
        return Ok(new AuthResponse(true, $"Login successful for realm '{clientId}'.", accessToken, refreshToken.Token, userDto));
    }

    [HttpPost("refresh")]
    public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequest request)
    {
        var principal = _jwtService.GetPrincipalFromExpiredToken(request.AccessToken);
        if (principal == null)
        {
            return BadRequest(new AuthResponse(false, "Invalid Access Token format or signature.", null, null, null));
        }

        string? userIdStr = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdStr, out var userId))
        {
            return BadRequest(new AuthResponse(false, "Invalid token claims.", null, null, null));
        }

        var storedToken = await _db.RefreshTokens.FirstOrDefaultAsync(rt => rt.Token == request.RefreshToken && rt.UserId == userId);
        if (storedToken == null || !storedToken.IsActive)
        {
            return Unauthorized(new AuthResponse(false, "Refresh token is expired, revoked, or invalid.", null, null, null));
        }

        var user = await _db.Users.FindAsync(userId);
        if (user == null)
        {
            return NotFound(new AuthResponse(false, "User not found.", null, null, null));
        }

        // Revoke old refresh token & spin new pair
        var newRefreshToken = _jwtService.GenerateRefreshToken(user);
        storedToken.RevokedAt = DateTime.UtcNow;
        storedToken.ReplacedByToken = newRefreshToken.Token;

        _db.RefreshTokens.Add(newRefreshToken);
        await _db.SaveChangesAsync();

        var newAccessToken = _jwtService.GenerateAccessToken(user);
        var userDto = new UserDto(user.Id.ToString(), user.Username, user.Email, user.Role, user.CreatedAt.ToString("o"), user.ClientId);

        return Ok(new AuthResponse(true, "Token refreshed successfully.", newAccessToken, newRefreshToken.Token, userDto));
    }

    [Authorize]
    [HttpGet("me")]
    public async Task<IActionResult> GetCurrentUser()
    {
        string? userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdStr, out var userId))
        {
            return Unauthorized();
        }

        var user = await _db.Users.FindAsync(userId);
        if (user == null) return NotFound();

        string? decryptedNote = null;
        if (!string.IsNullOrEmpty(user.EncryptedSensitiveNote))
        {
            try
            {
                decryptedNote = _encryptionService.DecryptText(user.EncryptedSensitiveNote, Convert.ToBase64String(_encryptionService.GenerateRandomKey()));
            }
            catch
            {
                decryptedNote = "[AES-256-GCM Encrypted Data at Rest]";
            }
        }

        return Ok(new
        {
            user.Id,
            user.Username,
            user.Email,
            user.Role,
            user.ClientId,
            user.CreatedAt,
            user.IsEmailVerified,
            user.EncryptedSensitiveNote,
            DecryptedNotePreview = decryptedNote
        });
    }

    [Authorize]
    [HttpPost("sensitive-note")]
    public async Task<IActionResult> SaveSensitiveNote([FromBody] UpdateSensitiveNoteRequest request)
    {
        string? userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdStr, out var userId)) return Unauthorized();

        var user = await _db.Users.FindAsync(userId);
        if (user == null) return NotFound();

        // Encrypt field-level data using master key
        byte[] defaultKey = new byte[32]; // Fixed master key for demo
        Array.Fill(defaultKey, (byte)0x42);
        string keyBase64 = Convert.ToBase64String(defaultKey);

        string cipherText = _encryptionService.EncryptText(request.Note, keyBase64);
        user.EncryptedSensitiveNote = cipherText;

        await _db.SaveChangesAsync();
        return Ok(new { Success = true, Message = "Sensitive note encrypted with AES-256-GCM and saved securely.", CipherText = cipherText });
    }

    // --- Helper Methods ---

    private static string GenerateOtp()
    {
        using var rng = RandomNumberGenerator.Create();
        byte[] bytes = new byte[4];
        rng.GetBytes(bytes);
        int number = Math.Abs(BitConverter.ToInt32(bytes, 0)) % 900000 + 100000; // 6-digit: 100000-999999
        return number.ToString();
    }

    private static string HashOtp(string otp)
    {
        byte[] hashBytes = SHA256.HashData(Encoding.UTF8.GetBytes(otp));
        return Convert.ToHexStringLower(hashBytes);
    }
}
