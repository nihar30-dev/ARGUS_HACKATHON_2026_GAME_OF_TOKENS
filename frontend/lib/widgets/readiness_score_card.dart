import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Circular progress meter for a readiness / confidence score.
///
/// Extracted from the private `_ReadinessMeter` in `final_report_screen.dart`.
///
/// [color] and [trackColor] default to white so the widget looks right on a
/// brand-gradient background. Pass [AppColors.forConfidence(score)] for
/// use on a light background.
class ReadinessScoreCard extends StatelessWidget {
  final double score;
  final double size;
  final Color color;
  final Color trackColor;

  const ReadinessScoreCard({
    super.key,
    required this.score,
    this.size = 140,
    this.color = Colors.white,
    this.trackColor = const Color(0x26FFFFFF), // white 15%
  });

  @override
  Widget build(BuildContext context) {
    final pct = (score * 100).toStringAsFixed(0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: score,
                strokeWidth: size * 0.09,
                backgroundColor: trackColor,
                valueColor: AlwaysStoppedAnimation(color),
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$pct%',
                  style: TextStyle(
                    color: color,
                    fontSize: size * 0.27,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'READINESS',
                  style: TextStyle(
                    color: color.withValues(alpha: 0.7),
                    fontSize: size * 0.07,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: AppSpacing.smMd),
        Text(
          'Meeting Strategy Ready',
          style: TextStyle(
            color: color.withValues(alpha: 0.9),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'All agents completed',
          style: TextStyle(
            color: color.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
