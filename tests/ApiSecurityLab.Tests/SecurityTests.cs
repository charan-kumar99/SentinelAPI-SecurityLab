using System;
using System.IO;
using System.Text;
using ApiSecurityLab.Core.Models;
using ApiSecurityLab.Core.Security;
using FluentAssertions;
using Xunit;

namespace ApiSecurityLab.Tests;

public class SecurityTests
{
    private readonly AesGcmEncryptionService _encryptionService = new();
    private readonly Argon2PasswordHasher _passwordHasher = new();
    private readonly FileSanitizerService _fileSanitizer = new();
    private readonly XssSanitizerService _xssSanitizer = new();
    private readonly JwtTokenService _jwtService = new(new JwtTokenSettings());

    [Fact]
    public void JwtTokenService_GeneratesAndValidatesToken()
    {
        // Arrange
        var user = new User
        {
            Id = Guid.NewGuid(),
            Username = "securitytester",
            Email = "tester@lab.sec",
            Role = "Admin"
        };

        // Act
        string token = _jwtService.GenerateAccessToken(user);
        bool isValid = _jwtService.ValidateTokenSignature(token);
        var principal = _jwtService.GetPrincipalFromExpiredToken(token);

        // Assert
        token.Should().NotBeNullOrEmpty();
        isValid.Should().BeTrue();
        principal.Should().NotBeNull();
        principal!.FindFirst(System.Security.Claims.ClaimTypes.Name)?.Value.Should().Be("securitytester");
        principal.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value.Should().Be(user.Id.ToString());
    }

    [Fact]
    public void Argon2PasswordHasher_HashesAndVerifiesPassword()
    {
        // Arrange
        string rawPassword = "StrongSecretPassword123!";

        // Act
        var (hash, salt) = _passwordHasher.HashPassword(rawPassword);
        bool isCorrectValid = _passwordHasher.VerifyPassword(rawPassword, hash, salt);
        bool isWrongValid = _passwordHasher.VerifyPassword("WrongPassword123!", hash, salt);

        // Assert
        hash.Should().NotBeNullOrEmpty();
        salt.Should().NotBeNullOrEmpty();
        isCorrectValid.Should().BeTrue();
        isWrongValid.Should().BeFalse();
    }

    [Fact]
    public void AesGcmEncryptionService_EncryptsAndDecryptsText()
    {
        // Arrange
        string masterKey = Convert.ToBase64String(_encryptionService.GenerateRandomKey());
        string sensitiveData = "Confidential User Payload SSN: 999-00-1234";

        // Act
        string cipherText = _encryptionService.EncryptText(sensitiveData, masterKey);
        string decryptedText = _encryptionService.DecryptText(cipherText, masterKey);

        // Assert
        cipherText.Should().NotBeNullOrEmpty();
        cipherText.Should().NotBe(sensitiveData);
        decryptedText.Should().Be(sensitiveData);
    }

    [Fact]
    public void FileSanitizer_RejectsExecutableMasqueradingAsImage()
    {
        // Arrange: Binary stream starting with 'M' 'Z' (0x4D, 0x5A) disguised as .png
        byte[] exeBytes = new byte[] { 0x4D, 0x5A, 0x90, 0x00, 0x03, 0x00, 0x00, 0x00 };
        using var stream = new MemoryStream(exeBytes);

        // Act
        var result = _fileSanitizer.ValidateFile("malware.png", stream);

        // Assert
        result.IsValid.Should().BeFalse();
        result.ErrorMessage.Should().Contain("Executable binary");
    }

    [Fact]
    public void FileSanitizer_ValidatesGenuinePngImage()
    {
        // Arrange: Valid PNG Magic Bytes (0x89 0x50 0x4E 0x47 0x0D 0x0A 0x1A 0x0A)
        byte[] pngHeader = new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D };
        using var stream = new MemoryStream(pngHeader);

        // Act
        var result = _fileSanitizer.ValidateFile("photo.png", stream);

        // Assert
        result.IsValid.Should().BeTrue();
        result.ErrorMessage.Should().BeEmpty();
    }

    [Fact]
    public void FileSanitizer_SanitizesPathTraversalSequences()
    {
        // Arrange
        string maliciousPath = "../../etc/passwd";

        // Act
        string safeName = _fileSanitizer.SanitizeFileName(maliciousPath);

        // Assert
        safeName.Should().NotContain("..");
        safeName.Should().NotContain("/");
        safeName.Should().NotContain("\\");
    }

    [Fact]
    public void XssSanitizer_StripsScriptTags()
    {
        // Arrange
        string xssPayload = "<script>alert('hack')</script><img src=x onerror=alert('xss')><b>Hello</b>";

        // Act
        string sanitized = _xssSanitizer.SanitizeHtml(xssPayload);
        string encoded = _xssSanitizer.HtmlEncode(xssPayload);

        // Assert
        sanitized.Should().NotContain("<script>");
        sanitized.Should().NotContain("onerror=");
        sanitized.Should().Contain("<b>Hello</b>");

        encoded.Should().Contain("&lt;script&gt;");
    }
}
