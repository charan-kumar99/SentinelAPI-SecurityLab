using System;

namespace SentinelApi.Core.Models;

public class EmailVerificationToken
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public string OtpHash { get; set; } = string.Empty; // SHA-256 hash of the OTP
    public DateTime ExpiresAt { get; set; }
    public bool IsUsed { get; set; } = false;
    public int AttemptCount { get; set; } = 0; // Max 5 attempts
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
