using System;

namespace ApiSecurityLab.Core.Security;

public interface IEncryptionService
{
    string EncryptText(string plainText, string masterKeyBase64);
    string DecryptText(string cipherTextBase64, string masterKeyBase64);
    (byte[] cipherBytes, byte[] nonce, byte[] tag) EncryptData(byte[] plainBytes, byte[] keyBytes);
    byte[] DecryptData(byte[] cipherBytes, byte[] nonce, byte[] tag, byte[] keyBytes);
    byte[] GenerateRandomKey();
}
