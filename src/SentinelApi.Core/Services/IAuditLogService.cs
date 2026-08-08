using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using SentinelApi.Core.Models;

namespace SentinelApi.Core.Services;

public interface IAuditLogService
{
    Task LogAsync(string? userId, string? username, string clientIp, string userAgent, string endpoint, string httpMethod, string action, int statusCode, RiskLevel riskLevel, string details);
    Task<List<AuditLog>> GetRecentLogsAsync(int count = 50, RiskLevel? minRiskLevel = null);
    Task<List<AuditLog>> SearchLogsAsync(string? userId, string? searchTerm, RiskLevel? riskLevel, int page = 1, int pageSize = 50);
}
