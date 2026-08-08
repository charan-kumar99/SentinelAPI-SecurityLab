import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CyberTheme {
  // Brand Palettes - Obsidian & High-Tech Cyber Neons
  static const Color background = Color(0xFF060913);
  static const Color surface = Color(0xFF0B1222);
  static const Color surfaceElevated = Color(0xFF111C33);
  static const Color surfaceCard = Color(0xFF0F1A30);
  static const Color surfaceInput = Color(0xFF070C1A);
  
  static const Color primaryNeon = Color(0xFF00F0FF); // Cyber Cyan
  static const Color primaryGlow = Color(0xFF00B4D8);
  static const Color secondaryNeon = Color(0xFFA855F7); // Cyber Violet / Purple
  static const Color emeraldNeon = Color(0xFF10B981); // Defense Safe Green
  static const Color amberNeon = Color(0xFFF59E0B); // Warning Amber
  static const Color crimsonNeon = Color(0xFFEF4444); // Critical Attack Red
  static const Color blueNeon = Color(0xFF3B82F6); // Electric Blue
  
  static const Color textMain = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textSubtle = Color(0xFF64748B);
  static const Color borderSubtle = Color(0xFF1E293B);
  static const Color borderGlow = Color(0xFF00F0FF);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primaryNeon,
      colorScheme: const ColorScheme.dark(
        primary: primaryNeon,
        secondary: secondaryNeon,
        surface: surface,
        error: crimsonNeon,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: textMain,
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF1E293B),
        thickness: 1,
        space: 24,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(color: textMain, fontWeight: FontWeight.w800, fontSize: 32, letterSpacing: -0.5),
        displayMedium: GoogleFonts.outfit(color: textMain, fontWeight: FontWeight.w700, fontSize: 26),
        titleLarge: GoogleFonts.outfit(color: textMain, fontWeight: FontWeight.w700, fontSize: 18),
        titleMedium: GoogleFonts.outfit(color: textMain, fontWeight: FontWeight.w600, fontSize: 15),
        bodyLarge: GoogleFonts.outfit(color: textMain, fontSize: 14),
        bodyMedium: GoogleFonts.outfit(color: textMuted, fontSize: 13),
        labelLarge: GoogleFonts.outfit(color: textMain, fontWeight: FontWeight.w600, fontSize: 13),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceInput,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.outfit(color: textSubtle, fontSize: 13),
        labelStyle: GoogleFonts.outfit(color: textMuted, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderSubtle, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryNeon, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: crimsonNeon, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNeon,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textMain,
          side: const BorderSide(color: borderSubtle, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      useMaterial3: true,
    );
  }

  static TextStyle codeFont({
    double fontSize = 12.5,
    FontWeight fontWeight = FontWeight.w500,
    Color color = primaryNeon,
  }) {
    return GoogleFonts.firaCode(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}
