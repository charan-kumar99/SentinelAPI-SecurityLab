namespace ApiSecurityLab.Api.DTOs;

public record SqlTestRequest(string SearchInput, bool ExecuteVulnerableMode);
public record SqlTestResponse(string ExecutedQuery, bool WasVulnerable, object Results, string SecurityAnalysis);

public record XssTestRequest(string RawPayload);
public record XssTestResponse(string RawPayload, string SanitizedHtml, string EncodedOutput, string SecurityAnalysis);

public record CryptoTestRequest(string PlainText, string Password);
public record CryptoTestResponse(
    string PlainText,
    string AesGcmCipherTextBase64,
    string DecryptedText,
    string Argon2HashBase64,
    string Argon2SaltBase64,
    long HashExecutionTimeMs,
    string SecurityAnalysis
);
