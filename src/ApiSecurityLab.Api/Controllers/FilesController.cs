using System;
using System.Security.Claims;
using System.Threading.Tasks;
using ApiSecurityLab.Core.Security;
using ApiSecurityLab.Core.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace ApiSecurityLab.Api.Controllers;

[ApiController]
[Route("api/v1/files")]
public class FilesController : ControllerBase
{
    private readonly ISecureFileStorageService _storageService;
    private readonly IFileSanitizer _fileSanitizer;
    private const string SecretSigningKey = "SIGNING_SECRET_KEY_FOR_EXPIRING_URLS_SECURITY_LAB_2026!";

    public FilesController(ISecureFileStorageService storageService, IFileSanitizer fileSanitizer)
    {
        _storageService = storageService;
        _fileSanitizer = fileSanitizer;
    }

    [Authorize]
    [HttpPost("upload")]
    public async Task<IActionResult> UploadFile([FromForm] IFormFile file)
    {
        if (file == null || file.Length == 0)
        {
            return BadRequest(new { Success = false, Message = "No file provided." });
        }

        string? userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdStr, out var userId))
        {
            return Unauthorized();
        }

        using var stream = file.OpenReadStream();
        var result = await _storageService.StoreFileAsync(file.FileName, file.ContentType, stream, userId);

        if (!result.Success)
        {
            return BadRequest(new
            {
                Success = false,
                Error = result.ValidationResult.ErrorMessage,
                MagicBytesDetectedHex = result.ValidationResult.MagicBytesHex,
                SecurityAnalysis = "File upload rejected by Magic Byte binary inspection pipeline."
            });
        }

        return Ok(new
        {
            Success = true,
            Message = "File validated, magic bytes verified, encrypted with AES-256-GCM, and stored safely.",
            FileMetadata = result.Metadata
        });
    }

    [Authorize]
    [HttpGet("my-files")]
    public async Task<IActionResult> GetMyFiles()
    {
        string? userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdStr, out var userId)) return Unauthorized();

        var files = await _storageService.GetUserFilesAsync(userId);
        return Ok(files);
    }

    [Authorize]
    [HttpGet("signed-url/{id:guid}")]
    public async Task<IActionResult> GenerateSignedDownloadUrl(Guid id, [FromQuery] int expirationSeconds = 300)
    {
        long expiresTimestamp = DateTimeOffset.UtcNow.AddSeconds(expirationSeconds).ToUnixTimeSeconds();
        string signature = _fileSanitizer.GenerateExpiringDownloadSignature(id.ToString(), expiresTimestamp, SecretSigningKey);

        string requestScheme = Request.Scheme;
        string requestHost = Request.Host.Value ?? "localhost";
        string downloadUrl = $"{requestScheme}://{requestHost}/api/v1/files/download/{id}?expires={expiresTimestamp}&signature={signature}";

        return Ok(new
        {
            FileId = id,
            ExpiresAt = DateTimeOffset.FromUnixTimeSeconds(expiresTimestamp).UtcDateTime,
            ExpirationSeconds = expirationSeconds,
            Signature = signature,
            DownloadUrl = downloadUrl
        });
    }

    [HttpGet("download/{id:guid}")]
    public async Task<IActionResult> DownloadFile(Guid id, [FromQuery] long expires, [FromQuery] string signature)
    {
        // 1. Verify signature if provided via expiring URL
        if (!string.IsNullOrEmpty(signature) && expires > 0)
        {
            bool isValid = _fileSanitizer.VerifyDownloadSignature(id.ToString(), expires, signature, SecretSigningKey);
            if (!isValid)
            {
                return Unauthorized(new { Success = false, Message = "Download signature is invalid or expired." });
            }
        }
        else
        {
            // Fallback to Bearer Auth
            if (!User.Identity?.IsAuthenticated ?? true)
            {
                return Unauthorized(new { Success = false, Message = "Authentication required or valid expiring signature missing." });
            }
        }

        var result = await _storageService.RetrieveFileAsync(id);
        if (result == null)
        {
            return NotFound(new { Success = false, Message = "File not found or corrupted." });
        }

        var (fileBytes, metadata) = result.Value;
        return File(fileBytes, metadata.ContentType, metadata.OriginalFileName);
    }
}
