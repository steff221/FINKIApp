import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_shape.dart';
import 'app_type.dart';

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      primary: AppColors.navy,
      surface: AppColors.canvas,
    ),
    // The page itself is painted once behind the router (see PageBackground),
    // so scaffolds let it through instead of covering it.
    scaffoldBackgroundColor: Colors.transparent,
  );

  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(
      base.textTheme,
    ).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
    // No coloured slab: a screen begins with its own name, set in the serif, on
    // the same surface as its content.
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      // A transparent bar reads as *dark* to Flutter's brightness estimate, so
      // it would ask iOS for a white clock and battery on our light pages —
      // i.e. an invisible status bar. Every page here is light: say so.
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      foregroundColor: AppColors.navy,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppType.screenTitle,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),
    // Fields are a recess in the page, not a box drawn on it: filled, no
    // outline at rest, and a navy ring only while they have focus.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.field,
      floatingLabelStyle: const TextStyle(
        color: AppColors.navy,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(color: AppColors.faint),
      prefixIconColor: AppColors.muted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: const BorderSide(color: AppColors.navy, width: 1.4),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shadowColor: AppColors.navy.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.navy.withValues(alpha: 0.10),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? AppColors.navy
              : AppColors.muted,
        ),
      ),
    ),
  );
}
