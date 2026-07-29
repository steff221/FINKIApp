import 'package:flutter/material.dart';

/// FINKI brand palette — mirrors tailwind.config.ts and the web UI.
class AppColors {
  static const navy = Color(0xFF00265C); // finki-navy / primary
  static const mid = Color(0xFF0050B3); // finki-mid / hover
  static const bright = Color(0xFF1A7FFF); // finki-bright / accents
  static const canvas = Color(0xFFF7F9FC); // page background — near-white, airy
  static const card = Colors.white;

  static const examAccent = Color(0xFFE11D48); // rose-600 — exams accent/highlight
  static const examSurface = Color(0xFFFFE4E6); // rose-100 — exam tags/pills
  static const danger = Color(0xFFEF4444); // red-500 — delete actions, conflicts
  static const dangerInk = Color(0xFFB91C1C); // red-700 — error text on a tint
  static const dangerSurface = Color(0xFFFEF2F2); // red-50 — error panel fill
  static const dangerBorder = Color(0xFFFECACA); // red-200 — error panel border

  static const ink = Color(0xFF111827); // gray-900
  static const muted = Color(0xFF6B7280); // gray-500
  static const faint = Color(0xFF9CA3AF); // gray-400
  static const border = Color(0xFFE5E7EB); // gray-200
  static const hairline = Color(0xFFF3F4F6); // gray-100

  /// The one warm note in an otherwise cool palette — reserved for a choice the
  /// student has made (a selected segment), so it never competes with navy.
  static const warm = Color(0xFFD98E2B);
  static const warmSurface = Color(0xFFFBF1E1);

  /// The bottom of the page wash — the background settles into it.
  static const wash = Color(0xFFDCE7F6);

  /// Soft navy-tinted panel. Carries a block of text that is neither a card nor
  /// the page — the "what now" hero, an empty state, a callout.
  static const panel = Color(0xFFEDF1FA);

  /// Fill for text fields and unselected segments: a recess in the page rather
  /// than a box drawn on it. Deliberately a clear step down from [canvas] —
  /// closer than this and a filled control disappears into the page.
  static const field = Color(0xFFE8EDF5);
}
