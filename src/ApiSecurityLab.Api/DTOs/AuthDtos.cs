namespace ApiSecurityLab.Api.DTOs;

public record RegisterRequest(string Username, string Email, string Password, string Role = "User");
public record LoginRequest(string UsernameOrEmail, string Password);
public record AuthResponse(bool Success, string Message, string? AccessToken, string? RefreshToken, UserDto? User);
public record RefreshTokenRequest(string AccessToken, string RefreshToken);
public record UserDto(string Id, string Username, string Email, string Role, string CreatedAt);
public record UpdateSensitiveNoteRequest(string Note);
