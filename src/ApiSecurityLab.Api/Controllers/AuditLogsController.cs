using System.Threading.Tasks;
using ApiSecurityLab.Core.Models;
using ApiSecurityLab.Core.Services;
using Microsoft.AspNetCore.Mvc;

namespace ApiSecurityLab.Api.Controllers;

[ApiController]
[Route("api/v1/audit-logs")]
public class AuditLogsController : ControllerBase
{
    private readonly IAuditLogService _auditLogService;

    public AuditLogsController(IAuditLogService auditLogService)
    {
        _auditLogService = auditLogService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAuditLogs([FromQuery] string? userId, [FromQuery] string? search, [FromQuery] RiskLevel? riskLevel, [FromQuery] int page = 1, [FromQuery] int pageSize = 50)
    {
        var logs = await _auditLogService.SearchLogsAsync(userId, search, riskLevel, page, pageSize);
        return Ok(logs);
    }

    [HttpGet("recent")]
    public async Task<IActionResult> GetRecentLogs([FromQuery] int count = 20, [FromQuery] RiskLevel? minRiskLevel = null)
    {
        var logs = await _auditLogService.GetRecentLogsAsync(count, minRiskLevel);
        return Ok(logs);
    }
}
