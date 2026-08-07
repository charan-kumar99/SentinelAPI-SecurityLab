import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/api_service.dart';

void main() {
  runApp(const ApiSecurityLabApp());
}

class ApiSecurityLabApp extends StatelessWidget {
  const ApiSecurityLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'API Security Lab - Flutter Enterprise Client',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF060911),
        cardColor: const Color(0xFF0D1424),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFFA855F7),
          surface: Color(0xFF0D1424),
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _usernameController = TextEditingController(text: 'flutter_sec_admin');
  final _emailController = TextEditingController(text: 'admin@flutter.sec');
  final _passwordController = TextEditingController(text: 'Argon2idPass2026!');
  final _sensitiveNoteController = TextEditingController(text: 'Confidential Credit Card: 4532-1111-2222-3333');

  final _sqliController = TextEditingController(text: "admin' OR '1'='1");
  final _xssController = TextEditingController(text: "<script>alert('XSS_ATTACK')</script><b>Safe Bold Text</b>");

  String _authOutput = 'Register or Login to generate JWT token & inspect claims...';
  String _noteOutput = 'AES-256-GCM ciphertext output...';
  String _sqliOutput = 'Select execution mode above to test query defense...';
  String _xssOutput = 'Click Sanitize Payload to strip dangerous tags...';
  List<Map<String, dynamic>> _rateLimitResults = [];
  List<dynamic> _auditLogs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _refreshAuditLogs();
  }

  Future<void> _refreshAuditLogs() async {
    final logs = await ApiService.fetchAuditLogs();
    setState(() {
      _auditLogs = logs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildCyberHeader(),
            _buildMetricsBar(),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: const Color(0xFF00E5FF),
              indicatorWeight: 3,
              labelColor: const Color(0xFF00E5FF),
              unselectedLabelColor: const Color(0xFF94A3B8),
              tabs: const [
                Tab(icon: Icon(Icons.vpn_key_rounded), text: 'Auth, JWT & AES Encryption'),
                Tab(icon: Icon(Icons.folder_special_rounded), text: 'Secure File Vault'),
                Tab(icon: Icon(Icons.bug_report_rounded), text: 'Attack Sandbox (SQLi/XSS)'),
                Tab(icon: Icon(Icons.flash_on_rounded), text: 'Rate Limiter Hammer'),
                Tab(icon: Icon(Icons.analytics_rounded), text: 'Security Audit Telemetry'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAuthAndAesTab(),
                  _buildFileVaultTab(),
                  _buildSandboxTab(),
                  _buildRateLimitTab(),
                  _buildAuditTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCyberHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1424),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 16)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5)),
                ),
                child: const Icon(Icons.shield_rounded, color: Color(0xFF00E5FF), size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'API SECURITY LAB',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.white, letterSpacing: 1),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA855F7).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA855F7)),
                        ),
                        child: const Text('Flutter Client v1.0', style: TextStyle(fontSize: 11, color: Color(0xFFA855F7), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Text('Cross-Platform Flutter Security Operations Workbench', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
            ),
            child: const Row(
              children: [
                CircleAvatar(radius: 4, backgroundColor: Color(0xFF10B981)),
                SizedBox(width: 8),
                Text('PostgreSQL (5433) & Redis (6380) LIVE', style: TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildMetricChip('Argon2id v13', 'Password Hashing', const Color(0xFF00E5FF), Icons.lock),
          const SizedBox(width: 12),
          _buildMetricChip('AES-256-GCM', 'Field Encryption', const Color(0xFFA855F7), Icons.enhanced_encryption),
          const SizedBox(width: 12),
          _buildMetricChip('Sliding Window', 'Redis Rate Limiter', const Color(0xFF10B981), Icons.speed),
          const SizedBox(width: 12),
          _buildMetricChip('Structured Telemetry', 'Security Audit', const Color(0xFFF97316), Icons.analytics),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String title, String subtitle, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1424),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthAndAesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🔑 User Registration & Argon2id Hashing', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password (Argon2id Hashed)', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black),
                          onPressed: () async {
                            final res = await ApiService.register(_usernameController.text, _emailController.text, _passwordController.text, 'Admin');
                            setState(() { _authOutput = JsonEncoder.withIndent('  ').convert(res); });
                          },
                          child: const Text('Register Account', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () async {
                            final res = await ApiService.login(_usernameController.text, _passwordController.text);
                            setState(() { _authOutput = JsonEncoder.withIndent('  ').convert(res); });
                          },
                          child: const Text('Login (Get JWT)'),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Text('🔐 Field-Level AES-256-GCM Encryption', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 12),
                    TextField(controller: _sensitiveNoteController, maxLines: 2, decoration: const InputDecoration(labelText: 'Sensitive Note / PII Data', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA855F7)),
                      onPressed: () async {
                        if (ApiService.accessToken == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please Register or Login first!')));
                          return;
                        }
                        final res = await ApiService.saveSensitiveNote(_sensitiveNoteController.text);
                        setState(() { _noteOutput = JsonEncoder.withIndent('  ').convert(res); });
                      },
                      child: const Text('Encrypt & Save Field to DB'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                _buildCodeBox('JWT RESPONSE & CLAIMS', _authOutput),
                const SizedBox(height: 16),
                _buildCodeBox('AES-256-GCM CIPHERTEXT RESULT', _noteOutput),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileVaultTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_special_rounded, size: 64, color: Color(0xFF00E5FF)),
            const SizedBox(height: 16),
            Text('📁 Secure File Vault & Magic Byte Sanitizer', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Upload files to encrypt with AES-256 on disk & issue signed download URLs.', style: TextStyle(color: Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }

  Widget _buildSandboxTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('⚔️ SQL Injection Defense', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    TextField(controller: _sqliController, decoration: const InputDecoration(labelText: 'SQL Exploit Payload', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                          onPressed: () async {
                            final res = await ApiService.testSqli(_sqliController.text, true);
                            setState(() { _sqliOutput = JsonEncoder.withIndent('  ').convert(res); });
                          },
                          child: const Text('Vulnerable Mode'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.black),
                          onPressed: () async {
                            final res = await ApiService.testSqli(_sqliController.text, false);
                            setState(() { _sqliOutput = JsonEncoder.withIndent('  ').convert(res); });
                          },
                          child: const Text('Parameterized Query', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCodeBox('SQL EXECUTION RESULT', _sqliOutput),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🛡️ XSS Payload Sanitization', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    TextField(controller: _xssController, decoration: const InputDecoration(labelText: 'XSS Vector Payload', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black),
                      onPressed: () async {
                        final res = await ApiService.testXss(_xssController.text);
                        setState(() { _xssOutput = JsonEncoder.withIndent('  ').convert(res); });
                      },
                      child: const Text('Sanitize Payload', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    _buildCodeBox('SANITIZED HTML OUTPUT', _xssOutput),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateLimitTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316), foregroundColor: Colors.black, padding: const EdgeInsets.all(20)),
            icon: const Icon(Icons.flash_on_rounded),
            label: const Text('🚀 LAUNCH BURST TRAFFIC ATTACK (10 REQUESTS)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            onPressed: () async {
              final res = await ApiService.testRateLimitBurst();
              setState(() { _rateLimitResults = res; });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _rateLimitResults.length,
              itemBuilder: (context, index) {
                final item = _rateLimitResults[index];
                final isBlocked = item['statusCode'] == 429;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isBlocked ? const Color(0xFFEF4444).withOpacity(0.15) : const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isBlocked ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Request #${item['index']}: ${isBlocked ? "🚫 [429 TOO MANY REQUESTS]" : "✅ [200 OK]"}',
                        style: TextStyle(color: isBlocked ? const Color(0xFFEF4444) : const Color(0xFF10B981), fontWeight: FontWeight.bold, fontFamily: 'Fira Code'),
                      ),
                      Text('${item['timeMs']}ms', style: const TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Fira Code')),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D1424), foregroundColor: Colors.white),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh Security Telemetry Stream'),
            onPressed: _refreshAuditLogs,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _auditLogs.length,
              itemBuilder: (context, index) {
                final log = _auditLogs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRiskColor(log['riskLevel']),
                      child: Text('${log['statusCode']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    title: Text('${log['action']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('IP: ${log['clientIp']} • ${log['endpoint']} • ${log['details']}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(dynamic risk) {
    if (risk == 'High' || risk == 'Critical' || risk == 3 || risk == 4) return const Color(0xFFEF4444);
    if (risk == 'Medium' || risk == 2) return const Color(0xFFF97316);
    return const Color(0xFF00E5FF);
  }

  Widget _buildCodeBox(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF030712),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: SelectableText(content, style: GoogleFonts.firaCode(fontSize: 13, color: const Color(0xFF38BDF8))),
        ),
      ],
    );
  }
}
