import 'package:flutter/material.dart';

/// Centralised colour palette for MeetWise — AI tech aesthetic.
/// All widget colours must come from here. Never hardcode hex values elsewhere.
abstract class AppColors {
  // ── Primary brand: electric blue ──────────────────────────────────────────
  static const Color brand      = Color(0xFF3B82F6); // blue-500  (primary CTA)
  static const Color brandDark  = Color(0xFF2563EB); // blue-600  (pressed)
  static const Color brandMid   = Color(0xFF60A5FA); // blue-400  (hover)
  static const Color brandLight = Color(0xFFEFF6FF); // blue-50   (light surface)
  static const Color brandSubtle= Color(0xFFDBEAFE); // blue-100  (subtle bg)

  // ── AI secondary: violet / purple ─────────────────────────────────────────
  // "teal" name kept for backward compat — repurposed to violet for AI aesthetic
  static const Color teal        = Color(0xFF8B5CF6); // violet-500
  static const Color tealLight   = Color(0xFFA78BFA); // violet-400
  static const Color tealSurface = Color(0xFFF5F3FF); // violet-50
  static const Color tealSubtle  = Color(0xFFEDE9FE); // violet-100

  // ── AI badge: indigo (Gemini indicator) ────────────────────────────────────
  static const Color accent       = Color(0xFF6366F1); // indigo-500
  static const Color accentDark   = Color(0xFF4F46E5); // indigo-600
  static const Color accentLight  = Color(0xFFEEF2FF); // indigo-50
  static const Color accentSubtle = Color(0xFFE0E7FF); // indigo-100

  // ── Agent type colours ─────────────────────────────────────────────────────
  // Alpha-based: render correctly on both dark (navy) and light (white) surfaces
  static const Color gemini        = Color(0xFF6366F1);  // indigo-500
  static const Color geminiSurface = Color(0x336366F1);  // 20 % indigo alpha

  static const Color ruleBased        = Color(0xFF10B981); // emerald-500
  static const Color ruleBasedSurface = Color(0x3310B981); // 20 % emerald alpha

  // ── Status colours ─────────────────────────────────────────────────────────
  // Light surfaces (alpha-based) work on any background colour.
  static const Color success      = Color(0xFF10B981); // emerald-500
  static const Color successLight = Color(0x2210B981); // 13 %  (badge bg)
  static const Color successSubtle= Color(0x4010B981); // 25 %  (progress bg)

  static const Color warning      = Color(0xFFF59E0B); // amber-500
  static const Color warningLight = Color(0x22F59E0B); // 13 %  (badge bg)
  static const Color warningSubtle= Color(0x55F59E0B); // 33 %  (border)

  static const Color danger       = Color(0xFFEF4444); // red-500
  static const Color dangerLight  = Color(0x22EF4444); // 13 %  (badge bg)
  static const Color dangerSubtle = Color(0x44EF4444); // 27 %  (border)

  // ── Light surfaces ─────────────────────────────────────────────────────────
  static const Color surface      = Color(0xFFFFFFFF); // pure white (alias)
  static const Color surfacePage  = Color(0xFFF7F9FF); // blue-tinted scaffold
  static const Color surfaceCard  = Color(0xFFFFFFFF); // card bg
  static const Color surfaceCode  = Color(0xFFF1F5F9); // code block bg
  static const Color surfaceHover = Color(0xFFF0F6FF); // hover state

  // ── Dark surfaces: deep navy ───────────────────────────────────────────────
  static const Color surfaceDark         = Color(0xFF0A1020); // appBar bg dark
  static const Color surfacePageDark     = Color(0xFF060C1D); // scaffold dark
  static const Color surfaceCardDark     = Color(0xFF0C1828); // card bg dark
  static const Color surfaceCodeDark     = Color(0xFF0A1020); // code block dark
  static const Color surfaceElevatedDark = Color(0xFF111E35); // elevated dark

  // ── Borders ────────────────────────────────────────────────────────────────
  static const Color outline          = Color(0xFFE2E8F0); // light border
  static const Color outlineStrong    = Color(0xFFCBD5E1); // stronger light
  static const Color outlineDark      = Color(0xFF1A2E48); // dark border
  static const Color outlineDarkStrong= Color(0xFF243B5E); // stronger dark

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0F172A); // slate-900
  static const Color textSecondary = Color(0xFF475569); // slate-600
  static const Color textMuted     = Color(0xFF94A3B8); // slate-400
  static const Color textOnBrand   = Color(0xFFFFFFFF);
  static const Color textLink      = Color(0xFF3B82F6); // same as brand

  // ── Shadows / glow ─────────────────────────────────────────────────────────
  static Color get shadowXs    => const Color(0xFF0F172A).withValues(alpha: 0.04);
  static Color get shadowSm    => const Color(0xFF0F172A).withValues(alpha: 0.08);
  static Color get shadowMd    => const Color(0xFF0F172A).withValues(alpha: 0.14);
  static Color get shadowBrand => brand.withValues(alpha: 0.28);
  static Color get glowBrand   => brand.withValues(alpha: 0.42);   // hero button glow
  static Color get glowAccent  => teal.withValues(alpha: 0.35);    // violet glow

  // ── Gradients ──────────────────────────────────────────────────────────────

  /// Multi-stop deep navy hero (dashboard + demo loading overlay).
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF060C1D), // deep navy
      Color(0xFF0E1535), // navy-indigo
      Color(0xFF140F3A), // deep violet
      Color(0xFF0A1628), // navy-blue
    ],
    stops: [0.0, 0.33, 0.66, 1.0],
  );

  /// Electric blue → violet — used for gradient CTA buttons and accents.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
  );

  /// Diagonal 3-stop — traces, badges, highlights.
  static const LinearGradient brandGradientDiag = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );

  /// Light blue-violet tint — brand surface on light bg.
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEFF6FF), Color(0xFFF5F3FF)],
  );

  /// Dark navy — brand surface on dark bg.
  static const LinearGradient darkSurfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0E1A30), Color(0xFF12152E)],
  );

  // ── Confidence / status helpers ────────────────────────────────────────────

  static Color forConfidence(double score) =>
      score >= 0.8 ? success : score >= 0.5 ? warning : danger;

  /// Alpha-based — works on both dark and light backgrounds.
  static Color forConfidenceSurface(double score) =>
      forConfidence(score).withValues(alpha: 0.18);

  static Color forConfidenceSubtle(double score) =>
      forConfidence(score).withValues(alpha: 0.30);

  // ── Context-aware helpers ──────────────────────────────────────────────────

  static Color surface_(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark ? surfaceCardDark : surface;

  static Color outline_(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark ? outlineDark : outline;

  static Color textPrimary_(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark ? Colors.white : textPrimary;

  static Color textSecondary_(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF94A3B8)
          : textSecondary;
}
