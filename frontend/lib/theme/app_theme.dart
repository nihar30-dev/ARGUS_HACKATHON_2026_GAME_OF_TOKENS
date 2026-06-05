import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

abstract class AppTheme {
  // ── Theme entry points ─────────────────────────────────────────────────────
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark  => _build(Brightness.dark);

  // ── Internal builder ───────────────────────────────────────────────────────
  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
      primary:         AppColors.brand,
      onPrimary:       Colors.white,
      secondary:       AppColors.teal,        // violet
      onSecondary:     Colors.white,
      tertiary:        AppColors.accent,      // indigo
      surface:         isDark ? AppColors.surfaceCardDark : AppColors.surfaceCard,
      onSurface:       isDark ? const Color(0xFFF1F5F9) : AppColors.textPrimary,
      onSurfaceVariant:isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
      outline:         isDark ? AppColors.outlineDark : AppColors.outline,
      outlineVariant:  isDark ? AppColors.outlineDarkStrong : AppColors.outlineStrong,
      surfaceContainerHighest: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceHover,
    );

    final scaffoldBg = isDark ? AppColors.surfacePageDark   : AppColors.surfacePage;
    final cardBg     = isDark ? AppColors.surfaceCardDark   : AppColors.surfaceCard;
    final appBarBg   = isDark ? AppColors.surfaceDark       : AppColors.surfaceCard;
    final border     = isDark ? AppColors.outlineDark       : AppColors.outline;
    final textPri    = isDark ? const Color(0xFFF1F5F9)     : AppColors.textPrimary;
    final textSec    = isDark ? const Color(0xFF94A3B8)     : AppColors.textSecondary;
    final textMuted  = isDark ? const Color(0xFF64748B)     : AppColors.textMuted;
    final inputFill  = isDark ? AppColors.surfaceCodeDark   : AppColors.surfaceCard;
    final inputBorder= isDark ? AppColors.outlineDark       : AppColors.outline;

    final base      = _buildTextTheme(textPri, textSec, textMuted);
    final textTheme = GoogleFonts.interTextTheme(base);

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: scaffoldBg,
      brightness: brightness,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: textTheme,

      // ── AppBar ─────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: textPri,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: textPri,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: textSec),
        actionsIconTheme: IconThemeData(color: textSec),
        shape: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.outlineDark
                : AppColors.outline,
            width: 1,
          ),
        ),
      ),

      // ── Cards ──────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedLg,
          side: BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // ── Filled button (primary CTA) ────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) return border;
            if (s.contains(WidgetState.pressed))  return AppColors.brandDark;
            if (s.contains(WidgetState.hovered))  return AppColors.brandMid;
            return AppColors.brand;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) return textMuted;
            return Colors.white;
          }),
          overlayColor: WidgetStateProperty.all(
            Colors.white.withValues(alpha: 0.10),
          ),
          minimumSize: WidgetStateProperty.all(const Size(0, 46)),
          padding: WidgetStateProperty.all(AppSpacing.buttonPadding),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
          ),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.1),
          ),
          elevation: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.hovered)) return 4;
            return 0;
          }),
          shadowColor: WidgetStateProperty.all(AppColors.shadowBrand),
          mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
          animationDuration: const Duration(milliseconds: 160),
        ),
      ),

      // ── Outlined button ────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.hovered)) return AppColors.teal;
            return AppColors.brand;
          }),
          minimumSize: WidgetStateProperty.all(const Size(0, 46)),
          padding: WidgetStateProperty.all(AppSpacing.buttonPadding),
          side: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.hovered)) {
              return const BorderSide(color: AppColors.teal, width: 1.5);
            }
            return const BorderSide(color: AppColors.brand, width: 1.5);
          }),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
          ),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.1),
          ),
          overlayColor: WidgetStateProperty.all(
            AppColors.brand.withValues(alpha: 0.06),
          ),
          mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
          animationDuration: const Duration(milliseconds: 160),
        ),
      ),

      // ── Text button ────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.brand),
          minimumSize: WidgetStateProperty.all(const Size(0, 40)),
          padding: WidgetStateProperty.all(AppSpacing.buttonPaddingCompact),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
          ),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          overlayColor: WidgetStateProperty.all(
            AppColors.brand.withValues(alpha: 0.06),
          ),
          mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
        ),
      ),

      // ── Input fields ───────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(color: inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(color: inputBorder),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(color: AppColors.brand, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(color: AppColors.danger, width: 2),
        ),
        labelStyle: GoogleFonts.inter(
          color: textSec,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          color: AppColors.brand,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 14),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
        errorStyle: GoogleFonts.inter(color: AppColors.danger, fontSize: 12),
      ),

      // ── Chips ──────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.surfaceCodeDark : AppColors.surfacePage,
        selectedColor: isDark ? AppColors.outlineDark : AppColors.brandSubtle,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSec,
        ),
        side: BorderSide(color: border),
        shape: const RoundedRectangleBorder(borderRadius: AppSpacing.roundedPill),
        padding: AppSpacing.chipPadding,
      ),

      // ── Divider ────────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : AppColors.outline,
        thickness: 1,
        space: 1,
      ),

      // ── List tile ──────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        titleTextStyle: TextStyle(
            color: textPri, fontSize: 14, fontWeight: FontWeight.w500),
        subtitleTextStyle: TextStyle(color: textSec, fontSize: 13),
      ),

      // ── Progress indicator ─────────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.brand,
        linearTrackColor: isDark ? AppColors.outlineDark : AppColors.brandSubtle,
        linearMinHeight: 6,
        borderRadius: AppSpacing.roundedPill,
      ),

      // ── Snack bar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.surfaceElevatedDark : AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        actionTextColor: AppColors.tealLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
        elevation: 8,
      ),

      // ── Tooltip ────────────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceElevatedDark : AppColors.textPrimary,
          borderRadius: AppSpacing.roundedSm,
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMd,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        textStyle: TextStyle(
          color: isDark ? Colors.white : AppColors.surface,
          fontSize: 12,
        ),
      ),

      // ── Scrollbar: slim pill ───────────────────────────────────────────────
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(5),
        radius: const Radius.circular(AppSpacing.radiusPill),
        thumbColor: WidgetStateProperty.all(
          isDark ? AppColors.outlineDarkStrong : AppColors.outlineStrong,
        ),
        trackColor: WidgetStateProperty.all(Colors.transparent),
        thumbVisibility: WidgetStateProperty.all(false),
        trackVisibility: WidgetStateProperty.all(false),
      ),

      // ── Navigation bar ─────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceCard,
        indicatorColor: isDark ? AppColors.outlineDark : AppColors.brandSubtle,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // ── Text theme ─────────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme(Color pri, Color sec, Color muted) {
    return TextTheme(
      displayLarge:   TextStyle(fontSize: 52, fontWeight: FontWeight.w800, color: pri, letterSpacing: -2.0, height: 1.05),
      displayMedium:  TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: pri, letterSpacing: -1.5, height: 1.10),
      displaySmall:   TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: pri, letterSpacing: -0.8, height: 1.18),
      headlineLarge:  TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: pri, letterSpacing: -0.6, height: 1.25),
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: pri, letterSpacing: -0.4, height: 1.30),
      headlineSmall:  TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: pri, letterSpacing: -0.2, height: 1.35),
      titleLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: pri, letterSpacing: -0.1, height: 1.40),
      titleMedium:    TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: pri, letterSpacing:  0.0, height: 1.40),
      titleSmall:     TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sec, letterSpacing:  0.1, height: 1.40),
      bodyLarge:      TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: pri, height: 1.65),
      bodyMedium:     TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: pri, height: 1.60),
      bodySmall:      TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: sec, height: 1.55),
      labelLarge:     TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: pri, letterSpacing: 0.1),
      labelMedium:    TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: sec, letterSpacing: 0.2),
      labelSmall:     TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: muted, letterSpacing: 0.4),
    );
  }

  // ── Static presets (light-mode or gradient — context-free) ────────────────

  /// Basic card — light mode only. Use [cardDecorationOf] in screens.
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: AppColors.surfaceCard,
    borderRadius: AppSpacing.roundedLg,
    border: const Border.fromBorderSide(BorderSide(color: AppColors.outline)),
    boxShadow: [
      BoxShadow(color: AppColors.shadowXs, blurRadius: 2, offset: const Offset(0, 1)),
      BoxShadow(color: AppColors.shadowSm, blurRadius: 10, offset: const Offset(0, 5)),
    ],
  );

  /// Multi-stop deep-navy hero gradient (dashboard + demo loading).
  static const BoxDecoration heroDecoration = BoxDecoration(
    gradient: AppColors.heroGradient,
  );

  /// Brand surface — light mode gradient panel.
  static BoxDecoration get brandSurface => const BoxDecoration(
    gradient: AppColors.surfaceGradient,
    borderRadius: AppSpacing.roundedLg,
    border: Border.fromBorderSide(BorderSide(color: AppColors.brandSubtle)),
  );

  /// Code block — light mode.
  static BoxDecoration get codeDecoration => BoxDecoration(
    color: AppColors.surfaceCode,
    borderRadius: AppSpacing.roundedMd,
    border: const Border.fromBorderSide(BorderSide(color: AppColors.outline)),
  );

  // ── Context-aware decorations (always prefer these in screens) ─────────────

  /// Standard card respecting dark / light mode.
  static BoxDecoration cardDecorationOf(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? AppColors.surfaceCardDark : AppColors.surfaceCard,
      borderRadius: AppSpacing.roundedLg,
      border: Border.all(
        color: isDark ? AppColors.outlineDark : AppColors.outline,
      ),
      boxShadow: isDark
          ? [
              // Subtle aura — makes dark cards pop on the navy scaffold
              BoxShadow(
                color: AppColors.brand.withValues(alpha: 0.06),
                blurRadius: 24,
                spreadRadius: -2,
                offset: Offset.zero,
              ),
            ]
          : [
              BoxShadow(color: AppColors.shadowXs, blurRadius: 2, offset: const Offset(0, 1)),
              BoxShadow(color: AppColors.shadowSm, blurRadius: 12, offset: const Offset(0, 6)),
            ],
    );
  }

  /// Code block respecting dark / light mode.
  static BoxDecoration codeDecorationOf(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? AppColors.surfaceCodeDark : AppColors.surfaceCode,
      borderRadius: AppSpacing.roundedMd,
      border: Border.all(
        color: isDark ? AppColors.outlineDark : AppColors.outline,
      ),
    );
  }

  /// Brand-tinted surface panel respecting dark / light mode.
  static BoxDecoration brandSurfaceOf(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      gradient: isDark
          ? AppColors.darkSurfaceGradient
          : AppColors.surfaceGradient,
      borderRadius: AppSpacing.roundedLg,
      border: Border.all(
        color: isDark ? AppColors.outlineDark : AppColors.brandSubtle,
      ),
    );
  }

  // ── Text style presets ─────────────────────────────────────────────────────

  /// Monospaced — for JSON / code output.
  static TextStyle get monoStyle => GoogleFonts.jetBrainsMono(
    fontSize: 12,
    color: AppColors.textSecondary,
    height: 1.65,
  );

  static TextStyle monoStyleOf(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.jetBrainsMono(
      fontSize: 12,
      color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
      height: 1.65,
    );
  }

  /// Section overline label (ALL CAPS, tracking).
  static TextStyle get overlineStyle => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
    letterSpacing: 0.9,
    height: 1.4,
  );

  static TextStyle overlineStyleOf(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: isDark ? const Color(0xFF64748B) : AppColors.textMuted,
      letterSpacing: 0.9,
      height: 1.4,
    );
  }
}
