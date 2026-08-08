class AuditLogDto {
  final String id;
  final String? userId;
  final String action;
  final String endpoint;
  final String httpMethod;
  final int statusCode;
  final String clientIp;
  final dynamic riskLevel; // int or String (0=Low, 1=Medium, 2=High, 3=Critical)
  final String timestamp;
  final String details;

  AuditLogDto({
    required this.id,
    this.userId,
    required this.action,
    required this.endpoint,
    required this.httpMethod,
    required this.statusCode,
    required this.clientIp,
    required this.riskLevel,
    required this.timestamp,
    required this.details,
  });

  factory AuditLogDto.fromJson(Map<String, dynamic> json) {
    return AuditLogDto(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString(),
      action: json['action']?.toString() ?? 'SYSTEM_EVENT',
      endpoint: json['endpoint']?.toString() ?? '/',
      httpMethod: json['httpMethod']?.toString() ?? 'GET',
      statusCode: json['statusCode'] is int ? json['statusCode'] : int.tryParse(json['statusCode']?.toString() ?? '200') ?? 200,
      clientIp: json['clientIp']?.toString() ?? '127.0.0.1',
      riskLevel: json['riskLevel'] ?? 'Low',
      timestamp: json['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
      details: json['details']?.toString() ?? '',
    );
  }

  String get riskString {
    if (riskLevel is int) {
      switch (riskLevel) {
        case 3:
        case 4:
          return 'Critical';
        case 2:
          return 'High';
        case 1:
          return 'Medium';
        default:
          return 'Low';
      }
    }
    return riskLevel?.toString() ?? 'Low';
  }
}
