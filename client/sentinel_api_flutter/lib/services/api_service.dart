import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:5265/api/v1';

  static String? accessToken;
  static String? refreshToken;
  static String? currentUsername;
  static String? currentRole;

  static Map<String, String> get _headers {
    final map = {'Content-Type': 'application/json'};
    if (accessToken != null) {
      map['Authorization'] = 'Bearer $accessToken';
    }
    return map;
  }

  static Future<Map<String, dynamic>> register(String username, String email, String password, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode({'username': username, 'email': email, 'password': password, 'role': role}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      accessToken = data['accessToken'];
      refreshToken = data['refreshToken'];
      currentUsername = data['user']['username'];
      currentRole = data['user']['role'];
    }
    return data;
  }

  static Future<Map<String, dynamic>> login(String usernameOrEmail, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({'usernameOrEmail': usernameOrEmail, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      accessToken = data['accessToken'];
      refreshToken = data['refreshToken'];
      currentUsername = data['user']['username'];
      currentRole = data['user']['role'];
    }
    return data;
  }

  static Future<Map<String, dynamic>> saveSensitiveNote(String note) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/sensitive-note'),
      headers: _headers,
      body: jsonEncode({'note': note}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> testSqli(String payload, bool vulnerableMode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/lab/sqli'),
      headers: _headers,
      body: jsonEncode({'searchInput': payload, 'executeVulnerableMode': vulnerableMode}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> testXss(String payload) async {
    final response = await http.post(
      Uri.parse('$baseUrl/lab/xss'),
      headers: _headers,
      body: jsonEncode({'rawPayload': payload}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> testCrypto(String plainText, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/lab/crypto'),
      headers: _headers,
      body: jsonEncode({'plainText': plainText, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  static Future<List<Map<String, dynamic>>> testRateLimitBurst() async {
    final results = <Map<String, dynamic>>[];
    for (int i = 1; i <= 10; i++) {
      final sw = Stopwatch()..start();
      final res = await http.get(Uri.parse('$baseUrl/lab/rate-limit-test'));
      sw.stop();
      results.add({
        'index': i,
        'statusCode': res.statusCode,
        'timeMs': sw.elapsedMilliseconds,
        'body': res.body,
      });
    }
    return results;
  }

  static Future<List<dynamic>> fetchAuditLogs() async {
    final response = await http.get(Uri.parse('$baseUrl/audit-logs/recent?count=30'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }
}
