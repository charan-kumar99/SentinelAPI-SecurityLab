using System;

namespace SentinelApi.Core.Models;

public enum RiskLevel
{
    Info,
    Low,
    Medium,
    High,
    Critical
}

public class AuditLog
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public string? UserId { get; set; }
    public string? Username { get; set; }
    public string ClientIp { get; set; } = "127.0.0.1";
    public string UserAgent { get; set; } = string.Empty;
    public string Endpoint { get; set; } = string.Empty;
    public string HttpMethod { get; set; } = string.Empty;
    public string Action { get; set; } = string.Empty;
    public int StatusCode { get; set; }
    public RiskLevel RiskLevel { get; set; } = RiskLevel.Info;
    public string Details { get; set; } = string.Empty;
}
