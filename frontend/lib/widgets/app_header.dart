import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/theme_notifier.dart';

/// MeetWise SVG logo header — use as [AppBar.title].
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SvgPicture.asset(
      isDark
          ? 'assets/logo/meetwise_logo_dark.svg'
          : 'assets/logo/meetwise_logo.svg',
      height: 30,
      fit: BoxFit.contain,
    );
  }
}

/// Dark/light theme toggle — drop into AppBar.actions.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ThemeNotifier>();
    return IconButton(
      tooltip: notifier.isDark ? 'Light mode' : 'Dark mode',
      icon: Icon(
        notifier.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        color: notifier.isDark ? AppColors.tealLight : AppColors.textSecondary,
        size: 20,
      ),
      onPressed: notifier.toggle,
    );
  }
}
