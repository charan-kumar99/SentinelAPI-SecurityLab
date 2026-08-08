import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/cyber_theme.dart';

class CyberBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool isPill;
  final bool hasGlow;

  const CyberBadge({
    super.key,
    required this.label,
    this.color = CyberTheme.primaryNeon,
    this.icon,
    this.isPill = true,
    this.hasGlow = false,
  });

  factory CyberBadge.risk(dynamic riskLevel) {
    Color c = CyberTheme.emeraldNeon;
    String text = 'Low';
    if (riskLevel == 'Critical' || riskLevel == 3 || riskLevel == 4) {
      c = CyberTheme.crimsonNeon;
      text = 'Critical Risk';
    } else if (riskLevel == 'High' || riskLevel == 2) {
      c = CyberTheme.amberNeon;
      text = 'High Risk';
    } else if (riskLevel == 'Medium' || riskLevel == 1) {
      c = CyberTheme.blueNeon;
      text = 'Medium Risk';
    } else {
      text = 'Low Risk';
    }
    return CyberBadge(
      label: text,
      color: c,
      icon: Icons.shield_outlined,
      hasGlow: true,
    );
  }

  factory CyberBadge.status(int statusCode) {
    Color c = CyberTheme.emeraldNeon;
    IconData ic = Icons.check_circle_outline;
    if (statusCode == 429) {
      c = CyberTheme.amberNeon;
      ic = Icons.speed;
    } else if (statusCode >= 400) {
      c = CyberTheme.crimsonNeon;
      ic = Icons.error_outline;
    }
    return CyberBadge(
      label: '$statusCode ${statusCode == 200 ? "OK" : statusCode == 429 ? "THROTTLED" : "DENIED"}',
      color: c,
      icon: ic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(isPill ? 20 : 6),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
        boxShadow: hasGlow
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 0.5,
                )
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class CyberMetricTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final String? badge;

  const CyberMetricTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CyberTheme.surfaceElevated.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: color,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge!,
                          style: TextStyle(fontSize: 9.5, color: color, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    color: CyberTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
