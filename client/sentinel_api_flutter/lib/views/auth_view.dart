import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _AuthViewState extends State<AuthView> with TickerProviderStateMixin {
  final _usernameController = TextEditingController(text: 'devsecops_tester');
  final _emailController = TextEditingController(text: 'sentinelapi.security@gmail.com');
  final _passwordController = TextEditingController(text: 'Argon2idPass2026!');
  final _roleController = TextEditingController(text: 'Admin');
  final _sensitiveNoteController = TextEditingController(
    text: 'Confidential PCI-DSS Card: 4532-8822-1199-3401 | CVV: 891 | Exp: 09/29',
  );
  final _clientIdController = TextEditingController(text: 'sentinel-core');

  // OTP Controllers (6 individual boxes)
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  bool _showOtpVerification = false;
  String _pendingVerificationEmail = '';
  String _pendingVerificationClientId = 'sentinel-core';
  String _jwtOutput = 'Register or Login to generate HMAC-SHA256 JWT & inspect claims...';
  String _decodedClaimsOutput = 'No active JWT token loaded.';
  String _refreshOutput = 'Trigger refresh token rotation to inspect replay defense.';
  String _noteOutput = 'Submit sensitive data to execute AES-256-GCM field encryption.';

  // OTP Timer
  Timer? _otpTimer;
  int _otpSecondsRemaining = 600; // 10 minutes
  bool _canResendOtp = false;
  int _resendCooldown = 0;
  Timer? _resendTimer;

  // Animation
  late AnimationController _otpPulseController;
  late Animation<double> _otpPulseAnimation;
  late AnimationController _successController;
  late Animation<double> _successAnimation;
  bool _showSuccess = false;

  String get _activeClientId =>
      _clientIdController.text.trim().isNotEmpty
          ? _clientIdController.text.trim().toLowerCase()
          : 'sentinel-core';

  @override
  void initState() {
    super.initState();
    _otpPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _otpPulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _otpPulseController, curve: Curves.easeInOut),
    );

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _successAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _otpTimer?.cancel();
    _resendTimer?.cancel();
    _otpPulseController.dispose();
    _successController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    _clientIdController.dispose();
    super.dispose();
  }

  void _startOtpTimer() {
    _otpTimer?.cancel();
    _otpSecondsRemaining = 600;
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_otpSecondsRemaining > 0) {
          _otpSecondsRemaining--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _startResendCooldown() {
    _canResendOtp = false;
    _resendCooldown = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCooldown > 0) {
          _resendCooldown--;
        } else {
          _canResendOtp = true;
          timer.cancel();
        }
      });
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _otpValue => _otpControllers.map((c) => c.text).join();

  void _clearOtp() {
    for (var c in _otpControllers) {
      c.clear();
    }
    _otpFocusNodes[0].requestFocus();
  }

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
      _usernameController.text = 'agent_$rand';
      _emailController.text = 'agent_$rand@sentinel.sec';
    });
  }

  Future<void> _handleRegister() async {
    setState(() => _loading = true);
    final clientId = _activeClientId;
    final res = await ApiService.register(
      _usernameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _roleController.text.trim(),
      clientId: clientId,
    );
    setState(() {
      _loading = false;
      _jwtOutput = const JsonEncoder.withIndent('  ').convert(res);
    });

    if (res['success'] == true) {
      final assignedClientId = res['user']?['clientId']?.toString() ?? clientId;
      setState(() {
        _clientIdController.text = assignedClientId;
        _showOtpVerification = true;
        _pendingVerificationEmail = _emailController.text.trim();
        _pendingVerificationClientId = assignedClientId;
      });
      _startOtpTimer();
      _startResendCooldown();
      _clearOtp();
    }

    widget.onStateChange();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['success'] == true
              ? '📧 OTP sent! A unique Client ID has been generated for your app.'
              : '${res['message'] ?? res['error']}'),
          backgroundColor: res['success'] == true ? CyberTheme.emeraldNeon : CyberTheme.crimsonNeon,
        ),
      );
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpValue;
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit OTP code.'),
          backgroundColor: CyberTheme.amberNeon,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    final res = await ApiService.verifyEmail(
      _pendingVerificationEmail,
      otp,
      clientId: _pendingVerificationClientId,
    );
    setState(() {
      _loading = false;
      _jwtOutput = const JsonEncoder.withIndent('  ').convert(res);
      if (ApiService.accessToken != null) {
        _decodeJwt(ApiService.accessToken);
      }
    });

    if (res['success'] == true) {
      if (res['user']?['clientId'] != null) {
        setState(() {
          _clientIdController.text = res['user']['clientId'].toString();
        });
      }
      setState(() => _showSuccess = true);
      _successController.forward();
      _otpTimer?.cancel();

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showOtpVerification = false;
            _showSuccess = false;
          });
          _successController.reset();
        }
      });
    }

    widget.onStateChange();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['success'] == true
              ? '✅ Email verified! Welcome email with your Client ID sent to ${_pendingVerificationEmail}.'
              : '${res['message']}'),
          backgroundColor: res['success'] == true ? CyberTheme.emeraldNeon : CyberTheme.crimsonNeon,
        ),
      );
    }
  }

  Future<void> _handleResendOtp() async {
    setState(() => _loading = true);
    final res = await ApiService.resendOtp(
      _pendingVerificationEmail,
      clientId: _pendingVerificationClientId,
    );
    setState(() => _loading = false);

    if (res['success'] == true) {
      _startOtpTimer();
      _startResendCooldown();
      _clearOtp();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['success'] == true
              ? '📧 New OTP sent! Check your email.'
              : '${res['message']}'),
          backgroundColor: res['success'] == true ? CyberTheme.secondaryNeon : CyberTheme.crimsonNeon,
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
    setState(() => _loading = true);
    final clientId = _activeClientId;
    final res = await ApiService.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
      clientId: clientId,
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
          content: Text(res['success'] == true
              ? 'Login successful for realm "$clientId"! Access & Refresh tokens generated.'
              : 'Login failed: ${res['message']}'),
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

  Widget _buildOtpVerificationOverlay() {
    return AnimatedOpacity(
      opacity: _showOtpVerification ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        color: CyberTheme.background.withOpacity(0.92),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 410,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CyberTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _showSuccess
                      ? CyberTheme.emeraldNeon.withOpacity(0.6)
                      : CyberTheme.primaryNeon.withOpacity(0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_showSuccess ? CyberTheme.emeraldNeon : CyberTheme.primaryNeon)
                        .withOpacity(0.12),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: _showSuccess ? _buildSuccessContent() : _buildOtpInputContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessContent() {
    return AnimatedBuilder(
      animation: _successAnimation,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: _successAnimation.value,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CyberTheme.emeraldNeon.withOpacity(0.15),
                    border: Border.all(color: CyberTheme.emeraldNeon, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: CyberTheme.emeraldNeon.withOpacity(0.3),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, color: CyberTheme.emeraldNeon, size: 34),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'EMAIL VERIFIED',
                style: GoogleFonts.outfit(
                  color: CyberTheme.emeraldNeon,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Scoped Access Token generated for realm "$_pendingVerificationClientId"',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: CyberTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOtpInputContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Icon & Title
          AnimatedBuilder(
            animation: _otpPulseAnimation,
            builder: (context, child) {
              return Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CyberTheme.primaryNeon.withOpacity(0.1 * _otpPulseAnimation.value),
                  border: Border.all(
                    color: CyberTheme.primaryNeon.withOpacity(0.5 * _otpPulseAnimation.value),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.mark_email_read_rounded,
                  color: CyberTheme.primaryNeon.withOpacity(_otpPulseAnimation.value),
                  size: 24,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            'VERIFY YOUR EMAIL',
            style: GoogleFonts.outfit(
              color: CyberTheme.textMain,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hub_rounded, size: 12, color: CyberTheme.secondaryNeon),
              const SizedBox(width: 4),
              Text(
                'Realm: ',
                style: GoogleFonts.outfit(color: CyberTheme.textMuted, fontSize: 11),
              ),
              Text(
                _pendingVerificationClientId,
                style: GoogleFonts.firaCode(color: CyberTheme.secondaryNeon, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _pendingVerificationEmail,
            style: GoogleFonts.firaCode(
              color: CyberTheme.primaryNeon,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // OTP Input Boxes (Compact)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              return Container(
                width: 46,
                height: 52,
                margin: EdgeInsets.only(
                  right: index < 5 ? (index == 2 ? 10 : 5) : 0,
                ),
                child: TextField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: GoogleFonts.firaCode(
                    color: CyberTheme.primaryNeon,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: CyberTheme.surfaceInput,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: _otpControllers[index].text.isNotEmpty
                            ? CyberTheme.primaryNeon.withOpacity(0.6)
                            : CyberTheme.borderSubtle,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: _otpControllers[index].text.isNotEmpty
                            ? CyberTheme.primaryNeon.withOpacity(0.4)
                            : CyberTheme.borderSubtle,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: CyberTheme.primaryNeon, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                    if (value.isNotEmpty && index < 5) {
                      _otpFocusNodes[index + 1].requestFocus();
                    }
                    if (_otpValue.length == 6) {
                      _handleVerifyOtp();
                    }
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 14),

          // Timer (Compact)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _otpSecondsRemaining <= 60
                  ? CyberTheme.crimsonNeon.withOpacity(0.1)
                  : CyberTheme.surfaceInput,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _otpSecondsRemaining <= 60
                    ? CyberTheme.crimsonNeon.withOpacity(0.3)
                    : CyberTheme.borderSubtle,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _otpSecondsRemaining > 0 ? Icons.timer_outlined : Icons.timer_off_outlined,
                  color: _otpSecondsRemaining <= 60 ? CyberTheme.crimsonNeon : CyberTheme.textMuted,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  _otpSecondsRemaining > 0
                      ? 'Expires in ${_formatTime(_otpSecondsRemaining)}'
                      : 'Expired — request new code',
                  style: GoogleFonts.firaCode(
                    color: _otpSecondsRemaining <= 60 ? CyberTheme.crimsonNeon : CyberTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: CyberTheme.primaryNeon,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.verified_rounded, size: 16),
              label: Text(
                _loading ? 'VERIFYING...' : 'VERIFY OTP',
                style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12),
              ),
              onPressed: _loading ? null : _handleVerifyOtp,
            ),
          ),
          const SizedBox(height: 8),

          // Resend & Cancel row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                icon: Icon(
                  Icons.refresh_rounded,
                  size: 14,
                  color: _canResendOtp ? CyberTheme.secondaryNeon : CyberTheme.textSubtle,
                ),
                label: Text(
                  _canResendOtp ? 'Resend OTP' : 'Resend in ${_resendCooldown}s',
                  style: GoogleFonts.outfit(
                    color: _canResendOtp ? CyberTheme.secondaryNeon : CyberTheme.textSubtle,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: _canResendOtp && !_loading ? _handleResendOtp : null,
              ),
              TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                icon: const Icon(Icons.close_rounded, size: 14, color: CyberTheme.textSubtle),
                label: Text(
                  'Cancel',
                  style: GoogleFonts.outfit(
                    color: CyberTheme.textSubtle,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _showOtpVerification = false;
                    _otpTimer?.cancel();
                    _resendTimer?.cancel();
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Compact security badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: CyberTheme.surfaceInput,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: CyberTheme.borderSubtle),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: CyberTheme.emeraldNeon, size: 13),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'SHA-256 hashed token • Max 5 attempts • Rate-limited',
                    style: GoogleFonts.outfit(color: CyberTheme.textSubtle, fontSize: 10.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Realm Selector + Credentials & Auth Actions
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        // Auth Credentials Card
                        CyberCard(
                          title: 'Identity & Authentication Hub',
                          subtitle: 'Argon2id v13 Password Hashing & Multi-Tenant IAM Architecture',
                          icon: Icons.vpn_key_rounded,
                          accentColor: CyberTheme.primaryNeon,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: TextField(
                                      controller: _usernameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Username',
                                        prefixIcon: Icon(Icons.person_outline, color: CyberTheme.primaryNeon),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller: _roleController,
                                      decoration: const InputDecoration(
                                        labelText: 'Role (Admin / User)',
                                        prefixIcon: Icon(Icons.verified_user_outlined, color: CyberTheme.secondaryNeon),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 4,
                                    child: TextField(
                                      controller: _clientIdController,
                                      decoration: const InputDecoration(
                                        labelText: 'Client / App ID',
                                        hintText: 'e.g. sentinel-core',
                                        prefixIcon: Icon(Icons.apps_rounded, color: CyberTheme.amberNeon),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email Address (OTP verification required)',
                                  prefixIcon: Icon(Icons.alternate_email, color: CyberTheme.primaryNeon),
                                  suffixIcon: Tooltip(
                                    message: 'A 6-digit OTP will be sent to this email for verification',
                                    child: Icon(Icons.info_outline_rounded, color: CyberTheme.textSubtle, size: 18),
                                  ),
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
                                      label: const Text('REGISTER USER',
                                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
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
                                      label: const Text('LOGIN (GET JWT)',
                                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
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
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: CyberTheme.surfaceInput,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: CyberTheme.amberNeon.withOpacity(0.35)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.code_rounded, color: CyberTheme.amberNeon, size: 15),
                                            const SizedBox(width: 6),
                                            Text(
                                              'YOUR UNIQUE APP CLIENT ID',
                                              style: GoogleFonts.outfit(
                                                color: CyberTheme.amberNeon,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                        InkWell(
                                          onTap: () {
                                            Clipboard.setData(ClipboardData(text: 'X-Client-Id: $_activeClientId'));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Copied "X-Client-Id: $_activeClientId" to clipboard!'),
                                                backgroundColor: CyberTheme.emeraldNeon,
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: CyberTheme.amberNeon.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: CyberTheme.amberNeon.withOpacity(0.4)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.copy_rounded, color: CyberTheme.amberNeon, size: 12),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'COPY HEADER',
                                                  style: GoogleFonts.outfit(
                                                    color: CyberTheme.amberNeon,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF060913),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: CyberTheme.borderSubtle),
                                      ),
                                      child: Text(
                                        'X-Client-Id: $_activeClientId',
                                        style: GoogleFonts.firaCode(
                                          color: CyberTheme.primaryNeon,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Pass this header in HTTP calls from your external app to route auth to this isolated tenant.',
                                      style: GoogleFonts.outfit(color: CyberTheme.textSubtle, fontSize: 11),
                                    ),
                                  ],
                                ),
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
                              ? CyberBadge(
                                  label: 'REALM: ${ApiService.currentClientId ?? _activeClientId}',
                                  color: CyberTheme.emeraldNeon,
                                  hasGlow: true,
                                )
                              : const CyberBadge(label: 'NO TOKEN', color: CyberTheme.amberNeon),
                          child: Column(
                            children: [
                              CyberCodeBox(
                                title: 'DECODED TOKEN CLAIMS (PAYLOAD)',
                                content: _decodedClaimsOutput,
                                accentColor: CyberTheme.primaryNeon,
                                maxHeight: 200,
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
        ),

        // OTP Verification Overlay
        if (_showOtpVerification) _buildOtpVerificationOverlay(),
      ],
    );
  }
}
