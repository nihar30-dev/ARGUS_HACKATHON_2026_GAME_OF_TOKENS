import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Compact metric tile — icon on the left, large value + label on the right.
///
/// Extracted from the private `_BigStatTile` in `dashboard_screen.dart`.
///
/// ```dart
/// InfoCard(
///   value: '6',
///   label: 'Total Agents',
///   icon: Icons.smart_toy_outlined,
///   foreground: AppColors.brand,
///   background: AppColors.brandSubtle,
/// )
/// ```
class InfoCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;

  const InfoCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppSpacing.roundedMd,
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground, size: 20),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: foreground,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    color: foreground.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
