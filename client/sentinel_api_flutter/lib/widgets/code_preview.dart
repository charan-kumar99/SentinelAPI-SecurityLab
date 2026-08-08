import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/cyber_theme.dart';

class CyberCodeBox extends StatefulWidget {
  final String title;
  final String content;
  final Color accentColor;
  final double maxHeight;
  final bool showCopy;

  const CyberCodeBox({
    super.key,
    required this.title,
    required this.content,
    this.accentColor = CyberTheme.primaryNeon,
    this.maxHeight = 220,
    this.showCopy = true,
  });

  @override
  State<CyberCodeBox> createState() => _CyberCodeBoxState();
}

class _CyberCodeBoxState extends State<CyberCodeBox> {
  bool _copied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.content));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF030712),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            border: Border.all(color: widget.accentColor.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: widget.accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.accentColor.withOpacity(0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.title.toUpperCase(),
                    style: GoogleFonts.firaCode(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: CyberTheme.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              if (widget.showCopy)
                InkWell(
                  onTap: _copy,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _copied
                          ? CyberTheme.emeraldNeon.withOpacity(0.2)
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _copied
                            ? CyberTheme.emeraldNeon
                            : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _copied ? Icons.check_rounded : Icons.copy_rounded,
                          size: 12,
                          color: _copied
                              ? CyberTheme.emeraldNeon
                              : CyberTheme.textMuted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _copied ? 'Copied!' : 'Copy',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: _copied
                                ? CyberTheme.emeraldNeon
                                : CyberTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Code Content Body
        Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: widget.maxHeight),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF02040A),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
            border: Border(
              left: BorderSide(color: widget.accentColor.withOpacity(0.2)),
              right: BorderSide(color: widget.accentColor.withOpacity(0.2)),
              bottom: BorderSide(color: widget.accentColor.withOpacity(0.2)),
            ),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              widget.content,
              style: GoogleFonts.firaCode(
                fontSize: 12.5,
                color: widget.accentColor == CyberTheme.crimsonNeon
                    ? const Color(0xFFFCA5A5)
                    : const Color(0xFF38BDF8),
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
