using System.Security.Claims;
using ApiSecurityLab.Core.Models;

namespace ApiSecurityLab.Core.Security;

public interface IJwtTokenService
{
    string GenerateAccessToken(User user);
    RefreshToken GenerateRefreshToken(User user);
    ClaimsPrincipal? GetPrincipalFromExpiredToken(string token);
    bool ValidateTokenSignature(string token);
}
