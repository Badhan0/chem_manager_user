import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DesignSystem {
  // Futuristic Color Palette (HSL curated)
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color cardBackground = Color(0xFF1E293B); // Slate 800
  static const Color primaryAccent = Color(0xFF06B6D4); // Cyan 500
  static const Color secondaryAccent = Color(0xFF8B5CF6); // Violet 500
  static const Color glassWhite = Color(0x1AFFFFFF); 
  static const Color textMain = Colors.white;
  static const Color textSub = Color(0xFF94A3B8); // Slate 400

  static final LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF06B6D4), // Cyan
      Color(0xFF3B82F6), // Blue
      Color(0xFF8B5CF6), // Violet
    ],
  );

  static final LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withOpacity(0.15),
      Colors.white.withOpacity(0.05),
    ],
  );

  static BoxShadow neonShadow(Color color) => BoxShadow(
    color: color.withOpacity(0.5),
    blurRadius: 20,
    spreadRadius: -5,
    offset: const Offset(0, 10),
  );

  static final BoxShadow softShadow = BoxShadow(
    color: Colors.black.withOpacity(0.3),
    blurRadius: 15,
    offset: const Offset(0, 8),
  );

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
    color: textMain,
    letterSpacing: 1.0,
  );
}
