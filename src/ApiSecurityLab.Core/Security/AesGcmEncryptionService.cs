using System;
using System.Security.Cryptography;
using System.Text;

namespace ApiSecurityLab.Core.Security;

public class AesGcmEncryptionService : IEncryptionService
{
    private const int KeySizeBytes = 32; // 256 bits
    private const int NonceSizeBytes = 12; // 96 bits standard for GCM
    private const int TagSizeBytes = 16; // 128 bits authentication tag

    public byte[] GenerateRandomKey()
    {
        return RandomNumberGenerator.GetBytes(KeySizeBytes);
    }

    public string EncryptText(string plainText, string masterKeyBase64)
    {
        if (string.IsNullOrEmpty(plainText)) return string.Empty;
        byte[] keyBytes = string.IsNullOrEmpty(masterKeyBase64)
            ? RandomNumberGenerator.GetBytes(KeySizeBytes)
            : Convert.FromBase64String(masterKeyBase64);

        byte[] plainBytes = Encoding.UTF8.GetBytes(plainText);
        var (cipherBytes, nonce, tag) = EncryptData(plainBytes, keyBytes);

        // Pack: Nonce (12B) + Tag (16B) + Ciphertext
        byte[] resultBytes = new byte[NonceSizeBytes + TagSizeBytes + cipherBytes.Length];
        Buffer.BlockCopy(nonce, 0, resultBytes, 0, NonceSizeBytes);
        Buffer.BlockCopy(tag, 0, resultBytes, NonceSizeBytes, TagSizeBytes);
        Buffer.BlockCopy(cipherBytes, 0, resultBytes, NonceSizeBytes + TagSizeBytes, cipherBytes.Length);

        return Convert.ToBase64String(resultBytes);
    }

    public string DecryptText(string cipherTextBase64, string masterKeyBase64)
    {
        if (string.IsNullOrEmpty(cipherTextBase64)) return string.Empty;
        byte[] keyBytes = Convert.FromBase64String(masterKeyBase64);
        byte[] fullBytes = Convert.FromBase64String(cipherTextBase64);

        if (fullBytes.Length < NonceSizeBytes + TagSizeBytes)
            throw new CryptographicException("Invalid ciphertext payload format.");

        byte[] nonce = new byte[NonceSizeBytes];
        byte[] tag = new byte[TagSizeBytes];
        byte[] cipherBytes = new byte[fullBytes.Length - NonceSizeBytes - TagSizeBytes];

        Buffer.BlockCopy(fullBytes, 0, nonce, 0, NonceSizeBytes);
        Buffer.BlockCopy(fullBytes, NonceSizeBytes, tag, 0, TagSizeBytes);
        Buffer.BlockCopy(fullBytes, NonceSizeBytes + TagSizeBytes, cipherBytes, 0, cipherBytes.Length);

        byte[] plainBytes = DecryptData(cipherBytes, nonce, tag, keyBytes);
        return Encoding.UTF8.GetString(plainBytes);
    }

    public (byte[] cipherBytes, byte[] nonce, byte[] tag) EncryptData(byte[] plainBytes, byte[] keyBytes)
    {
        byte[] nonce = RandomNumberGenerator.GetBytes(NonceSizeBytes);
        byte[] tag = new byte[TagSizeBytes];
        byte[] cipherBytes = new byte[plainBytes.Length];

        using var aesGcm = new AesGcm(keyBytes, TagSizeBytes);
        aesGcm.Encrypt(nonce, plainBytes, cipherBytes, tag);

        return (cipherBytes, nonce, tag);
    }

    public byte[] DecryptData(byte[] cipherBytes, byte[] nonce, byte[] tag, byte[] keyBytes)
    {
        byte[] plainBytes = new byte[cipherBytes.Length];
        using var aesGcm = new AesGcm(keyBytes, TagSizeBytes);
        aesGcm.Decrypt(nonce, cipherBytes, tag, plainBytes);
        return plainBytes;
    }
}
