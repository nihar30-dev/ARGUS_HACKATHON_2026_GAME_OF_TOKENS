import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class Responsive {
  static bool isMobile(BuildContext ctx) => MediaQuery.sizeOf(ctx).width < 600;
  static bool isTablet(BuildContext ctx) => MediaQuery.sizeOf(ctx).width < 1024;

  // Max content width for centered web layout; returns infinity on mobile (no cap).
  static double contentMaxWidth(BuildContext ctx) {
    final w = MediaQuery.sizeOf(ctx).width;
    if (w > 1100) return 860;
    if (w > 700) return 680;
    return double.infinity;
  }

  // Responsive page padding: tighter horizontal on mobile, standard on desktop.
  static EdgeInsets pagePadding(BuildContext ctx) => EdgeInsets.symmetric(
        horizontal: isMobile(ctx) ? AppSpacing.md : AppSpacing.lg,
        vertical: AppSpacing.lg,
      );

  // Wraps [child] in a centered, width-constrained box on wider screens.
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
}
