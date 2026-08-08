using System;

namespace SentinelApi.Core.Models;

public class SecureFileMetadata
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string OriginalFileName { get; set; } = string.Empty;
    public string SanitizedFileName { get; set; } = string.Empty;
    public string StoredFilePath { get; set; } = string.Empty;
    public string ContentType { get; set; } = string.Empty;
    public string MagicBytesHex { get; set; } = string.Empty;
    public long FileSizeBytes { get; set; }
    public string EncryptedKeyBase64 { get; set; } = string.Empty;
    public string EncryptedIvBase64 { get; set; } = string.Empty;
    public Guid UploadedByUserId { get; set; }
    public DateTime UploadedAt { get; set; } = DateTime.UtcNow;
    public bool IsEncryptedAtRest { get; set; } = true;
}
