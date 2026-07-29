import 'package:flutter_test/flutter_test.dart';

import 'package:finki_scheduler/core/notifications/reminders.dart';
import 'package:finki_scheduler/models/models.dart';

ScheduleSlot slot({
  int id = 1,
  String name = 'Објектно-ориентирано програмирање',
  int day = 0, // Monday
  String start = '08:00:00',
  String? room = 'Амфитеатар А1',
}) =>
    ScheduleSlot(
      id: id,
      subject: Subject(id: id, fullName: name, baseName: name, lessonType: 'LECTURE'),
      teachers: const [],
      studyClasses: const [],
      classroom: room == null ? null : Classroom(id: 1, name: room),
      dayOfWeek: day,
      startTime: start,
      endTime: '09:45:00',
      editionNumber: '',
    );

CustomEntry entry({
  int id = 1,
  String title = 'Проектен состанок',
  int day = 0,
  String start = '12:00:00',
  String? room,
}) =>
    CustomEntry(
      id: id,
      title: title,
      professor: null,
      entryType: 'LECTURE',
      dayOfWeek: day,
      startTime: start,
      endTime: '13:00:00',
      room: room,
      color: null,
    );

Exam exam({
  int id = 1,
  String subject = 'Анализа на софтверските барања',
  String date = '2026-02-10',
  String? start = '09:00:00',
  String? rooms = 'Барака 3.2',
}) =>
    Exam(
      id: id,
      session: 'Јануари 2026',
      subjectName: subject,
      date: date,
      startTime: start,
      endTime: '11:00:00',
      rooms: rooms,
      note: null,
    );

void main() {
  // A Monday, 06:00 — before the 08:00 class it is used to reason about.
  final monday = DateTime(2026, 2, 2, 6);

  group('class reminders', () {
    test('fires 15 minutes before the class starts', () {
      final planned = planReminders(
        slots: [slot()],
        entries: const [],
        exams: const [],
        now: monday,
      );

      expect(planned.first.at, DateTime(2026, 2, 2, 7, 45));
      expect(planned.first.title, 'Објектно-ориентирано програмирање');
      expect(planned.first.body, contains('08:00'));
      expect(planned.first.body, contains('Амфитеатар А1'));
    });

    test('a class that has already started today is not scheduled', () {
      final planned = planReminders(
        slots: [slot()],
        entries: const [],
        exams: const [],
        // 08:30 — the 08:00 class is under way.
        now: DateTime(2026, 2, 2, 8, 30),
      );

      // Only next Monday's occurrence is left inside the horizon.
      expect(planned.every((r) => r.at.isAfter(DateTime(2026, 2, 2, 8, 30))), isTrue);
      expect(planned.any((r) => r.at.day == 2), isFalse);
    });

    test('a weekly class recurs once inside the seven-day horizon', () {
      final planned = planReminders(
        slots: [slot()],
        entries: const [],
        exams: const [],
        now: monday,
      );

      expect(planned.length, 1);
      expect(planned.single.at.weekday, DateTime.monday);
    });

    test('every weekday of the timetable gets its own reminder', () {
      final planned = planReminders(
        slots: [
          slot(id: 1, day: 0),
          slot(id: 2, day: 2, name: 'Веб програмирање'),
          slot(id: 3, day: 4, name: 'Бази на податоци'),
        ],
        entries: const [],
        exams: const [],
        now: monday,
      );

      expect(planned.length, 3);
      expect(planned.map((r) => r.at.weekday),
          [DateTime.monday, DateTime.wednesday, DateTime.friday]);
    });

    test('a room-less class still says when it starts', () {
      final planned = planReminders(
        slots: [slot(room: null)],
        entries: const [],
        exams: const [],
        now: monday,
      );

      expect(planned.single.body, 'Почнува во 08:00');
    });

    test('custom entries are reminded about like any other class', () {
      final planned = planReminders(
        slots: const [],
        entries: [entry(room: 'Лаб 138')],
        exams: const [],
        now: monday,
      );

      expect(planned.single.title, 'Проектен состанок');
      expect(planned.single.at, DateTime(2026, 2, 2, 11, 45));
      expect(planned.single.body, contains('Лаб 138'));
    });
  });

  group('exam reminders', () {
    test('lands the evening before, not minutes before', () {
      final planned = planReminders(
        slots: const [],
        entries: const [],
        exams: [exam(date: '2026-02-05')],
        now: monday,
      );

      // 09:00 on the 5th, less 18 hours.
      expect(planned.single.at, DateTime(2026, 2, 4, 15));
      expect(planned.single.isExam, isTrue);
      expect(planned.single.title, contains('Анализа на софтверските барања'));
      expect(planned.single.body, contains('Барака 3.2'));
    });

    test('an exam that has passed is not scheduled', () {
      final planned = planReminders(
        slots: const [],
        entries: const [],
        exams: [exam(date: '2026-01-05')],
        now: monday,
      );

      expect(planned, isEmpty);
    });

    test('an exam beyond a month away waits for a later sync', () {
      final planned = planReminders(
        slots: const [],
        entries: const [],
        exams: [exam(date: '2026-06-01')],
        now: monday,
      );

      expect(planned, isEmpty);
    });
  });

  group('the set as a whole', () {
    test('is ordered soonest first', () {
      final planned = planReminders(
        slots: [slot(id: 1, day: 4), slot(id: 2, day: 1)],
        entries: const [],
        exams: [exam(date: '2026-02-04')],
        now: monday,
      );

      for (var i = 1; i < planned.length; i++) {
        expect(planned[i].at.isAfter(planned[i - 1].at), isTrue);
      }
    });

    test('stays inside what iOS will hold', () {
      final planned = planReminders(
        // 20 classes a day, every day — far more than a real timetable.
        slots: [
          for (var day = 0; day < 5; day++)
            for (var i = 0; i < 20; i++)
              slot(id: day * 100 + i, day: day, start: '08:0$i:00'),
        ],
        entries: const [],
        exams: const [],
        now: monday,
      );

      expect(planned.length, lessThanOrEqualTo(64));
    });

    test('ids are stable across identical plans and unique within one', () {
      List<int> idsAt(DateTime now) => planReminders(
            slots: [slot(id: 1, day: 0), slot(id: 2, day: 2)],
            entries: [entry(id: 1, day: 0)],
            exams: [exam(date: '2026-02-04')],
            now: now,
          ).map((r) => r.id).toList();

      final first = idsAt(monday);
      expect(idsAt(monday), first, reason: 'same timetable must reschedule in place');
      expect(first.toSet().length, first.length, reason: 'no two reminders share an id');
    });

    test('a custom entry and a slot with the same id do not collide', () {
      final planned = planReminders(
        slots: [slot(id: 7, day: 0, start: '08:00:00')],
        entries: [entry(id: 7, day: 0, start: '08:00:00')],
        exams: const [],
        now: monday,
      );

      expect(planned.length, 2);
      expect(planned[0].id, isNot(planned[1].id));
    });
  });
}
