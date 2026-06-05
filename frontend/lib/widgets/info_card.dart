import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Compact metric tile — icon on the left, large value + label on the right.
///
/// Automatically adjusts border tint for dark mode using [foreground] alpha.
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
        border: Border.all(
          color: foreground.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: foreground.withValues(alpha: 0.12),
              borderRadius: AppSpacing.roundedSm,
            ),
            child: Icon(icon, color: foreground, size: 18),
          ),
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
                    color: foreground.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
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
