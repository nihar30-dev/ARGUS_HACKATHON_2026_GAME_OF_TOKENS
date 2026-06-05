import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Centered loading indicator with an optional message.
///
/// Use as the body of a [Scaffold] or inside a conditional widget while data
/// is being fetched.
///
/// ```dart
/// body: _loading ? const LoadingView(message: 'Running agents…') : _content,
/// ```
class LoadingView extends StatelessWidget {
  final String? message;

  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            SizedBox(height: AppSpacing.lg),
            Text(
              message!,
              style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
