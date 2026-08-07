using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Threading.Tasks;
using ApiSecurityLab.Core.Models;
using ApiSecurityLab.Core.Security;
using ApiSecurityLab.Core.Services;
using ApiSecurityLab.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace ApiSecurityLab.Infrastructure.Services;

public class SecureFileStorageService : ISecureFileStorageService
{
    private readonly AppDbContext _db;
    private readonly IFileSanitizer _sanitizer;
    private readonly IEncryptionService _encryption;
    private readonly string _storageDirectory;

    public SecureFileStorageService(AppDbContext db, IFileSanitizer sanitizer, IEncryptionService encryption)
    {
        _db = db;
        _sanitizer = sanitizer;
        _encryption = encryption;
        _storageDirectory = Path.Combine(Directory.GetCurrentDirectory(), "Storage", "EncryptedFiles");
        if (!Directory.Exists(_storageDirectory))
        {
            Directory.CreateDirectory(_storageDirectory);
        }
    }

    public async Task<FileUploadResult> StoreFileAsync(string fileName, string contentType, Stream inputStream, Guid userId)
    {
        var validationResult = _sanitizer.ValidateFile(fileName, inputStream);
        if (!validationResult.IsValid)
        {
            return new FileUploadResult(false, null, validationResult);
        }

        string safeFileName = _sanitizer.SanitizeFileName(fileName);
        string diskPath = Path.Combine(_storageDirectory, safeFileName);

        using var memoryStream = new MemoryStream();
        await inputStream.CopyToAsync(memoryStream);
        byte[] rawBytes = memoryStream.ToArray();

        // Generate dynamic key per file for AES-256-GCM encryption
        byte[] fileKey = _encryption.GenerateRandomKey();
        var (cipherBytes, nonce, tag) = _encryption.EncryptData(rawBytes, fileKey);

        // Package Nonce + Tag + Ciphertext into stored file
        byte[] payloadToSave = new byte[nonce.Length + tag.Length + cipherBytes.Length];
        Buffer.BlockCopy(nonce, 0, payloadToSave, 0, nonce.Length);
        Buffer.BlockCopy(tag, 0, payloadToSave, nonce.Length, tag.Length);
        Buffer.BlockCopy(cipherBytes, 0, payloadToSave, nonce.Length + tag.Length, cipherBytes.Length);

        await File.WriteAllBytesAsync(diskPath, payloadToSave);

        var metadata = new SecureFileMetadata
        {
            Id = Guid.NewGuid(),
            OriginalFileName = fileName,
            SanitizedFileName = safeFileName,
            StoredFilePath = diskPath,
            ContentType = contentType,
            MagicBytesHex = validationResult.MagicBytesHex,
            FileSizeBytes = rawBytes.Length,
            EncryptedKeyBase64 = Convert.ToBase64String(fileKey),
            EncryptedIvBase64 = Convert.ToBase64String(nonce),
            UploadedByUserId = userId,
            UploadedAt = DateTime.UtcNow,
            IsEncryptedAtRest = true
        };

        _db.SecureFiles.Add(metadata);
        await _db.SaveChangesAsync();

        return new FileUploadResult(true, metadata, validationResult);
    }

    public async Task<(byte[] fileBytes, SecureFileMetadata metadata)?> RetrieveFileAsync(Guid fileId)
    {
        var metadata = await _db.SecureFiles.FirstOrDefaultAsync(f => f.Id == fileId);
        if (metadata == null || !File.Exists(metadata.StoredFilePath))
        {
            return null;
        }

        byte[] payload = await File.ReadAllBytesAsync(metadata.StoredFilePath);
        byte[] fileKey = Convert.FromBase64String(metadata.EncryptedKeyBase64);

        int nonceLength = 12; // GCM 96-bit nonce
        int tagLength = 16;   // GCM 128-bit tag

        if (payload.Length < nonceLength + tagLength)
        {
            throw new CryptographicException("Corrupted encrypted file container.");
        }

        byte[] nonce = new byte[nonceLength];
        byte[] tag = new byte[tagLength];
        byte[] cipherBytes = new byte[payload.Length - nonceLength - tagLength];

        Buffer.BlockCopy(payload, 0, nonce, 0, nonceLength);
        Buffer.BlockCopy(payload, nonceLength, tag, 0, tagLength);
        Buffer.BlockCopy(payload, nonceLength + tagLength, cipherBytes, 0, cipherBytes.Length);

        byte[] decryptedBytes = _encryption.DecryptData(cipherBytes, nonce, tag, fileKey);
        return (decryptedBytes, metadata);
    }

    public async Task<List<SecureFileMetadata>> GetUserFilesAsync(Guid userId)
    {
        return await _db.SecureFiles
            .Where(f => f.UploadedByUserId == userId)
            .OrderByDescending(f => f.UploadedAt)
            .ToListAsync();
    }
}
