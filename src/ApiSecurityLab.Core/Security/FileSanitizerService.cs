using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;

namespace ApiSecurityLab.Core.Security;

public class FileSanitizerService : IFileSanitizer
{
    private static readonly HashSet<string> AllowedExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".png", ".jpg", ".jpeg", ".pdf", ".txt"
    };

    private static readonly Dictionary<string, List<byte[]>> KnownMagicBytes = new(StringComparer.OrdinalIgnoreCase)
    {
        { ".png", new List<byte[]> { new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A } } },
        { ".jpg", new List<byte[]> { new byte[] { 0xFF, 0xD8, 0xFF } } },
        { ".jpeg", new List<byte[]> { new byte[] { 0xFF, 0xD8, 0xFF } } },
        { ".pdf", new List<byte[]> { new byte[] { 0x25, 0x50, 0x44, 0x46 } } } // %PDF
    };

    public FileValidationResult ValidateFile(string fileName, Stream contentStream)
    {
        string ext = Path.GetExtension(fileName);
        if (string.IsNullOrWhiteSpace(ext) || !AllowedExtensions.Contains(ext))
        {
            return new FileValidationResult(false, "N/A", $"File extension '{ext}' is forbidden.");
        }

        if (contentStream == null || contentStream.Length == 0)
        {
            return new FileValidationResult(false, "N/A", "File content is empty.");
        }

        // Read header bytes (first 16 bytes)
        byte[] headerBytes = new byte[16];
        long originalPosition = contentStream.Position;
        int bytesRead = contentStream.Read(headerBytes, 0, headerBytes.Length);
        contentStream.Position = originalPosition; // Reset stream position

        string hexBytes = BitConverter.ToString(headerBytes, 0, bytesRead).Replace("-", " ");

        // Check for known executable signatures (MZ header = 4D 5A, ELF = 7F 45 4C 46)
        if (bytesRead >= 2 && headerBytes[0] == 0x4D && headerBytes[1] == 0x5A)
        {
            return new FileValidationResult(false, hexBytes, "SECURITY ALERT: Executable binary (MZ header) detected disguised as image/document!");
        }

        if (bytesRead >= 4 && headerBytes[0] == 0x7F && headerBytes[1] == 0x45 && headerBytes[2] == 0x4C && headerBytes[3] == 0x46)
        {
            return new FileValidationResult(false, hexBytes, "SECURITY ALERT: Linux ELF binary detected!");
        }

        // Validate extension magic bytes if strictly configured
        if (KnownMagicBytes.TryGetValue(ext, out var validSignatures))
        {
            bool matches = validSignatures.Any(sig => bytesRead >= sig.Length && headerBytes.Take(sig.Length).SequenceEqual(sig));
            if (!matches)
            {
                return new FileValidationResult(false, hexBytes, $"Magic byte validation failed for extension '{ext}'. Header was [{hexBytes}].");
            }
        }

        return new FileValidationResult(true, hexBytes, string.Empty);
    }

    public string SanitizeFileName(string originalFileName)
    {
        if (string.IsNullOrWhiteSpace(originalFileName))
            return $"{Guid.NewGuid()}.dat";

        // Remove path information to defeat Path Traversal
        string safeName = Path.GetFileName(originalFileName);

        // Strip null bytes and dangerous relative path sequences
        safeName = safeName.Replace("\0", "").Replace("..", "");

        // Keep only alphanumeric characters, underscores, hyphens, and extension dots
        safeName = Regex.Replace(safeName, @"[^a-zA-Z0-9_\-\.]", "_");

        string ext = Path.GetExtension(safeName);
        string nameWithoutExt = Path.GetFileNameWithoutExtension(safeName);

        // Append GUID to prevent collisions and overwriting
        return $"{nameWithoutExt}_{Guid.NewGuid():N}{ext}";
    }

    public string GenerateExpiringDownloadSignature(string fileId, long expiresTimestamp, string secretKey)
    {
        string payload = $"{fileId}:{expiresTimestamp}";
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(secretKey));
        byte[] hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(payload));
        return Convert.ToHexString(hash).ToLowerInvariant();
    }

    public bool VerifyDownloadSignature(string fileId, long expiresTimestamp, string signature, string secretKey)
    {
        if (DateTimeOffset.UtcNow.ToUnixTimeSeconds() > expiresTimestamp)
        {
            return false; // Signature expired
        }

        string expectedSignature = GenerateExpiringDownloadSignature(fileId, expiresTimestamp, secretKey);
        return CryptographicOperations.FixedTimeEquals(
            Encoding.UTF8.GetBytes(expectedSignature),
            Encoding.UTF8.GetBytes(signature.ToLowerInvariant())
        );
    }
}
