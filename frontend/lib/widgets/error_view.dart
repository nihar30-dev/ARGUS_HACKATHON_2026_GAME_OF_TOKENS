import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Inline error banner (dismissible) or full-area error / empty state.
///
/// **Banner** (`compact: true`, default) — small coloured container suitable
/// for embedding inside a form or scroll view.
///
/// **Full area** (`compact: false`) — centred column with icon, optional title,
/// message, and up to two action buttons. Use as the [Scaffold] body when a
/// screen fails to load or has no data.
///
/// Set [isError] = false for neutral empty-state scenarios (grey palette
/// instead of red). Pass [icon] to override the default icon.
class ErrorView extends StatelessWidget {
  final String message;

  /// Optional bold heading shown above [message] in full-area mode.
  final String? title;

  /// Override the default icon. Compact mode always uses [Icons.error_outline].
  final IconData? icon;

  /// `true` (default) = red danger palette. `false` = neutral grey for empty states.
  final bool isError;

  /// Compact banner dismiss callback (shows × button when non-null).
  final VoidCallback? onDismiss;

  /// Primary action. Shows as a [FilledButton] in full-area mode.
  final VoidCallback? onRetry;

  /// Label for the primary action button. Defaults to 'Retry'.
  final String? retryLabel;

  /// Secondary action. Shows as an [OutlinedButton] below the primary action.
  final VoidCallback? onSecondary;

  /// Label for the secondary action button. Defaults to 'Go Back'.
  final String? secondaryLabel;

  /// `true` = compact banner (inline). `false` = full-screen error / empty state.
  final bool compact;

  const ErrorView({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.isError = true,
    this.onDismiss,
    this.onRetry,
    this.retryLabel,
    this.onSecondary,
    this.secondaryLabel,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) =>
      compact ? _banner() : _fullArea(context);

  // ── Compact banner ────────────────────────────────────────────────────────

  Widget _banner() => Container(
        padding: AppSpacing.cardPadding,
        decoration: const BoxDecoration(
          color: AppColors.dangerLight,
          borderRadius: AppSpacing.roundedMd,
          border: Border.fromBorderSide(
              BorderSide(color: AppColors.dangerSubtle)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.danger, size: 20),
            AppSpacing.hGapSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Request failed',
                    style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 13,
                        height: 1.4),
                  ),
                ],
              ),
            ),
            if (onDismiss != null)
              GestureDetector(
                onTap: onDismiss,
                child: const Padding(
                  padding: EdgeInsets.only(left: AppSpacing.sm),
                  child: Icon(Icons.close,
                      color: AppColors.danger, size: 18),
                ),
              ),
          ],
        ),
      );

  // ── Full-area error / empty state ─────────────────────────────────────────

  Widget _fullArea(BuildContext context) {
    final iconData = icon ??
        (isError ? Icons.error_outline : Icons.inbox_outlined);
    final iconColor = isError ? AppColors.danger : AppColors.textMuted;
    final iconBg =
        isError ? AppColors.dangerLight : AppColors.surfacePage;
    final borderColor =
        isError ? AppColors.dangerSubtle : AppColors.outline;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: borderColor),
                ),
                child: Icon(iconData, color: iconColor, size: 28),
              ),
              const SizedBox(height: AppSpacing.md),
              if (title != null) ...[
                Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.55,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onRetry,
                    child: Text(retryLabel ?? 'Retry'),
                  ),
                ),
              ],
              if (onSecondary != null) ...[
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onSecondary,
                    child: Text(secondaryLabel ?? 'Go Back'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
