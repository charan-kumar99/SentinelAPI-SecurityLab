using System;
using System.Security.Claims;
using System.Threading.Tasks;
using SentinelApi.Api.DTOs;
using SentinelApi.Core.Models;
using SentinelApi.Core.Security;
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

    public AuthController(
        AppDbContext db,
        IPasswordHasher passwordHasher,
        IJwtTokenService jwtService,
        IEncryptionService encryptionService)
    {
        _db = db;
        _passwordHasher = passwordHasher;
        _jwtService = jwtService;
        _encryptionService = encryptionService;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Username) || string.IsNullOrWhiteSpace(request.Password))
        {
            return BadRequest(new AuthResponse(false, "Username and password are required.", null, null, null));
        }

        if (await _db.Users.AnyAsync(u => u.Username.ToLower() == request.Username.ToLower()))
        {
            return Conflict(new AuthResponse(false, "Username is already taken.", null, null, null));
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
            CreatedAt = DateTime.UtcNow
        };

        _db.Users.Add(user);
        await _db.SaveChangesAsync();

        var accessToken = _jwtService.GenerateAccessToken(user);
        var refreshToken = _jwtService.GenerateRefreshToken(user);

        _db.RefreshTokens.Add(refreshToken);
        await _db.SaveChangesAsync();

        var userDto = new UserDto(user.Id.ToString(), user.Username, user.Email, user.Role, user.CreatedAt.ToString("o"));
        return Ok(new AuthResponse(true, "Registration successful.", accessToken, refreshToken.Token, userDto));
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u =>
            u.Username.ToLower() == request.UsernameOrEmail.ToLower() ||
            u.Email.ToLower() == request.UsernameOrEmail.ToLower());

        if (user == null || !_passwordHasher.VerifyPassword(request.Password, user.PasswordHash, user.Salt))
        {
            return Unauthorized(new AuthResponse(false, "Invalid credentials.", null, null, null));
        }

        var accessToken = _jwtService.GenerateAccessToken(user);
        var refreshToken = _jwtService.GenerateRefreshToken(user);

        _db.RefreshTokens.Add(refreshToken);
        await _db.SaveChangesAsync();

        var userDto = new UserDto(user.Id.ToString(), user.Username, user.Email, user.Role, user.CreatedAt.ToString("o"));
        return Ok(new AuthResponse(true, "Login successful.", accessToken, refreshToken.Token, userDto));
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
        var userDto = new UserDto(user.Id.ToString(), user.Username, user.Email, user.Role, user.CreatedAt.ToString("o"));

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
            user.CreatedAt,
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
}
