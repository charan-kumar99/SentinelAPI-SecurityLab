using System;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;
using SentinelApi.Api.DTOs;
using SentinelApi.Core.Security;
using SentinelApi.Infrastructure.Data;
using Microsoft.AspNetCore.Cors;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;

namespace SentinelApi.Api.Controllers;

[ApiController]
[Route("api/v1/lab")]
public class SecurityLabController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly IXssSanitizer _xssSanitizer;
    private readonly IEncryptionService _encryptionService;
    private readonly IPasswordHasher _passwordHasher;

    public SecurityLabController(
        AppDbContext db,
        IXssSanitizer xssSanitizer,
        IEncryptionService encryptionService,
        IPasswordHasher passwordHasher)
    {
        _db = db;
        _xssSanitizer = xssSanitizer;
        _encryptionService = encryptionService;
        _passwordHasher = passwordHasher;
    }

    [HttpPost("sqli")]
    public async Task<IActionResult> TestSqlInjection([FromBody] SqlTestRequest request)
    {
        string input = request.SearchInput ?? string.Empty;

        if (request.ExecuteVulnerableMode)
        {
            // Simulated Vulnerable Raw SQL string concatenation
            string vulnerableQuery = $"SELECT * FROM \"Users\" WHERE \"Username\" = '{input}'";

            // If input contains string break `' OR '1'='1`, return simulated compromised dataset
            bool isAttacked = input.Contains("' OR '") || input.Contains("' OR 1=1") || input.Contains("' OR '1'='1");

            var results = isAttacked
                ? await _db.Users.Select(u => new { u.Id, u.Username, u.Email, u.Role }).ToListAsync()
                : await _db.Users.Where(u => u.Username == input).Select(u => new { u.Id, u.Username, u.Email, u.Role }).ToListAsync();

            return Ok(new SqlTestResponse(
                vulnerableQuery,
                true,
                results,
                isAttacked
                    ? "VULNERABILITY DEMO: Unsanitized string concatenation allowed SQL Injection payload to bypass authentication and dump all user records!"
                    : "Unsafe string concatenation query constructed."
            ));
        }
        else
        {
            // Safe Parameterized Execution using EF Core LINQ / Parameterized SQL
            string safeQueryPattern = "SELECT * FROM \"Users\" WHERE \"Username\" = @p0";
            var results = await _db.Users
                .Where(u => u.Username == input)
                .Select(u => new { u.Id, u.Username, u.Email, u.Role })
                .ToListAsync();

            return Ok(new SqlTestResponse(
                safeQueryPattern,
                false,
                results,
                "DEFENSE ENGAGED: Parameterized query binds input as literal data parameter. SQL Injection payload was neutralized completely."
            ));
        }
    }

    [HttpPost("xss")]
    public IActionResult TestXss([FromBody] XssTestRequest request)
    {
        string raw = request.RawPayload ?? string.Empty;

        string sanitizedHtml = _xssSanitizer.SanitizeHtml(raw);
        string htmlEncoded = _xssSanitizer.HtmlEncode(raw);

        string analysis = raw.Contains("<script") || raw.Contains("onerror=") || raw.Contains("javascript:")
            ? "DEFENSE ENGAGED: XSS Vector detected! HtmlSanitizer stripped dangerous tags/attributes, and HTML Encoding converted special characters to safe entities."
            : "No active XSS script tags detected in payload.";

        return Ok(new XssTestResponse(raw, sanitizedHtml, htmlEncoded, analysis));
    }

    [HttpPost("crypto")]
    public IActionResult TestCrypto([FromBody] CryptoTestRequest request)
    {
        string plainText = request.PlainText ?? "Sensitive Password/Credit Card Payload";
        string password = request.Password ?? "SuperSecretUserPass123!";

        // 1. Benchmark AES-256-GCM Encryption
        byte[] masterKey = _encryptionService.GenerateRandomKey();
        string masterKeyBase64 = Convert.ToBase64String(masterKey);

        string cipherText = _encryptionService.EncryptText(plainText, masterKeyBase64);
        string decryptedText = _encryptionService.DecryptText(cipherText, masterKeyBase64);

        // 2. Benchmark Argon2id Hashing
        var sw = Stopwatch.StartNew();
        var (hash, salt) = _passwordHasher.HashPassword(password);
        sw.Stop();

        return Ok(new CryptoTestResponse(
            plainText,
            cipherText,
            decryptedText,
            hash,
            salt,
            sw.ElapsedMilliseconds,
            "AES-256-GCM provides confidentiality and integrity tags. Argon2id (64MB memory, 3 iterations) prevents GPU/ASIC brute-force dictionary attacks."
        ));
    }

    [EnableRateLimiting("StrictPolicy")]
    [HttpGet("rate-limit-test")]
    public IActionResult TestRateLimiter()
    {
        return Ok(new
        {
            Success = true,
            Message = "Request allowed within rate limit threshold.",
            Timestamp = DateTime.UtcNow,
            Advice = "Send burst requests rapidly to trigger HTTP 429 Too Many Requests response!"
        });
    }
}
