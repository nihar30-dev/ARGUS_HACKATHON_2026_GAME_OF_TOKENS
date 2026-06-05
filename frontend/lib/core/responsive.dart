import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class Responsive {
  // ── Breakpoints ────────────────────────────────────────────────────────────
  static bool isMobile(BuildContext ctx) =>
      MediaQuery.sizeOf(ctx).width < 640;

  static bool isTablet(BuildContext ctx) =>
      MediaQuery.sizeOf(ctx).width < 1024;

  static bool isDesktop(BuildContext ctx) =>
      MediaQuery.sizeOf(ctx).width >= 1024;

  // ── Content max width ──────────────────────────────────────────────────────
  /// Returns the max width for centred page content.
  /// Returns infinity on mobile so the layout fills the screen.
  static double contentMaxWidth(BuildContext ctx) {
    final w = MediaQuery.sizeOf(ctx).width;
    if (w > 1400) return 1120;
    if (w > 1100) return 960;
    if (w > 700)  return 720;
    return double.infinity;
  }

  // ── Page padding ───────────────────────────────────────────────────────────
  /// Responsive horizontal + vertical page padding.
  static EdgeInsets pagePadding(BuildContext ctx) {
    final w = MediaQuery.sizeOf(ctx).width;
    if (w > 1100) {
      return const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl, vertical: AppSpacing.lg);
    }
    if (w > 640) {
      return const EdgeInsets.symmetric(horizontal: AppSpacing.lg,   vertical: AppSpacing.lg);
    }
    return const EdgeInsets.symmetric(horizontal: AppSpacing.md,     vertical: AppSpacing.md);
  }

  // ── Centred content wrapper ────────────────────────────────────────────────
  /// Wraps [child] in a centred, width-constrained box on wider screens.
  static Widget centered(BuildContext ctx, Widget child) {
    final maxW = contentMaxWidth(ctx);
    if (maxW == double.infinity) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: child,
      ),
    );
  }

  // ── Column count helper ────────────────────────────────────────────────────
  /// Returns 1 on mobile, 2 on tablet, 3+ on desktop.
  static int columnCount(BuildContext ctx, {int desktopCols = 3}) {
    if (isMobile(ctx)) return 1;
    if (isTablet(ctx)) return 2;
    return desktopCols;
  }
}
