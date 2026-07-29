import 'package:flutter/material.dart';

/// Lesson-type colors + labels, mirroring the web TimetableGrid (TYPE_STYLES).
class LessonTypeStyle {
  final Color accent; // left border / dot
  final Color pillBg;
  final Color pillFg;

  const LessonTypeStyle(this.accent, this.pillBg, this.pillFg);
}

const _lecture = LessonTypeStyle(Color(0xFF60A5FA), Color(0xFFDBEAFE), Color(0xFF1D4ED8));
// Аудиториски вежби are the green ones. They were green while they were
// mislabelled as LAB, and there is no reason for correcting the type to repaint
// every exercise class in the faculty.
const _exercise = LessonTypeStyle(Color(0xFF34D399), Color(0xFFD1FAE5), Color(0xFF047857));
const _lab = LessonTypeStyle(Color(0xFFFBBF24), Color(0xFFFEF3C7), Color(0xFFB45309));
const _combined = LessonTypeStyle(Color(0xFFA78BFA), Color(0xFFEDE9FE), Color(0xFF6D28D9));
const _fallback = LessonTypeStyle(Color(0xFFD1D5DB), Color(0xFFF3F4F6), Color(0xFF4B5563));

LessonTypeStyle lessonTypeStyle(String type) {
  switch (type) {
    case 'LECTURE':
      return _lecture;
    case 'EXERCISE':
      return _exercise;
    case 'LAB':
      return _lab;
    case 'COMBINED':
      return _combined;
    default:
      return _fallback;
  }
}

/// Every label the app shows for a lesson type, in one place.
///
/// The timetable used to keep its own map that relabelled LAB as "Аудиториски
/// вежби" — a plaster over the ingestion bug that stored аудиториски вежби as
/// LAB. With the type itself fixed, the cards and the Тип filter finally agree
/// on what a slot is called.
const Map<String, String> kLessonTypeLabels = {
  'LECTURE': 'Предавање',
  'EXERCISE': 'Аудиториски вежби',
  'LAB': 'Лабораториски вежби',
  'COMBINED': 'Комбинирано',
};

/// The label for a lesson type, falling back to the raw value so an unknown
/// type from the server shows as something rather than as a blank.
String lessonTypeLabel(String type) => kLessonTypeLabels[type] ?? type;

/// Glyph for a lesson type's meta row: a lectern for Предавање, a pen for the
/// exercise classes, and two joined branches for the ones that are both.
///
/// Returns null for types with no dedicated icon — callers fall back to the
/// generic tag glyph.
String? lessonTypeIconAsset(String type) {
  switch (type) {
    case 'LECTURE':
      return 'assets/lecture.svg';
    case 'EXERCISE':
    case 'LAB':
      return 'assets/excercice.svg';
    case 'COMBINED':
      return 'assets/code-fork.svg';
    default:
      return null;
  }
}
