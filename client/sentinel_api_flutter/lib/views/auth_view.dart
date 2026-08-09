import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_card.dart';
import '../widgets/code_preview.dart';
import '../widgets/badge_chip.dart';

class AuthView extends StatefulWidget {
  final VoidCallback onStateChange;

  const AuthView({super.key, required this.onStateChange});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final _usernameController = TextEditingController(text: 'devsecops_tester');
  final _emailController = TextEditingController(text: 'tester@sentinel.sec');
  final _passwordController = TextEditingController(text: 'Argon2idPass2026!');
  final _roleController = TextEditingController(text: 'Admin');
  final _sensitiveNoteController = TextEditingController(
    text: 'Confidential PCI-DSS Card: 4532-8822-1199-3401 | CVV: 891 | Exp: 09/29',
  );

  bool _loading = false;
  String _jwtOutput = 'Register or Login to generate HMAC-SHA256 JWT & inspect claims...';
  String _decodedClaimsOutput = 'No active JWT token loaded.';
  String _refreshOutput = 'Trigger refresh token rotation to inspect replay defense.';
  String _noteOutput = 'Submit sensitive data to execute AES-256-GCM field encryption.';

  void _decodeJwt(String? token) {
    if (token == null || token.isEmpty) {
      setState(() => _decodedClaimsOutput = 'No token provided.');
      return;
    }
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        String normalized = base64Url.normalize(parts[1]);
        final payloadStr = utf8.decode(base64Url.decode(normalized));
        final prettyJson = const JsonEncoder.withIndent('  ').convert(jsonDecode(payloadStr));
        setState(() {
          _decodedClaimsOutput = '--- JWT HEADER (HS256) ---\n${utf8.decode(base64Url.decode(base64Url.normalize(parts[0])))}\n\n--- JWT PAYLOAD CLAIMS ---\n$prettyJson';
        });
      }
    } catch (e) {
      setState(() => _decodedClaimsOutput = 'JWT Decode error: $e');
    }
  }

  void _generateFreshIdentity() {
    final rand = math.Random().nextInt(9000) + 1000;
    setState(() {
      _usernameController.text = 'sentinel_agent_$rand';
      _emailController.text = 'agent_$rand@sentinel.sec';
    });
  }

  Future<void> _handleRegister() async {
    setState(() => _loading = true);
    final res = await ApiService.register(
      _usernameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _roleController.text.trim(),
    );
    setState(() {
      _loading = false;
      _jwtOutput = const JsonEncoder.withIndent('  ').convert(res);
      if (ApiService.accessToken != null) {
        _decodeJwt(ApiService.accessToken);
      }
    });
    widget.onStateChange();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['success'] == true ? 'Registered successfully! Argon2id password hash created.' : '${res['message'] ?? res['error']}'),
          backgroundColor: res['success'] == true ? CyberTheme.emeraldNeon : CyberTheme.crimsonNeon,
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
    setState(() => _loading = true);
    final res = await ApiService.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );
    setState(() {
      _loading = false;
      _jwtOutput = const JsonEncoder.withIndent('  ').convert(res);
      if (ApiService.accessToken != null) {
        _decodeJwt(ApiService.accessToken);
      }
    });
    widget.onStateChange();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['success'] == true ? 'Login successful! Access & Refresh tokens generated.' : 'Login failed: ${res['message']}'),
          backgroundColor: res['success'] == true ? CyberTheme.emeraldNeon : CyberTheme.crimsonNeon,
        ),
      );
    }
  }

  Future<void> _handleRefreshToken() async {
    setState(() => _loading = true);
    final res = await ApiService.refreshSession();
    setState(() {
      _loading = false;
      _refreshOutput = const JsonEncoder.withIndent('  ').convert(res);
      if (ApiService.accessToken != null) {
        _decodeJwt(ApiService.accessToken);
      }
    });
    widget.onStateChange();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['success'] == true ? 'Token rotated! Old refresh token revoked.' : 'Refresh failed: ${res['message']}'),
          backgroundColor: res['success'] == true ? CyberTheme.secondaryNeon : CyberTheme.crimsonNeon,
        ),
      );
    }
  }

  Future<void> _handleSaveNote() async {
    if (!ApiService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please Register or Login first!')),
      );
      return;
    }
    setState(() => _loading = true);
    final res = await ApiService.saveSensitiveNote(_sensitiveNoteController.text.trim());
    setState(() {
      _loading = false;
      _noteOutput = const JsonEncoder.withIndent('  ').convert(res);
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
              // Left Column: Credentials & Auth Actions
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    CyberCard(
                      title: 'Identity & Authentication Hub',
                      subtitle: 'Argon2id v13 Password Hashing & Dual-Token Architecture',
                      icon: Icons.vpn_key_rounded,
                      accentColor: CyberTheme.primaryNeon,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _usernameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Username',
                                    prefixIcon: Icon(Icons.person_outline, color: CyberTheme.primaryNeon),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _roleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Role (Admin / User)',
                                    prefixIcon: Icon(Icons.verified_user_outlined, color: CyberTheme.secondaryNeon),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.alternate_email, color: CyberTheme.primaryNeon),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password (Argon2id 64MB Hashed)',
                              prefixIcon: Icon(Icons.lock_outline, color: CyberTheme.primaryNeon),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: CyberTheme.primaryNeon,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  icon: const Icon(Icons.person_add_rounded, size: 18),
                                  label: const Text('REGISTER USER', style: TextStyle(fontWeight: FontWeight.w900)),
                                  onPressed: _loading ? null : _handleRegister,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: CyberTheme.primaryNeon),
                                    foregroundColor: CyberTheme.primaryNeon,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  icon: const Icon(Icons.login_rounded, size: 18),
                                  label: const Text('LOGIN (GET JWT)', style: TextStyle(fontWeight: FontWeight.w900)),
                                  onPressed: _loading ? null : _handleLogin,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Generate Random Unique User & Email',
                                style: IconButton.styleFrom(
                                  backgroundColor: CyberTheme.secondaryNeon.withOpacity(0.15),
                                  side: BorderSide(color: CyberTheme.secondaryNeon.withOpacity(0.5)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.shuffle_rounded, size: 18, color: CyberTheme.secondaryNeon),
                                onPressed: _generateFreshIdentity,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // AES-256-GCM Field Level Encryption Studio
                    CyberCard(
                      title: 'Field-Level AES-256-GCM Encryption',
                      subtitle: 'Authenticating Data-at-Rest with 128-bit Integrity Tag',
                      icon: Icons.enhanced_encryption_rounded,
                      accentColor: CyberTheme.secondaryNeon,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _sensitiveNoteController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Sensitive PII / Credit Card Payload',
                              prefixIcon: Icon(Icons.credit_card, color: CyberTheme.secondaryNeon),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  CyberBadge(label: 'AES-GCM 256-bit', color: CyberTheme.secondaryNeon),
                                  SizedBox(width: 8),
                                  CyberBadge(label: '96-bit Nonce / IV', color: CyberTheme.emeraldNeon),
                                ],
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: CyberTheme.secondaryNeon,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.lock_rounded, size: 16),
                                label: const Text('ENCRYPT & SAVE TO DB'),
                                onPressed: _loading ? null : _handleSaveNote,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          CyberCodeBox(
                            title: 'AES-256-GCM CIPHERTEXT AT REST',
                            content: _noteOutput,
                            accentColor: CyberTheme.secondaryNeon,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Right Column: Decoded JWT & Refresh Token Lifecycle
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    CyberCard(
                      title: 'Decoded JWT Claims Inspector',
                      subtitle: 'Cryptographic HS256 Token Validation & Expiry Tracking',
                      icon: Icons.code_rounded,
                      accentColor: CyberTheme.primaryNeon,
                      trailing: ApiService.isLoggedIn
                          ? const CyberBadge(label: 'TOKEN ACTIVE', color: CyberTheme.emeraldNeon, hasGlow: true)
                          : const CyberBadge(label: 'NO TOKEN', color: CyberTheme.amberNeon),
                      child: Column(
                        children: [
                          CyberCodeBox(
                            title: 'DECODED TOKEN CLAIMS (PAYLOAD)',
                            content: _decodedClaimsOutput,
                            accentColor: CyberTheme.primaryNeon,
                            maxHeight: 180,
                          ),
                          const SizedBox(height: 12),
                          CyberCodeBox(
                            title: 'RAW AUTH RESPONSE',
                            content: _jwtOutput,
                            accentColor: CyberTheme.textMuted,
                            maxHeight: 120,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    CyberCard(
                      title: 'Refresh Token Rotation Lab',
                      subtitle: 'Replay-Attack Prevention & Automatic Token Invalidation',
                      icon: Icons.autorenew_rounded,
                      accentColor: CyberTheme.amberNeon,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Exchange current refresh token for a brand new pair and revoke old token:',
                                style: TextStyle(fontSize: 12, color: CyberTheme.textMuted),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: CyberTheme.amberNeon,
                                  foregroundColor: Colors.black,
                                ),
                                icon: const Icon(Icons.sync_lock_rounded, size: 16),
                                label: const Text('ROTATE TOKEN PAIR', style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: _loading ? null : _handleRefreshToken,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          CyberCodeBox(
                            title: 'TOKEN ROTATION RESULT',
                            content: _refreshOutput,
                            accentColor: CyberTheme.amberNeon,
                            maxHeight: 140,
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
