using System;

namespace SentinelApi.Core.Models;

public class User
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string Salt { get; set; } = string.Empty;
    public string Role { get; set; } = "User"; // User, Admin, SecurityAuditor
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public bool IsEmailVerified { get; set; } = false; // Must verify email via OTP before login
    public string ClientId { get; set; } = "sentinel-core"; // Multi-tenant scoping: moneymate, orion, sentinel-core
    public string? EncryptedSensitiveNote { get; set; } // Field-level AES-256-GCM encryption
}
