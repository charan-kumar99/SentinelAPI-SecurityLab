class UserDto {
  final String id;
  final String username;
  final String email;
  final String role;
  final String createdAt;

  UserDto({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'User',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class AuthResult {
  final bool success;
  final String message;
  final String? accessToken;
  final String? refreshToken;
  final UserDto? user;

  AuthResult({
    required this.success,
    required this.message,
    this.accessToken,
    this.refreshToken,
    this.user,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      accessToken: json['accessToken']?.toString(),
      refreshToken: json['refreshToken']?.toString(),
      user: json['user'] != null ? UserDto.fromJson(json['user'] as Map<String, dynamic>) : null,
    );
  }
}
