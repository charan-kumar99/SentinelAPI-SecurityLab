import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_card.dart';
import '../widgets/code_preview.dart';
import '../widgets/badge_chip.dart';

class SandboxView extends StatefulWidget {
  const SandboxView({super.key});

  @override
  State<SandboxView> createState() => _SandboxViewState();
}

class _SandboxViewState extends State<SandboxView> {
  final _sqliController = TextEditingController(text: "admin' OR '1'='1");
  final _xssController = TextEditingController(
    text: "<script>alert('XSS_PWNED')</script><b>Safe Bold Header</b><img src=x onerror=alert('PWNED')>",
  );

  bool _loading = false;
  String _sqliOutput = 'Select execution mode below to test dynamic SQL vs parameterized AST defense.';
  String _xssOutput = 'Click Sanitize Payload to test AntiXSS DOM tag stripping & entity encoding.';

  Future<void> _testSqli(bool vulnerableMode) async {
    setState(() => _loading = true);
    final res = await ApiService.testSqli(_sqliController.text.trim(), vulnerableMode);
    setState(() {
      _loading = false;
      _sqliOutput = const JsonEncoder.withIndent('  ').convert(res);
    });
  }

  Future<void> _testXss() async {
    setState(() => _loading = true);
    final res = await ApiService.testXss(_xssController.text.trim());
    setState(() {
      _loading = false;
      _xssOutput = const JsonEncoder.withIndent('  ').convert(res);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: SQL Injection Chamber
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    CyberCard(
                      title: 'SQL Injection Defense Chamber',
                      subtitle: 'Comparing Unsafe String Concatenation vs Parameterized AST Query Binding',
                      icon: Icons.pest_control_rounded,
                      accentColor: CyberTheme.crimsonNeon,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _sqliController,
                            style: CyberTheme.codeFont(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'SQL Payload / Search Parameter',
                              prefixIcon: Icon(Icons.code, color: CyberTheme.crimsonNeon),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('Exploit Presets:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              ActionChip(
                                label: const Text("' OR '1'='1"),
                                onPressed: () => setState(() => _sqliController.text = "' OR '1'='1"),
                              ),
                              ActionChip(
                                label: const Text("admin'--"),
                                onPressed: () => setState(() => _sqliController.text = "admin'--"),
                              ),
                              ActionChip(
                                label: const Text("UNION SELECT"),
                                onPressed: () => setState(() => _sqliController.text = "' UNION SELECT null, username, password_hash, role FROM \"Users\"--"),
                              ),
                              ActionChip(
                                label: const Text("Normal Query"),
                                onPressed: () => setState(() => _sqliController.text = "sentinel_admin"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: CyberTheme.crimsonNeon,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  icon: const Icon(Icons.dangerous_rounded, size: 18),
                                  label: const Text('VULNERABLE MODE', style: TextStyle(fontWeight: FontWeight.w900)),
                                  onPressed: _loading ? null : () => _testSqli(true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: CyberTheme.emeraldNeon,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  icon: const Icon(Icons.shield_rounded, size: 18),
                                  label: const Text('PARAMETERIZED DEFENSE', style: TextStyle(fontWeight: FontWeight.w900)),
                                  onPressed: _loading ? null : () => _testSqli(false),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          CyberCodeBox(
                            title: 'SQL EXECUTION & AST ANALYSIS',
                            content: _sqliOutput,
                            accentColor: CyberTheme.crimsonNeon,
                            maxHeight: 250,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Right: XSS Chamber
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    CyberCard(
                      title: 'XSS & HTML Sanitization Chamber',
                      subtitle: 'AntiXSS DOM Tree Stripping & Strict HTML Entity Encoding',
                      icon: Icons.shield_rounded,
                      accentColor: CyberTheme.primaryNeon,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _xssController,
                            maxLines: 2,
                            style: CyberTheme.codeFont(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Untrusted HTML / Script Vector',
                              prefixIcon: Icon(Icons.html_rounded, color: CyberTheme.primaryNeon),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('XSS Attack Vectors:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              ActionChip(
                                label: const Text("<script>alert()</script>"),
                                onPressed: () => setState(() => _xssController.text = "<script>alert('DOM_PWNED')</script>"),
                              ),
                              ActionChip(
                                label: const Text("<img onerror=...>"),
                                onPressed: () => setState(() => _xssController.text = "<img src=invalid onerror=alert('IMAGE_EXPLOIT')>"),
                              ),
                              ActionChip(
                                label: const Text("<svg onload=...>"),
                                onPressed: () => setState(() => _xssController.text = "<svg onload=alert(document.domain)>"),
                              ),
                              ActionChip(
                                label: const Text("JavaScript: URI"),
                                onPressed: () => setState(() => _xssController.text = "<a href=\"javascript:alert('CLICK_XSS')\">Free Gift</a>"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CyberTheme.primaryNeon,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                            ),
                            icon: const Icon(Icons.cleaning_services_rounded, size: 18),
                            label: const Text('SANITIZE & ENCODE PAYLOAD', style: TextStyle(fontWeight: FontWeight.w900)),
                            onPressed: _loading ? null : _testXss,
                          ),
                          const SizedBox(height: 16),
                          CyberCodeBox(
                            title: 'SANITIZED & HTML ENCODED OUTPUT',
                            content: _xssOutput,
                            accentColor: CyberTheme.primaryNeon,
                            maxHeight: 250,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
