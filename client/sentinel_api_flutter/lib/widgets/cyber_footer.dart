import 'dart:ui_web' as ui;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/cyber_theme.dart';

class CyberFooter extends StatelessWidget {
  const CyberFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: CyberTheme.surfaceElevated.withOpacity(0.8),
        border: Border(
          top: BorderSide(
            color: CyberTheme.primaryNeon.withOpacity(0.15),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: CyberTheme.primaryNeon.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: CK Logo + Branding & Copyright
          Row(
            children: [
              // CK Logo — clickable to portfolio
              _CKLogoButton(),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'SENTINEL API',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: CyberTheme.textMain,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'SECURITY LAB',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: CyberTheme.primaryNeon,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '© 2026 DevSecOps Engineering — Enterprise Defensive Platform',
                    style: GoogleFonts.outfit(
                      fontSize: 10.5,
                      color: CyberTheme.textSubtle,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Center: Technology Stack Badges
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TechBadge(
                    label: 'ASP.NET 10',
                    icon: Icons.dns_rounded,
                    color: CyberTheme.secondaryNeon,
                  ),
                  const SizedBox(width: 8),
                  _TechBadge(
                    label: 'Flutter',
                    icon: Icons.flutter_dash,
                    color: CyberTheme.primaryNeon,
                  ),
                  const SizedBox(width: 8),
                  _TechBadge(
                    label: 'PostgreSQL',
                    icon: Icons.storage_rounded,
                    color: CyberTheme.blueNeon,
                  ),
                  const SizedBox(width: 8),
                  _TechBadge(
                    label: 'Redis',
                    icon: Icons.speed_rounded,
                    color: CyberTheme.crimsonNeon,
                  ),
                  const SizedBox(width: 8),
                  _TechBadge(
                    label: 'Docker',
                    icon: Icons.sailing_rounded,
                    color: CyberTheme.emeraldNeon,
                  ),
                ],
              ),
            ),
          ),

          // Right: Security Status Indicator
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: CyberTheme.emeraldNeon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: CyberTheme.emeraldNeon.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: CyberTheme.emeraldNeon,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: CyberTheme.emeraldNeon.withOpacity(0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'All Systems Operational',
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: CyberTheme.emeraldNeon,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'v1.0.0',
                style: GoogleFonts.firaCode(
                  fontSize: 10,
                  color: CyberTheme.textSubtle,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// CK Logo Button — opens portfolio on click (uses exact SVG)
// ──────────────────────────────────────────────
class _CKLogoButton extends StatefulWidget {
  @override
  State<_CKLogoButton> createState() => _CKLogoButtonState();
}

class _CKLogoButtonState extends State<_CKLogoButton> {
  bool _hovered = false;
  static bool _registered = false;

  @override
  void initState() {
    super.initState();
    if (!_registered) {
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory('ck-logo-svg', (int viewId) {
        final div = html.DivElement()
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.display = 'flex'
          ..style.alignItems = 'center'
          ..style.justifyContent = 'center';

        // Use NodeTreeSanitizer.trusted to allow SVG elements
        div.setInnerHtml(
          '<svg viewBox="0 0 240 240" xmlns="http://www.w3.org/2000/svg" width="22" height="22">'
          '<defs>'
          '<linearGradient id="logoCkGrad_$viewId" x1="0%" y1="0%" x2="100%" y2="100%">'
          '<stop offset="0%" stop-color="#00d4ff"/>'
          '<stop offset="100%" stop-color="#00ffaa"/>'
          '</linearGradient>'
          '</defs>'
          '<g fill="none" stroke="url(#logoCkGrad_$viewId)" stroke-width="22" stroke-linecap="round" stroke-linejoin="round">'
          '<path d="M 129.96 81.43 A 60 60 0 1 0 129.96 158.57"/>'
          '<line x1="156" y1="60" x2="156" y2="180"/>'
          '<line x1="156" y1="120" x2="216" y2="60"/>'
          '<line x1="156" y1="120" x2="216" y2="180"/>'
          '</g>'
          '</svg>',
          treeSanitizer: html.NodeTreeSanitizer.trusted,
        );

        return div;
      });
      _registered = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          html.window.open('https://charan-kumar99.github.io/', '_blank');
        },
        child: Tooltip(
          message: 'Visit Portfolio — charan-kumar99.github.io',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: _hovered
                  ? CyberTheme.primaryNeon.withOpacity(0.18)
                  : CyberTheme.primaryNeon.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hovered
                    ? CyberTheme.primaryNeon.withOpacity(0.7)
                    : CyberTheme.primaryNeon.withOpacity(0.25),
                width: 1.2,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: CyberTheme.primaryNeon.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: const HtmlElementView(viewType: 'ck-logo-svg'),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Tech Stack Badge Widget
// ──────────────────────────────────────────────
class _TechBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _TechBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
