import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DesignSystem {
  // Glassmorphic Light Mode Palette (HSL / Slate curated)
  static const Color background = Color(0xFFF1F5F9); // Light Slate 100
  static const Color cardBackground = Color(0x99FFFFFF); // 60% opacity white for glass effect
  static const Color primaryAccent = Color(0xFF0284C7); // Sky 600 - rich, readable blue
  static const Color secondaryAccent = Color(0xFF7C3AED); // Violet 600 - rich violet
  static const Color glassWhite = Color(0x66FFFFFF); // 40% white for fields and small elements
  static const Color textMain = Color(0xFF0F172A); // Slate 900 - very dark for high readability
  static const Color textSub = Color(0xFF475569); // Slate 600 - readable subtext

  static final LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0EA5E9), // Sky 500
      Color(0xFF2563EB), // Blue 600
      Color(0xFF7C3AED), // Violet 600
    ],
  );

  static final LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withOpacity(0.65),
      Colors.white.withOpacity(0.35),
    ],
  );

  static BoxShadow neonShadow(Color color) => BoxShadow(
    color: color.withOpacity(0.25),
    blurRadius: 18,
    spreadRadius: -3,
    offset: const Offset(0, 10),
  );

  static final BoxShadow softShadow = BoxShadow(
    color: Colors.black.withOpacity(0.04),
    blurRadius: 16,
    spreadRadius: 0,
    offset: const Offset(0, 8),
  );

  // Helper to build consistent glass decoration
  static BoxDecoration glassDecoration({
    double borderRadius = 24.0,
    Color? color,
    Border? border,
  }) {
    return BoxDecoration(
      color: color ?? cardBackground,
      borderRadius: BorderRadius.circular(borderRadius),
      border: border ?? Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
      boxShadow: [softShadow],
    );
  }

  // Modern Typography
  static TextStyle get h1 => GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: textMain,
    letterSpacing: -0.5,
  );

  static TextStyle get h2 => GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textMain,
  );

  static TextStyle get bodyBold => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: textMain,
  );

  static TextStyle get bodyMain => GoogleFonts.inter(
    fontSize: 14,
    color: textSub,
  );

  static TextStyle get buttonText => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white, // Always white on a dark gradient background
    letterSpacing: 1.0,
  );
}
