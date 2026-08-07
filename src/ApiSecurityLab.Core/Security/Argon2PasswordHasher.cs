using System;
using System.Security.Cryptography;
using System.Text;
using Konscious.Security.Cryptography;

namespace ApiSecurityLab.Core.Security;

public class Argon2PasswordHasher : IPasswordHasher
{
    private const int SaltSizeBytes = 16;
    private const int HashSizeBytes = 32;
    private const int DegreeOfParallelism = 2;
    private const int MemorySizeKb = 65536; // 64MB memory cost
    private const int Iterations = 3;

    public (string hashBase64, string saltBase64) HashPassword(string password)
    {
        byte[] salt = RandomNumberGenerator.GetBytes(SaltSizeBytes);
        byte[] hash = ComputeArgon2IdHash(password, salt);

        return (Convert.ToBase64String(hash), Convert.ToBase64String(salt));
    }

    public bool VerifyPassword(string password, string hashBase64, string saltBase64)
    {
        try
        {
            byte[] salt = Convert.FromBase64String(saltBase64);
            byte[] storedHash = Convert.FromBase64String(hashBase64);
            byte[] computedHash = ComputeArgon2IdHash(password, salt);

            return CryptographicOperations.FixedTimeEquals(storedHash, computedHash);
        }
        catch
        {
            return false;
        }
    }

    private static byte[] ComputeArgon2IdHash(string password, byte[] salt)
    {
        using var argon2 = new Argon2id(Encoding.UTF8.GetBytes(password))
        {
            Salt = salt,
            DegreeOfParallelism = DegreeOfParallelism,
            MemorySize = MemorySizeKb,
            Iterations = Iterations
        };
        return argon2.GetBytes(HashSizeBytes);
    }
}
