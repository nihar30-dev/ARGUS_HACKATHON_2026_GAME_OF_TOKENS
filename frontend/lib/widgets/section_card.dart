import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Card with a coloured icon header, optional subtitle, and content area.
///
/// Extracted from the private `_Section` in `final_report_screen.dart`.
///
/// ```dart
/// SectionCard(
///   icon: Icons.help_outline_rounded,
///   iconColor: AppColors.brand,
///   iconBg: AppColors.brandSubtle,
///   title: 'Questions to Ask',
///   subtitle: '7 questions',
///   child: _myContent,
/// )
/// ```
class SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final Widget child;

  const SectionCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          Container(
            padding: AppSpacing.cardPadding,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.outline)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: AppSpacing.roundedSm),
                  child: Icon(icon, color: iconColor, size: 16),
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
                            color: AppColors.textPrimary),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: AppSpacing.cardPaddingLg,
            child: child,
          ),
        ],
      ),
    );
  }
}
