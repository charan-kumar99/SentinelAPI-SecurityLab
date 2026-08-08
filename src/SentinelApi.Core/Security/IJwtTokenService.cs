using System.Security.Claims;
using SentinelApi.Core.Models;

namespace SentinelApi.Core.Security;

public interface IJwtTokenService
{
    string GenerateAccessToken(User user);
    RefreshToken GenerateRefreshToken(User user);
    ClaimsPrincipal? GetPrincipalFromExpiredToken(string token);
    bool ValidateTokenSignature(string token);
}
