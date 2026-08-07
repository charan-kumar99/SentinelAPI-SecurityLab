using System;

namespace ApiSecurityLab.Core.Models;

public class User
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string Salt { get; set; } = string.Empty;
    public string Role { get; set; } = "User"; // User, Admin, SecurityAuditor
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public string? EncryptedSensitiveNote { get; set; } // Field-level AES-256-GCM encryption
}
