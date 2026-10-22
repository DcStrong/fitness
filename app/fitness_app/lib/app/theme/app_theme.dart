import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';

/// Fitness Yoda Material 3 theme — design system v2.
abstract final class AppTheme {
  static const String fontFamily = 'Onest';

  /// Material roles mapped onto the DS type scale (Onest, Cyrillic built in).
  static TextTheme textTheme() {
    TextStyle s(double size, double line, FontWeight weight, {Color? color}) =>
        TextStyle(
          fontFamily: fontFamily,
          fontSize: size,
          height: line / size,
          fontWeight: weight,
          color: color ?? AppColors.textPrimary,
          letterSpacing: size >= 24 ? -0.02 * size : 0,
        );

    return TextTheme(
      displayLarge: s(40, 46, FontWeight.w800),
      displayMedium: s(36, 42, FontWeight.w800),
      // Display · 32/38 · 800
      displaySmall: s(32, 38, FontWeight.w800),
      headlineLarge: s(30, 36, FontWeight.w800),
      // Number · 28/32 · 800
      headlineMedium: s(28, 32, FontWeight.w800),
      // Title · 24/30 · screen titles
      headlineSmall: s(24, 30, FontWeight.w800),
      // Heading · 18/24 · 700
      titleLarge: s(18, 24, FontWeight.w700),
      titleMedium: s(16, 22, FontWeight.w700),
      titleSmall: s(15, 20, FontWeight.w700),
      // Body · 16/24 · 500
      bodyLarge: s(16, 24, FontWeight.w500),
      // Body S · 14/20 · 500
      bodyMedium: s(14, 20, FontWeight.w500),
      bodySmall: s(13, 18, FontWeight.w500, color: AppColors.textSecondary),
      labelLarge: s(15, 20, FontWeight.w700),
      labelMedium: s(13, 18, FontWeight.w600),
      // Caption · 12/16 · 600
      labelSmall: s(12, 16, FontWeight.w600, color: AppColors.textTertiary),
    );
  }

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.primary)
        .copyWith(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          primaryContainer: AppColors.primarySoft,
          onPrimaryContainer: AppColors.primary,
          secondary: AppColors.primary,
          onSecondary: AppColors.onPrimary,
          secondaryContainer: AppColors.primarySoft,
          onSecondaryContainer: AppColors.primary,
          tertiary: AppColors.mint,
          onTertiary: AppColors.textPrimary,
          error: AppColors.error,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          onSurfaceVariant: AppColors.textSecondary,
          surfaceContainerLowest: AppColors.surface,
          surfaceContainerLow: AppColors.surface,
          surfaceContainer: AppColors.canvas,
          surfaceContainerHigh: AppColors.sunken,
          surfaceContainerHighest: AppColors.sunken,
          outline: AppColors.borderStrong,
          outlineVariant: AppColors.border,
        );

    const controlRadius = BorderRadius.all(Radius.circular(AppRadii.control));
    const controlShape = RoundedRectangleBorder(borderRadius: controlRadius);
    OutlineInputBorder inputBorder(Color color, double width) =>
        OutlineInputBorder(
          borderRadius: controlRadius,
          borderSide: BorderSide(color: color, width: width),
        );
    final text = textTheme();

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.canvas,
      visualDensity: VisualDensity.standard,
      fontFamily: fontFamily,
      textTheme: text,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: AppColors.shadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.card)),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        floatingLabelStyle: const TextStyle(color: AppColors.primary),
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        prefixIconColor: AppColors.textTertiary,
        suffixIconColor: AppColors.textTertiary,
        errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
        border: inputBorder(AppColors.borderStrong, 1.5),
        enabledBorder: inputBorder(AppColors.borderStrong, 1.5),
        focusedBorder: inputBorder(AppColors.primary, 2),
        errorBorder: inputBorder(AppColors.error, 1.5),
        focusedErrorBorder: inputBorder(AppColors.error, 2),
        disabledBorder: inputBorder(AppColors.border, 1.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: controlShape,
          // inherit: false matches Material defaults so theme switches can lerp.
          textStyle: text.labelLarge?.copyWith(inherit: false, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.borderStrong, width: 1.5),
          shape: controlShape,
          // inherit: false matches Material defaults so theme switches can lerp.
          textStyle: text.labelLarge?.copyWith(inherit: false, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(44, 44),
          shape: controlShape,
          textStyle: text.labelLarge?.copyWith(inherit: false),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(44, 44),
          shape: controlShape,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 2,
        // Circle only on icon FABs (`shape: CircleBorder()` locally).
        // Extended FABs («Привязать») must stay stadium so the label fits.
        sizeConstraints: BoxConstraints.tightFor(width: 56, height: 56),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.surface;
            }
            return AppColors.sunken;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.textPrimary;
            }
            return AppColors.textSecondary;
          }),
          side: const WidgetStatePropertyAll(BorderSide.none),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            text.labelMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primarySoft,
        side: const BorderSide(color: AppColors.border, width: 1.5),
        shape: const StadiumBorder(),
        labelStyle: text.labelMedium?.copyWith(fontSize: 14),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: AppColors.borderStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.sheet)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: text.bodyMedium?.copyWith(color: AppColors.onPrimary),
        shape: const RoundedRectangleBorder(borderRadius: controlRadius),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.primarySoft,
        indicatorShape: const StadiumBorder(),
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
            size: 22,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: fontFamily,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w600,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        dividerColor: AppColors.border,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        space: 1,
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.sunken,
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      visualDensity: VisualDensity.standard,
      fontFamily: fontFamily,
    );
  }
}
