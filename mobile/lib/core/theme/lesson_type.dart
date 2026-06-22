import 'package:flutter/material.dart';

/// Lesson-type colors + labels, mirroring the web TimetableGrid (TYPE_STYLES)
/// and the timetable's LAB→"Аудиториски вежби" relabel.
class LessonTypeStyle {
  final Color accent; // left border / dot
  final Color pillBg;
  final Color pillFg;

  const LessonTypeStyle(this.accent, this.pillBg, this.pillFg);
}

const _lecture = LessonTypeStyle(Color(0xFF60A5FA), Color(0xFFDBEAFE), Color(0xFF1D4ED8));
const _lab = LessonTypeStyle(Color(0xFF34D399), Color(0xFFD1FAE5), Color(0xFF047857));
const _exercise = LessonTypeStyle(Color(0xFFFBBF24), Color(0xFFFEF3C7), Color(0xFFB45309));
const _combined = LessonTypeStyle(Color(0xFFA78BFA), Color(0xFFEDE9FE), Color(0xFF6D28D9));
const _fallback = LessonTypeStyle(Color(0xFFD1D5DB), Color(0xFFF3F4F6), Color(0xFF4B5563));

LessonTypeStyle lessonTypeStyle(String type) {
  switch (type) {
    case 'LECTURE':
      return _lecture;
    case 'LAB':
      return _lab;
    case 'EXERCISE':
      return _exercise;
    case 'COMBINED':
      return _combined;
    default:
      return _fallback;
  }
}

/// Timetable label overrides — LAB shows as "Аудиториски вежби" here (matches web),
/// while the shared meaning stays the same elsewhere.
String timetableTypeLabel(String type) {
  switch (type) {
    case 'LECTURE':
      return 'Предавање';
    case 'LAB':
      return 'Аудиториски вежби';
    case 'EXERCISE':
      return 'Аудиториски вежби';
    case 'COMBINED':
      return 'Комбинирано';
    default:
      return type;
  }
}

const Map<String, String> kLessonTypeLabels = {
  'LECTURE': 'Предавање',
  'LAB': 'Лабораториски вежби',
  'EXERCISE': 'Аудиториски вежби',
  'COMBINED': 'Комбинирано',
};
