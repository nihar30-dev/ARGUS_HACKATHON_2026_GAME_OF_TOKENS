import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// MeetWise brand title row — use as [AppBar.title].
///
/// ```dart
/// appBar: AppBar(title: const AppHeader())
/// ```
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) => const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, color: AppColors.brand, size: 18),
          SizedBox(width: AppSpacing.sm),
          Text(
            'MeetWise',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ],
      );
}
