import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// The app speaks in two voices.
///
/// A serif names things — screens, sections, the panel that tells you what is
/// next. Inter carries everything you actually read: times, rooms, subjects,
/// labels. Keeping the serif to headings is what makes it read as editorial
/// rather than as a novelty font.
///
/// Playfair Display covers Cyrillic, which most display serifs do not.
abstract final class AppType {
  static TextStyle _serif({
    required double size,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.navy,
    double height = 1.2,
    double? letterSpacing,
  }) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// The greeting on Дома — the one line that talks to the student.
  static TextStyle get greeting => _serif(size: 27, height: 1.15, letterSpacing: -0.3);

  /// A screen's own name.
  static TextStyle get screenTitle => _serif(size: 25, height: 1.15, letterSpacing: -0.2);

  /// The same, once it has collapsed into a toolbar.
  static TextStyle get toolbarTitle => _serif(size: 18, height: 1.2);

  /// Heading over a section of a page — "Оваа недела", "Поминати испити".
  static TextStyle get section => _serif(size: 19);

  /// Heading inside a panel or an empty state.
  static TextStyle get panelTitle => _serif(size: 21, height: 1.25);

  /// What a card is about — a subject, an exam, a professor.
  ///
  /// A little larger than the sans it replaces: Playfair carries a smaller
  /// x-height, so matching Inter's 15px would read as a step down.
  static TextStyle get cardTitle =>
      _serif(size: 16, height: 1.25, color: AppColors.ink);

  /// The quiet line under a title. Inter — it is read, not announced.
  static const TextStyle subtitle = TextStyle(
    fontSize: 13.5,
    height: 1.35,
    fontWeight: FontWeight.w400,
    color: AppColors.muted,
  );

  /// Label above a form field.
  static const TextStyle fieldLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );
}
