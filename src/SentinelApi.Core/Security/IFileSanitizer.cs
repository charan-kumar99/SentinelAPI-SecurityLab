using System.IO;

namespace SentinelApi.Core.Security;

public record FileValidationResult(bool IsValid, string MagicBytesHex, string ErrorMessage);

public interface IFileSanitizer
{
    FileValidationResult ValidateFile(string fileName, Stream contentStream);
    string SanitizeFileName(string originalFileName);
    string GenerateExpiringDownloadSignature(string fileId, long expiresTimestamp, string secretKey);
    bool VerifyDownloadSignature(string fileId, long expiresTimestamp, string signature, string secretKey);
}
