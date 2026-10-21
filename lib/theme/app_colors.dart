import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette - Deep Royal Indigo
  static const Color primary = Color(0xFF4338CA); // Indigo 700
  static const Color primaryLight = Color(0xFFEEF2FF);
  static const Color primaryDark = Color(0xFF312E81);
  
  // Secondary / Accent - Vibrant Sky & Cyan
  static const Color secondary = Color(0xFF0284C7); // Sky 600
  static const Color secondaryLight = Color(0xFFE0F2FE);
  
  // Semantic colors
  static const Color success = Color(0xFF059669); // Emerald 600
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFD97706); // Amber 600
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626); // Red 600
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF4F46E5);
  
  // Neutrals & Surfaces - Slate scale
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF1F5F9); // Slate 100
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderLight = Color(0xFFF1F5F9);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  
  // Card & Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3730A3), Color(0xFF4338CA), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF047857), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFB45309), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Soft Shadows for Production Look
  static const List<BoxShadow> softCardShadow = [
    BoxShadow(
      color: Color(0x080F172A),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x040F172A),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];
}
