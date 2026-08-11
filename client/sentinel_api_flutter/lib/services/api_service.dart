import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/auth_models.dart';
import '../models/file_models.dart';
import '../models/audit_models.dart';

class ApiService {
  static String baseUrl = 'http://localhost:5265/api/v1';

  static String? accessToken;
  static String? refreshToken;
  static String? currentUsername;
  static String? currentEmail;
  static String? currentRole;
  static String? currentUserId;
  static String? currentClientId;

  static bool get isLoggedIn => accessToken != null && accessToken!.isNotEmpty;

  static Map<String, String> get _headers {
    final map = {'Content-Type': 'application/json'};
    if (accessToken != null && accessToken!.isNotEmpty) {
      map['Authorization'] = 'Bearer $accessToken';
    }
    if (currentClientId != null && currentClientId!.isNotEmpty) {
      map['X-Client-Id'] = currentClientId!;
    }
    return map;
  }

  static void logout() {
    accessToken = null;
    refreshToken = null;
    currentUsername = null;
    currentEmail = null;
    currentRole = null;
    currentUserId = null;
    currentClientId = null;
  }

  // --- 1. Authentication Endpoints ---

  static Future<Map<String, dynamic>> register(
      String username, String email, String password, String role,
      {String clientId = 'sentinel-core'}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'X-Client-Id': clientId,
        },
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'role': role,
          'clientId': clientId,
        }),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      // Note: Register no longer returns tokens — must verify email first
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> verifyEmail(
      String email, String otp,
      {String clientId = 'sentinel-core'}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-email'),
        headers: {
          'Content-Type': 'application/json',
          'X-Client-Id': clientId,
        },
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'clientId': clientId,
        }),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) {
        accessToken = data['accessToken']?.toString();
        refreshToken = data['refreshToken']?.toString();
        if (data['user'] != null) {
          currentUsername = data['user']['username']?.toString();
          currentEmail = data['user']['email']?.toString();
          currentRole = data['user']['role']?.toString();
          currentUserId = data['user']['id']?.toString();
          currentClientId = data['user']['clientId']?.toString() ?? clientId;
        }
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> resendOtp(
      String email,
      {String clientId = 'sentinel-core'}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-otp'),
        headers: {
          'Content-Type': 'application/json',
          'X-Client-Id': clientId,
        },
        body: jsonEncode({
          'email': email,
          'clientId': clientId,
        }),
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> login(
      String usernameOrEmail, String password,
      {String clientId = 'sentinel-core'}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'X-Client-Id': clientId,
        },
        body: jsonEncode({
          'usernameOrEmail': usernameOrEmail,
          'password': password,
          'clientId': clientId,
        }),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) {
        accessToken = data['accessToken']?.toString();
        refreshToken = data['refreshToken']?.toString();
        if (data['user'] != null) {
          currentUsername = data['user']['username']?.toString();
          currentEmail = data['user']['email']?.toString();
          currentRole = data['user']['role']?.toString();
          currentUserId = data['user']['id']?.toString();
          currentClientId = data['user']['clientId']?.toString() ?? clientId;
        }
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> refreshSession() async {
    if (accessToken == null || refreshToken == null) {
      return {'success': false, 'message': 'No active tokens to refresh.'};
    }
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'accessToken': accessToken,
          'refreshToken': refreshToken,
        }),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) {
        accessToken = data['accessToken']?.toString();
        refreshToken = data['refreshToken']?.toString();
        if (data['user'] != null) {
          currentUsername = data['user']['username']?.toString();
          currentEmail = data['user']['email']?.toString();
          currentRole = data['user']['role']?.toString();
          currentUserId = data['user']['id']?.toString();
        }
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Refresh error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'success': false, 'status': response.statusCode, 'body': response.body};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> saveSensitiveNote(String note) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/sensitive-note'),
        headers: _headers,
        body: jsonEncode({'note': note}),
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // --- 2. Secure File Vault & Magic Byte Sanitizer ---

  static Future<Map<String, dynamic>> uploadFile({
    required String fileName,
    required List<int> bytes,
    required String contentType,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/files/upload');
      final request = http.MultipartRequest('POST', uri);

      if (accessToken != null) {
        request.headers['Authorization'] = 'Bearer $accessToken';
      }

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'statusCode': response.statusCode,
        ...data,
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'error': 'Upload failure: $e',
      };
    }
  }

  static Future<List<FileMetadataDto>> getMyFiles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/files/my-files'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((item) => FileMetadataDto.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> generateSignedUrl(
      String fileId, {int expirationSeconds = 300}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/files/signed-url/$fileId?expirationSeconds=$expirationSeconds'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'success': false, 'status': response.statusCode, 'body': response.body};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Uint8List?> downloadFileBytes(
      String fileId, {int? expires, String? signature}) async {
    try {
      Uri uri;
      if (expires != null && signature != null && signature.isNotEmpty) {
        uri = Uri.parse('$baseUrl/files/download/$fileId?expires=$expires&signature=$signature');
      } else {
        uri = Uri.parse('$baseUrl/files/download/$fileId');
      }

      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- 3. Attack Sandbox & Crypto Benchmarking ---

  static Future<Map<String, dynamic>> testSqli(
      String payload, bool vulnerableMode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/lab/sqli'),
        headers: _headers,
        body: jsonEncode({
          'searchInput': payload,
          'executeVulnerableMode': vulnerableMode,
        }),
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> testXss(String payload) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/lab/xss'),
        headers: _headers,
        body: jsonEncode({'rawPayload': payload}),
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> testCrypto(
      String plainText, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/lab/crypto'),
        headers: _headers,
        body: jsonEncode({
          'plainText': plainText,
          'password': password,
        }),
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // --- 4. Rate Limiting Hammer ---

  static Future<List<Map<String, dynamic>>> testRateLimitBurst({int count = 10}) async {
    final results = <Map<String, dynamic>>[];
    for (int i = 1; i <= count; i++) {
      final sw = Stopwatch()..start();
      try {
        final res = await http.get(Uri.parse('$baseUrl/lab/rate-limit-test'));
        sw.stop();
        results.add({
          'index': i,
          'statusCode': res.statusCode,
          'timeMs': sw.elapsedMilliseconds,
          'body': res.body,
          'success': res.statusCode == 200,
        });
      } catch (e) {
        sw.stop();
        results.add({
          'index': i,
          'statusCode': 0,
          'timeMs': sw.elapsedMilliseconds,
          'body': 'Connection failed: $e',
          'success': false,
        });
      }
    }
    return results;
  }

  // --- 5. Security Audit Telemetry ---

  static Future<List<AuditLogDto>> fetchRecentAuditLogs({int count = 30}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/audit-logs/recent?count=$count'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((item) => AuditLogDto.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
