import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ConfidenceBadge extends StatelessWidget {
  final double score;
  final double fontSize;

  const ConfidenceBadge({super.key, required this.score, this.fontSize = 24});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${(score * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
            color: AppColors.forConfidence(score),
          ),
        ),
        Text(
          'confidence',
          style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
