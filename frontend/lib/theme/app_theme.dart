import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// Central Material 3 theme for MeetWise.
///
/// Usage:
///   theme: AppTheme.light
///
/// Inside widgets prefer [Theme.of(context).colorScheme] for component colors
/// and [AppColors] for semantic values (confidence, agent type, etc.).
abstract class AppTheme {
  static ThemeData get light {
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: Brightness.light,
      // Override key roles so seed-generated shades stay on-brand.
      primary: AppColors.brand,
      onPrimary: AppColors.textOnBrand,
      secondary: AppColors.accent,
      onSecondary: AppColors.textOnBrand,
      surface: AppColors.surface,
      surfaceContainerLowest: AppColors.surfacePage,
      outline: AppColors.outline,
      outlineVariant: AppColors.outline,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.surfacePage,

      // ── Typography ─────────────────────────────────────────────────────────
      textTheme: _buildTextTheme(cs),

      // ── AppBar ─────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: AppSpacing.elevationNone,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.outline,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        actionsIconTheme: const IconThemeData(color: AppColors.textSecondary),
        shape: const Border(
          bottom: BorderSide(color: AppColors.outline, width: 1),
        ),
      ),

      // ── Card ───────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        elevation: AppSpacing.elevationNone,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedLg,
          side: const BorderSide(color: AppColors.outline, width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // ── FilledButton ───────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: AppColors.textOnBrand,
          minimumSize: const Size(0, 48),
          padding: AppSpacing.buttonPadding,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.outline;
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.brandDark;
            }
            if (states.contains(WidgetState.hovered)) {
              return AppColors.brandMid;
            }
            return AppColors.brand;
          }),
        ),
      ),

      // ── OutlinedButton ─────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brand,
          minimumSize: const Size(0, 48),
          padding: AppSpacing.buttonPadding,
          side: const BorderSide(color: AppColors.brand, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // ── TextButton ─────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand,
          minimumSize: const Size(0, 40),
          padding: AppSpacing.buttonPaddingCompact,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // ── Input Decoration ───────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: AppSpacing.inputPadding,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: const BorderSide(color: AppColors.brand, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.brand,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
        errorStyle: const TextStyle(color: AppColors.danger, fontSize: 12),
      ),

      // ── Chip ───────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfacePage,
        selectedColor: AppColors.brandSubtle,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        side: const BorderSide(color: AppColors.outline),
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedPill,
        ),
        padding: AppSpacing.chipPadding,
      ),

      // ── Divider ────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.outline,
        thickness: 1,
        space: 1,
      ),

      // ── ListTile ───────────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
      ),

      // ── ProgressIndicator ──────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brand,
        linearTrackColor: AppColors.brandSubtle,
        linearMinHeight: 6,
        borderRadius: AppSpacing.roundedPill,
      ),

      // ── SnackBar ───────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(
          color: AppColors.surface,
          fontSize: 14,
        ),
        actionTextColor: AppColors.brandMid,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
        elevation: AppSpacing.elevationHigh,
      ),

      // ── Tooltip ────────────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: AppSpacing.roundedSm,
        ),
        textStyle: const TextStyle(
          color: AppColors.surface,
          fontSize: 12,
        ),
      ),

      // ── Bottom Navigation ──────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.brandSubtle,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        elevation: AppSpacing.elevationLow,
      ),
    );
  }

  // ── Text theme ─────────────────────────────────────────────────────────────

  static TextTheme _buildTextTheme(ColorScheme cs) {
    return const TextTheme(
      // Page / section headings
      displayLarge: TextStyle(
        fontSize: 48, fontWeight: FontWeight.w800,
        color: AppColors.textPrimary, letterSpacing: -1.5, height: 1.1,
      ),
      displayMedium: TextStyle(
        fontSize: 36, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, letterSpacing: -1.0, height: 1.2,
      ),
      displaySmall: TextStyle(
        fontSize: 28, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, letterSpacing: -0.5, height: 1.25,
      ),

      // Section / card headings
      headlineLarge: TextStyle(
        fontSize: 24, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, letterSpacing: -0.5, height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, letterSpacing: -0.3, height: 1.35,
      ),
      headlineSmall: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, letterSpacing: -0.2, height: 1.4,
      ),

      // Component titles
      titleLarge: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, letterSpacing: -0.1, height: 1.4,
      ),
      titleMedium: TextStyle(
        fontSize: 15, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, letterSpacing: 0, height: 1.4,
      ),
      titleSmall: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w600,
        color: AppColors.textSecondary, letterSpacing: 0.1, height: 1.4,
      ),

      // Body content
      bodyLarge: TextStyle(
        fontSize: 15, fontWeight: FontWeight.w400,
        color: AppColors.textPrimary, height: 1.6,
      ),
      bodyMedium: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w400,
        color: AppColors.textPrimary, height: 1.55,
      ),
      bodySmall: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w400,
        color: AppColors.textSecondary, height: 1.5,
      ),

      // Labels, captions, metadata
      labelLarge: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w500,
        color: AppColors.textSecondary, letterSpacing: 0.2,
      ),
      labelSmall: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w500,
        color: AppColors.textMuted, letterSpacing: 0.4,
      ),
    );
  }

  // ── Reusable BoxDecoration presets ─────────────────────────────────────────

  /// White card with a subtle border (no elevation shadow).
  static BoxDecoration get cardDecoration => const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppSpacing.roundedLg,
        border: Border.fromBorderSide(BorderSide(color: AppColors.outline)),
      );

  /// Tinted brand surface (e.g., summary bars, banners).
  static BoxDecoration get brandSurface => const BoxDecoration(
        gradient: AppColors.surfaceGradient,
        borderRadius: AppSpacing.roundedLg,
        border: Border.fromBorderSide(BorderSide(color: AppColors.brandSubtle)),
      );

  /// Full brand gradient (hero sections, loading overlays).
  static BoxDecoration get heroDecoration => const BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: AppSpacing.roundedLg,
      );

  /// Code / JSON block background.
  static BoxDecoration get codeDecoration => const BoxDecoration(
        color: AppColors.surfaceCode,
        borderRadius: AppSpacing.roundedMd,
        border: Border.fromBorderSide(BorderSide(color: AppColors.outline)),
      );

  // ── TextStyle shortcuts ────────────────────────────────────────────────────

  /// Mono-spaced style for JSON / raw output blocks.
  static const TextStyle monoStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    color: AppColors.textSecondary,
    height: 1.6,
  );

  /// Uppercase section label (like a Figma "overline" role).
  static const TextStyle overlineStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    letterSpacing: 0.8,
    height: 1.4,
  );
}
