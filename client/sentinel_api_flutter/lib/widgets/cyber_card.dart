import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/cyber_theme.dart';

class CyberCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color accentColor;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const CyberCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.accentColor = CyberTheme.primaryNeon,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CyberTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.04),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          const BoxShadow(
            color: Colors.black45,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: CyberTheme.surfaceElevated.withOpacity(0.6),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              border: Border(
                bottom: BorderSide(color: accentColor.withOpacity(0.2), width: 1),
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accentColor.withOpacity(0.4)),
                    ),
                    child: Icon(icon, color: accentColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: CyberTheme.textMain,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            color: CyberTheme.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          // Content
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      ),
    );
  }
}
