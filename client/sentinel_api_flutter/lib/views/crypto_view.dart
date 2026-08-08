import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_card.dart';
import '../widgets/code_preview.dart';
import '../widgets/badge_chip.dart';

class CryptoView extends StatefulWidget {
  const CryptoView({super.key});

  @override
  State<CryptoView> createState() => _CryptoViewState();
}

class _CryptoViewState extends State<CryptoView> {
  final _plainTextController = TextEditingController(text: 'Enterprise Token #88392-SECRET-PASSPHRASE');
  final _passwordController = TextEditingController(text: 'SuperArgon2idVaultPassword2026!');

  bool _loading = false;
  String _cryptoOutput = 'Run cryptographic benchmark to inspect AES-256-GCM & Argon2id metrics.';
  int? _lastElapsedMs;

  Future<void> _benchmarkCrypto() async {
    setState(() => _loading = true);
    final res = await ApiService.testCrypto(
      _plainTextController.text.trim(),
      _passwordController.text.trim(),
    );
    setState(() {
      _loading = false;
      _lastElapsedMs = res['argon2ElapsedMs'] is int ? res['argon2ElapsedMs'] : null;
      _cryptoOutput = const JsonEncoder.withIndent('  ').convert(res);
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
              // Left: Parameters & Controls
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    CyberCard(
                      title: 'Cryptographic Operations & Argon2id Studio',
                      subtitle: 'AES-256-GCM Authenticated Encryption & Memory-Hard Argon2id v13',
                      icon: Icons.lock_clock_rounded,
                      accentColor: CyberTheme.secondaryNeon,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _plainTextController,
                            decoration: const InputDecoration(
                              labelText: 'Plaintext Payload for AES-256-GCM',
                              prefixIcon: Icon(Icons.security, color: CyberTheme.secondaryNeon),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Password for Argon2id Memory Benchmark',
                              prefixIcon: Icon(Icons.key, color: CyberTheme.primaryNeon),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const CyberBadge(label: '64 MB Memory Matrix', color: CyberTheme.emeraldNeon),
                              const SizedBox(width: 8),
                              const CyberBadge(label: '3 Iterations (t=3)', color: CyberTheme.secondaryNeon),
                              const SizedBox(width: 8),
                              if (_lastElapsedMs != null)
                                CyberBadge(label: '$_lastElapsedMs ms CPU Time', color: CyberTheme.primaryNeon, hasGlow: true),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CyberTheme.secondaryNeon,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                            ),
                            icon: const Icon(Icons.speed_rounded, size: 18),
                            label: const Text('EXECUTE CRYPTO BENCHMARK', style: TextStyle(fontWeight: FontWeight.w900)),
                            onPressed: _loading ? null : _benchmarkCrypto,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Security Specifications Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CyberTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: CyberTheme.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DevSecOps Cryptographic Standards:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 8),
                          const Text(
                            '• NIST SP 800-38D: AES-256-GCM guarantees confidentiality and 128-bit authentication tag validation against tampering.\n• RFC 9106: Argon2id incorporates 64MB memory hardness and 3 iterations to thwart GPU/ASIC parallel dictionary attacks.',
                            style: TextStyle(fontSize: 12, color: CyberTheme.textMuted, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Right: Ciphertext & Hash Results
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    CyberCard(
                      title: 'Cryptographic Output & Telemetry',
                      subtitle: 'Ciphertext, Initialization Vector, Auth Tag & Argon2id Hash',
                      icon: Icons.data_object_rounded,
                      accentColor: CyberTheme.primaryNeon,
                      child: CyberCodeBox(
                        title: 'BENCHMARK METRICS & HASH DATA',
                        content: _cryptoOutput,
                        accentColor: CyberTheme.primaryNeon,
                        maxHeight: 380,
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
