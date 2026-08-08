import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/cyber_theme.dart';

class CyberFooter extends StatelessWidget {
  const CyberFooter({super.key});

  Future<void> _openPortfolio() async {
    final uri = Uri.parse('https://charan-kumar99.github.io/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: CyberTheme.surfaceElevated.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CyberTheme.borderSubtle, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row: Project info, Standards & Live Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Project Info & Shield
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CyberTheme.primaryNeon.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: CyberTheme.primaryNeon.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.security_rounded, color: CyberTheme.primaryNeon, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'SENTINEL API',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: CyberTheme.textMain,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'SECURITY LAB',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: CyberTheme.primaryNeon,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'DevSecOps Defensive Architecture & Threat Intelligence',
                        style: GoogleFonts.outfit(fontSize: 11.5, color: CyberTheme.textMuted),
                      ),
                    ],
                  ),
                ],
              ),

              // Middle: Standards & Compliance Badges
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildComplianceBadge('NIST SP 800-38D', 'AES-GCM', CyberTheme.secondaryNeon),
                  _buildComplianceBadge('RFC 9106', 'Argon2id', CyberTheme.primaryNeon),
                  _buildComplianceBadge('OWASP API Top 10', 'Mitigated', CyberTheme.emeraldNeon),
                  _buildComplianceBadge('Zero Trust', 'RBAC & Signed URLs', CyberTheme.amberNeon),
                ],
              ),

              // Right: System Engine Status
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: CyberTheme.emeraldNeon,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'DEFENSE GRID ACTIVE',
                    style: GoogleFonts.firaCode(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: CyberTheme.emeraldNeon,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Bottom Bar: Crafted by Charan Kumar with Custom CK Logo & Portfolio Link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Creator & Attribution with Custom CK Logo
              InkWell(
                onTap: _openPortfolio,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4FF).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Custom SVG CK Logo
                      const CkLogo(size: 24),
                      const SizedBox(width: 10),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.outfit(fontSize: 12, color: CyberTheme.textMain),
                          children: [
                            const TextSpan(text: 'Crafted with '),
                            const TextSpan(text: '❤️', style: TextStyle(fontSize: 12)),
                            const TextSpan(text: ' & Innovation by '),
                            TextSpan(
                              text: 'Charan Kumar',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF00FFAA),
                                letterSpacing: 0.3,
                              ),
                            ),
                            TextSpan(
                              text: ' (charan-kumar99.github.io)',
                              style: GoogleFonts.firaCode(
                                fontSize: 10.5,
                                color: const Color(0xFF00D4FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.open_in_new_rounded, size: 13, color: Color(0xFF00FFAA)),
                    ],
                  ),
                ),
              ),

              // Server Architecture details
              Text(
                'PostgreSQL 16 (:5433) • Redis 7 (:6380) • API v1 (:5265) • Flutter Web (:3000)',
                style: GoogleFonts.firaCode(fontSize: 10.5, color: CyberTheme.textSubtle),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildComplianceBadge(String standard, String detail, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            standard,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '• $detail',
            style: GoogleFonts.outfit(
              fontSize: 10.5,
              color: CyberTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Pixel-Perfect Vector Painter for Charan Kumar (CK) Monogram Logo
class CkLogo extends StatelessWidget {
  final double size;

  const CkLogo({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CkLogoPainter(),
      ),
    );
  }
}

class _CkLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 240.0;

    // Linear Gradient #00d4ff to #00ffaa
    final gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF00D4FF),
        Color(0xFF00FFAA),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final paint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22.0 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    canvas.scale(scale, scale);

    // 1. Path: M 129.96 81.43 A 60 60 0 1 0 129.96 158.57
    final cPath = Path();
    final center = const Offset(120, 120);
    const radius = 60.0;
    // Arc from angle -40 deg (81.43) counter-clockwise through 180 deg to +40 deg (158.57)
    // Angles in radians: start angle ~ -0.698 rad (-40 deg), sweep angle ~ -4.887 rad (-280 deg)
    const startAngle = -0.70;
    const sweepAngle = -4.88;
    cPath.addArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
    );
    canvas.drawPath(cPath, paint);

    // 2. Line 1: x1="156" y1="60" x2="156" y2="180"
    canvas.drawLine(const Offset(156, 60), const Offset(156, 180), paint);

    // 3. Line 2: x1="156" y1="120" x2="216" y2="60"
    canvas.drawLine(const Offset(156, 120), const Offset(216, 60), paint);

    // 4. Line 3: x1="156" y1="120" x2="216" y2="180"
    canvas.drawLine(const Offset(156, 120), const Offset(216, 180), paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
