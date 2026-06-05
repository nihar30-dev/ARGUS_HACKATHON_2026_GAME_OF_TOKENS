import 'package:flutter/material.dart';

/// Spacing scale, border radii, and EdgeInsets presets.
///
/// Use these instead of raw numeric literals to keep layout consistent.
abstract class AppSpacing {
  // ── Base scale (4 pt grid) ─────────────────────────────────────────────────
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  // ── In-between sizes ───────────────────────────────────────────────────────
  static const double smMd = 12;
  static const double mdLg = 20;

  // ── Border radius ──────────────────────────────────────────────────────────
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusPill = 100; // fully rounded (chips, badges)

  static const BorderRadius roundedSm =
      BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius roundedMd =
      BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius roundedLg =
      BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius roundedXl =
      BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius roundedPill =
      BorderRadius.all(Radius.circular(radiusPill));

  // ── EdgeInsets presets ─────────────────────────────────────────────────────

  /// Full-page content padding.
  static const EdgeInsets pagePadding = EdgeInsets.all(lg);
  static const EdgeInsets pagePaddingH =
      EdgeInsets.symmetric(horizontal: lg, vertical: md);

  /// Standard card internal padding.
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets cardPaddingLg = EdgeInsets.all(lg);

  /// Comfortable button padding.
  static const EdgeInsets buttonPadding =
      EdgeInsets.symmetric(horizontal: xl, vertical: smMd);

  /// Compact button (icon buttons, secondary actions).
  static const EdgeInsets buttonPaddingCompact =
      EdgeInsets.symmetric(horizontal: md, vertical: sm);

  /// Chip / badge padding.
  static const EdgeInsets chipPadding =
      EdgeInsets.symmetric(horizontal: sm, vertical: xs);

  /// Input field content padding.
  static const EdgeInsets inputPadding =
      EdgeInsets.symmetric(horizontal: md, vertical: smMd);

  // ── SizedBox helpers ───────────────────────────────────────────────────────
  static const SizedBox gapXs = SizedBox(height: xs);
  static const SizedBox gapSm = SizedBox(height: sm);
  static const SizedBox gapMd = SizedBox(height: md);
  static const SizedBox gapLg = SizedBox(height: lg);
  static const SizedBox gapXl = SizedBox(height: xl);

  static const SizedBox hGapXs = SizedBox(width: xs);
  static const SizedBox hGapSm = SizedBox(width: sm);
  static const SizedBox hGapMd = SizedBox(width: md);
  static const SizedBox hGapLg = SizedBox(width: lg);

  // ── Elevation ──────────────────────────────────────────────────────────────
  static const double elevationNone = 0;
  static const double elevationLow = 1;
  static const double elevationMid = 3;
  static const double elevationHigh = 6;
}
