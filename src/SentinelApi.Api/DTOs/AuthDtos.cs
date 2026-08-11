namespace SentinelApi.Api.DTOs;

public record RegisterRequest(string Username, string Email, string Password, string Role = "User", string ClientId = "sentinel-core");
public record LoginRequest(string UsernameOrEmail, string Password, string ClientId = "sentinel-core");
public record AuthResponse(bool Success, string Message, string? AccessToken, string? RefreshToken, UserDto? User);
public record RefreshTokenRequest(string AccessToken, string RefreshToken);
public record UserDto(string Id, string Username, string Email, string Role, string CreatedAt, string ClientId = "sentinel-core");
public record UpdateSensitiveNoteRequest(string Note);
public record VerifyEmailRequest(string Email, string Otp, string ClientId = "sentinel-core");
public record ResendOtpRequest(string Email, string ClientId = "sentinel-core");

