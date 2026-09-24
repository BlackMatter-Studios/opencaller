import 'package:flutter/material.dart';

/// Cyberpunk / Futuristic Glass Color Tokens
class GlassColors {
  // Backgrounds & Surface
  static const Color deepSpace = Color(0xFF090A0F);
  static const Color darkSurface = Color(0xFF11131B);
  static const Color elevatedSurface = Color(0xFF181B26);
  static const Color glassFill = Color(0x1AFFFFFF); // 10% white
  static const Color glassBorder = Color(0x33FFFFFF); // 20% white

  // Neon Brand Accents
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonCyanDim = Color(0x3300E5FF);
  static const Color neonPurple = Color(0xFF9333EA);
  static const Color neonPurpleLight = Color(0xFFA855F7);
  static const Color cyberBlue = Color(0xFF3B82F6);

  // Status & Telephony Semantics
  static const Color cleanVerified = Color(0xFF10B981); // Emerald Green
  static const Color cleanVerifiedGlass = Color(0x2610B981);
  static const Color warningSpam = Color(0xFFF59E0B); // Amber Warning
  static const Color warningSpamGlass = Color(0x26F59E0B);
  static const Color severeScam = Color(0xFFEF4444); // Crimson Neon
  static const Color severeScamGlass = Color(0x26EF4444);

  // Text Colors
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // Linear Gradients
  static const LinearGradient cyanPurpleGradient = LinearGradient(
    colors: [neonCyan, neonPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF161822), Color(0xFF0F1017)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient scamGlowGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFF7F1D1D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
