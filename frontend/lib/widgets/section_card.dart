import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Card with a coloured icon header, optional subtitle, and content area.
/// Fully dark-mode aware via [AppTheme.cardDecorationOf].
class SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final Widget child;
  final EdgeInsets? contentPadding;

  const SectionCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.subtitle,
    required this.child,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.outlineDark : AppColors.outline;
    final subtitleColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      decoration: AppTheme.cardDecorationOf(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: AppSpacing.roundedSm,
                  ),
                  child: Icon(icon, color: iconColor, size: 17),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle!,
                          style: TextStyle(fontSize: 12, color: subtitleColor),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Content ───────────────────────────────────────────────────────
          Padding(
            padding: contentPadding ?? AppSpacing.cardPaddingLg,
            child: child,
          ),
        ],
      ),
    );
  }
}
