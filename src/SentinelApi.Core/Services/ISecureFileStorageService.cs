using System;
using System.IO;
using System.Threading.Tasks;
using SentinelApi.Core.Models;
using SentinelApi.Core.Security;

namespace SentinelApi.Core.Services;

public record FileUploadResult(bool Success, SecureFileMetadata? Metadata, FileValidationResult ValidationResult);

public interface ISecureFileStorageService
{
    Task<FileUploadResult> StoreFileAsync(string fileName, string contentType, Stream inputStream, Guid userId);
    Task<(byte[] fileBytes, SecureFileMetadata metadata)?> RetrieveFileAsync(Guid fileId);
    Task<List<SecureFileMetadata>> GetUserFilesAsync(Guid userId);
}
