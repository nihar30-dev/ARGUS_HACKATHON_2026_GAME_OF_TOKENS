import 'package:flutter/material.dart';

/// Spacing scale, border radii, and EdgeInsets presets — 4 pt grid.
abstract class AppSpacing {
  // ── Base scale ─────────────────────────────────────────────────────────────
  static const double xxs  = 2;
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 16;
  static const double lg   = 24;
  static const double xl   = 32;
  static const double xxl  = 48;
  static const double xxxl = 64;

  // ── In-between sizes ───────────────────────────────────────────────────────
  static const double smMd = 12;
  static const double mdLg = 20;

  // ── Border radius ──────────────────────────────────────────────────────────
  static const double radiusXs   = 4;
  static const double radiusSm   = 8;
  static const double radiusMd   = 12;
  static const double radiusLg   = 16;
  static const double radiusXl   = 20;
  static const double radiusXxl  = 24;
  static const double radiusPill = 100;

  static const BorderRadius roundedSm   = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius roundedMd   = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius roundedLg   = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius roundedXl   = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius roundedXxl  = BorderRadius.all(Radius.circular(radiusXxl));
  static const BorderRadius roundedPill = BorderRadius.all(Radius.circular(radiusPill));

  // ── EdgeInsets presets ─────────────────────────────────────────────────────
  static const EdgeInsets pagePadding   = EdgeInsets.all(lg);
  static const EdgeInsets pagePaddingH  = EdgeInsets.symmetric(horizontal: lg, vertical: md);

  static const EdgeInsets cardPadding   = EdgeInsets.all(md);
  static const EdgeInsets cardPaddingLg = EdgeInsets.all(lg);

  static const EdgeInsets buttonPadding        = EdgeInsets.symmetric(horizontal: xl,  vertical: smMd);
  static const EdgeInsets buttonPaddingCompact = EdgeInsets.symmetric(horizontal: md,  vertical: sm);
  static const EdgeInsets buttonPaddingSm      = EdgeInsets.symmetric(horizontal: smMd, vertical: xs);

  static const EdgeInsets chipPadding  = EdgeInsets.symmetric(horizontal: sm,  vertical: xs);
  static const EdgeInsets badgePadding = EdgeInsets.symmetric(horizontal: smMd, vertical: xxs + 1);

  static const EdgeInsets inputPadding = EdgeInsets.symmetric(horizontal: md, vertical: smMd);

  // ── Vertical SizedBox gaps ─────────────────────────────────────────────────
  static const SizedBox gapXxs = SizedBox(height: xxs);
  static const SizedBox gapXs  = SizedBox(height: xs);
  static const SizedBox gapSm  = SizedBox(height: sm);
  static const SizedBox gapMd  = SizedBox(height: md);
  static const SizedBox gapLg  = SizedBox(height: lg);
  static const SizedBox gapXl  = SizedBox(height: xl);
  static const SizedBox gapXxl = SizedBox(height: xxl);

  // ── Horizontal SizedBox gaps ───────────────────────────────────────────────
  static const SizedBox hGapXs  = SizedBox(width: xs);
  static const SizedBox hGapSm  = SizedBox(width: sm);
  static const SizedBox hGapMd  = SizedBox(width: md);
  static const SizedBox hGapLg  = SizedBox(width: lg);
  static const SizedBox hGapXl  = SizedBox(width: xl);

  // ── Elevation scale ────────────────────────────────────────────────────────
  static const double elevationNone = 0;
  static const double elevationLow  = 1;
  static const double elevationMid  = 3;
  static const double elevationHigh = 6;
}
