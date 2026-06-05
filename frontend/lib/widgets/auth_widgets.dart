import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

// ── Background decoration: glowing orb ──────────────────────────────────────

class AuthGlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  final double alpha;

  const AuthGlowOrb({
    super.key,
    required this.color,
    required this.size,
    required this.alpha,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

// ── Background decoration: dot grid ─────────────────────────────────────────

class AuthDotPainter extends CustomPainter {
  const AuthDotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 32.0;
    final paint = Paint()
      ..color = const Color(0x0F3B82F6)
      ..style = PaintingStyle.fill;
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Brand wordmark ───────────────────────────────────────────────────────────

class AuthBrand extends StatelessWidget {
  const AuthBrand({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          shaderCallback: (b) => AppColors.brandGradient.createShader(b),
          blendMode: BlendMode.srcIn,
          child: const Text(
            'MeetWise',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'AI Meeting Intelligence',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.45),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ── Glass card container ─────────────────────────────────────────────────────

class AuthCard extends StatelessWidget {
  final EdgeInsets padding;
  final Widget child;

  const AuthCard({super.key, required this.padding, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: AppSpacing.roundedXxl,
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }
}

// ── Input theme override ─────────────────────────────────────────────────────

ThemeData authInputTheme(BuildContext context) {
  return Theme.of(context).copyWith(
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.07),
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
      prefixIconColor: Colors.white.withValues(alpha: 0.45),
      suffixIconColor: Colors.white.withValues(alpha: 0.45),
      helperStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
      errorStyle: const TextStyle(color: Color(0xFFFC8181)),
      border: OutlineInputBorder(
        borderRadius: AppSpacing.roundedMd,
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppSpacing.roundedMd,
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppSpacing.roundedMd,
        borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppSpacing.roundedMd,
        borderSide: const BorderSide(color: Color(0xFFFC8181)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppSpacing.roundedMd,
        borderSide: const BorderSide(color: Color(0xFFFC8181), width: 1.5),
      ),
    ),
  );
}

// ── Error banner ─────────────────────────────────────────────────────────────

class AuthErrorBanner extends StatelessWidget {
  final String message;
  const AuthErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.15),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              size: 16, color: AppColors.danger.withValues(alpha: 0.85)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.danger.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Gradient submit button ───────────────────────────────────────────────────

class AuthSubmitButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: loading ? null : AppColors.brandGradient,
          color: loading ? Colors.white.withValues(alpha: 0.12) : null,
          borderRadius: AppSpacing.roundedMd,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: AppSpacing.roundedMd,
          child: InkWell(
            onTap: loading ? null : onPressed,
            borderRadius: AppSpacing.roundedMd,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
