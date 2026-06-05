import 'package:flutter/material.dart';

/// Central color palette for MeetWise.
///
/// Use [ColorScheme] from [AppTheme] for Material component colors.
/// Use [AppColors] for semantic values (confidence scores, agent badges, etc.)
/// that sit outside the Material role system.
abstract class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  /// Primary brand blue — used as the M3 seed color.
  static const Color brand = Color(0xFF2563EB);
  static const Color brandDark = Color(0xFF1D4ED8);
  static const Color brandMid = Color(0xFF3B82F6);
  static const Color brandLight = Color(0xFFEFF6FF);
  static const Color brandSubtle = Color(0xFFDBEAFE);

  // ── AI Accent (Indigo) ─────────────────────────────────────────────────────
  /// Indigo accent — used for AI/Gemini badges and accent elements.
  static const Color accent = Color(0xFF6366F1);
  static const Color accentDark = Color(0xFF4F46E5);
  static const Color accentLight = Color(0xFFEEF2FF);
  static const Color accentSubtle = Color(0xFFE0E7FF);

  // ── Semantic: Confidence / Status ──────────────────────────────────────────
  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFFECFDF5);
  static const Color successSubtle = Color(0xFFD1FAE5);

  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color warningSubtle = Color(0xFFFDE68A);

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEF2F2);
  static const Color dangerSubtle = Color(0xFFFECACA);

  // ── Surfaces ───────────────────────────────────────────────────────────────
  static const Color surface = Color(0xFFFFFFFF);
  /// Page/scaffold background — very faint blue-gray.
  static const Color surfacePage = Color(0xFFF8FAFC);
  /// Slightly elevated cards on colored backgrounds.
  static const Color surfaceCard = Color(0xFFFFFFFF);
  /// Code blocks / JSON viewer backgrounds.
  static const Color surfaceCode = Color(0xFFF1F5F9);

  // ── Borders / Dividers ─────────────────────────────────────────────────────
  static const Color outline = Color(0xFFE2E8F0);
  static const Color outlineStrong = Color(0xFFCBD5E1);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnBrand = Color(0xFFFFFFFF);
  static const Color textLink = Color(0xFF2563EB);

  // ── Agent Type Colors ──────────────────────────────────────────────────────
  /// Gemini AI agent badge.
  static const Color gemini = Color(0xFF2563EB);
  static const Color geminiSurface = Color(0xFFDBEAFE);

  /// Rule-based agent badge.
  static const Color ruleBased = Color(0xFF7C3AED);
  static const Color ruleBasedSurface = Color(0xFFEDE9FE);

  // ── Gradients ──────────────────────────────────────────────────────────────
  /// Hero gradient for banners / loading screens.
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF1D4ED8), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFFEFF6FF), Color(0xFFEEF2FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Semantic helpers ───────────────────────────────────────────────────────

  /// Foreground color for a confidence score (text / icon).
  static Color forConfidence(double score) =>
      score >= 0.8 ? success : score >= 0.5 ? warning : danger;

  /// Background tint for a confidence score badge.
  static Color forConfidenceSurface(double score) =>
      score >= 0.8 ? successLight : score >= 0.5 ? warningLight : dangerLight;

  /// Subtle border/progress color for a confidence score.
  static Color forConfidenceSubtle(double score) =>
      score >= 0.8 ? successSubtle : score >= 0.5 ? warningSubtle : dangerSubtle;
}
