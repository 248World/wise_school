import 'package:flutter/material.dart';

class AppColors {
  // Main brand colors
  static const Color primaryBlue = Color(0xFF0D8BFF);
  static const Color darkBlue = Color(0xFF005BCB);
  static const Color deepBlue = Color(0xFF0047A8);
  static const Color lightBlue = Color(0xFFEAF5FF);
  static const Color softBlue = Color(0xFFDFF1FF);

  // Backgrounds
  static const Color background = Color(0xFFF6FAFF);
  static const Color authBackground = Color(0xFF087EFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color inputBackground = Color(0xFFF9FBFF);

  // White / black
  static const Color white = Colors.white;
  static const Color black = Color(0xFF111827);

  // Text colors
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color textOnBlue = Color(0xFFFFFFFF);

  // Borders / shadows
  static const Color border = Color(0xFFE5E7EB);
  static const Color softBorder = Color(0xFFEFF4FA);
  static const Color shadow = Color(0x1A000000);

  // Status colors
  static const Color softGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFFEAF7EA);
  static const Color danger = Color(0xFFE53935);
  static const Color lightDanger = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFFF9800);
  static const Color lightWarning = Color(0xFFFFF4E5);

  // UI decorative colors
  static const Color bubbleBlue = Color(0xFF1D9BFF);
  static const Color bubbleBlueLight = Color(0xFF35A8FF);
  static const Color waveWhite = Color(0xFFFFFFFF);

  // Gradients
  static const LinearGradient authGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0678F9),
      Color(0xFF0D8BFF),
    ],
  );

  static const LinearGradient cardBlueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0D8BFF),
      Color(0xFF006FE6),
    ],
  );
}