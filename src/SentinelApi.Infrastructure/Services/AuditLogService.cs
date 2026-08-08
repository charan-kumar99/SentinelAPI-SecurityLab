using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using SentinelApi.Core.Models;
using SentinelApi.Core.Services;
using SentinelApi.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace SentinelApi.Infrastructure.Services;

public class AuditLogService : IAuditLogService
{
    private readonly AppDbContext _db;

    public AuditLogService(AppDbContext db)
    {
        _db = db;
    }

    public async Task LogAsync(string? userId, string? username, string clientIp, string userAgent, string endpoint, string httpMethod, string action, int statusCode, RiskLevel riskLevel, string details)
    {
        var log = new AuditLog
        {
            Id = Guid.NewGuid(),
            Timestamp = DateTime.UtcNow,
            UserId = userId,
            Username = username,
            ClientIp = clientIp,
            UserAgent = userAgent,
            Endpoint = endpoint,
            HttpMethod = httpMethod,
            Action = action,
            StatusCode = statusCode,
            RiskLevel = riskLevel,
            Details = details
        };

        _db.AuditLogs.Add(log);
        await _db.SaveChangesAsync();
    }

    public async Task<List<AuditLog>> GetRecentLogsAsync(int count = 50, RiskLevel? minRiskLevel = null)
    {
        var query = _db.AuditLogs.AsNoTracking();
        if (minRiskLevel.HasValue)
        {
            query = query.Where(l => l.RiskLevel >= minRiskLevel.Value);
        }

        return await query
            .OrderByDescending(l => l.Timestamp)
            .Take(count)
            .ToListAsync();
    }

    public async Task<List<AuditLog>> SearchLogsAsync(string? userId, string? searchTerm, RiskLevel? riskLevel, int page = 1, int pageSize = 50)
    {
        var query = _db.AuditLogs.AsNoTracking();

        if (!string.IsNullOrWhiteSpace(userId))
        {
            query = query.Where(l => l.UserId == userId);
        }

        if (riskLevel.HasValue)
        {
            query = query.Where(l => l.RiskLevel == riskLevel.Value);
        }

        if (!string.IsNullOrWhiteSpace(searchTerm))
        {
            string term = searchTerm.ToLower();
            query = query.Where(l => l.Action.ToLower().Contains(term) ||
                                     l.Endpoint.ToLower().Contains(term) ||
                                     l.Details.ToLower().Contains(term) ||
                                     (l.Username != null && l.Username.ToLower().Contains(term)));
        }

        return await query
            .OrderByDescending(l => l.Timestamp)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();
    }
}
