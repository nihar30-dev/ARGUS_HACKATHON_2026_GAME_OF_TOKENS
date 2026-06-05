import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Full-width [FilledButton] with an integrated loading spinner.
///
/// When [loading] is true the icon swaps to a spinner, the label shows
/// [loadingLabel] (or [label] if not set), and [onPressed] is disabled.
///
/// Set [outlined] to get the [OutlinedButton] variant.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final String? loadingLabel;
  final bool outlined;
  final double? verticalPadding;

  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.loadingLabel,
    this.outlined = false,
    this.verticalPadding,
  });

  EdgeInsets get _pad => EdgeInsets.symmetric(
      vertical: verticalPadding ?? AppSpacing.smMd);

  Widget get _icon => loading
      ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
      : Icon(icon ?? Icons.arrow_forward_rounded, size: 18);

  Widget get _label => Text(loading ? (loadingLabel ?? label) : label);

  @override
  Widget build(BuildContext context) {
    final style = outlined
        ? OutlinedButton.styleFrom(padding: _pad)
        : FilledButton.styleFrom(padding: _pad);

    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: loading ? null : onPressed,
              style: style,
              icon: Icon(icon ?? Icons.refresh_outlined, size: 18),
              label: _label,
            )
          : FilledButton.icon(
              onPressed: loading ? null : onPressed,
              style: style,
              icon: _icon,
              label: _label,
            ),
    );
  }
}
