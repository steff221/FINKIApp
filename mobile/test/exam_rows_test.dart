import 'package:flutter_test/flutter_test.dart';

import 'package:finki_scheduler/features/exams/exam_rows.dart';
import 'package:finki_scheduler/models/models.dart';

int _nextId = 1;

Exam exam(String subject, String date, {String? start}) => Exam(
      id: _nextId++,
      session: 'Јунска',
      subjectName: subject,
      date: date,
      startTime: start,
      endTime: null,
      rooms: null,
      note: null,
    );

/// The session as the student reads it, top to bottom.
List<String> outline(List<ExamRow> rows) => rows
    .map((r) => switch (r) {
          ExamDateRow(:final date, :final count, :final past) =>
            'date $date ×$count${past ? ' (past)' : ''}',
          ExamCardRow(:final exam, :final highlight) =>
            '  ${exam.subjectName}${highlight ? ' *' : ''}',
          ExamNoticeRow(:final text) => 'notice $text',
          ExamPastRow(:final count, :final expanded, :final toggleable) =>
            'past ×$count expanded=$expanded toggleable=$toggleable',
        })
    .toList();

void main() {
  const today = '2026-02-05';
  final now = DateTime(2026, 2, 5, 9);

  group('buildExamRows', () {
    test('leads with what is ahead and folds away what is behind', () {
      final rows = buildExamRows(
        [
          exam('Веб програмирање', '2026-01-20'),
          exam('Калкулус 1', '2026-02-08'),
          exam('Алгоритми', '2026-02-20'),
        ],
        today: today,
        showPast: false,
        now: now,
      );

      expect(outline(rows), [
        'date 2026-02-08 ×1',
        '  Калкулус 1 *',
        'date 2026-02-20 ×1',
        '  Алгоритми',
        'past ×1 expanded=false toggleable=true',
      ]);
    });

    test('opening the fold appends the past, most recent first', () {
      final exams = [
        exam('Калкулус 1', '2026-02-08'),
        exam('Веб програмирање', '2026-01-20'),
        exam('Бази на податоци', '2026-01-28'),
      ];
      final rows =
          buildExamRows(exams, today: today, showPast: true, now: now);

      expect(outline(rows), [
        'date 2026-02-08 ×1',
        '  Калкулус 1 *',
        'past ×2 expanded=true toggleable=true',
        'date 2026-01-28 ×1 (past)',
        '  Бази на податоци',
        'date 2026-01-20 ×1 (past)',
        '  Веб програмирање',
      ]);
    });

    test('a finished session opens on the past and says why', () {
      final rows = buildExamRows(
        [exam('Веб програмирање', '2026-01-20')],
        today: today,
        showPast: false,
        now: now,
      );

      expect(outline(rows), [
        'notice Нема претстојни испити во оваа сесија',
        // Nothing to fold back to, so the row is a heading rather than a toggle.
        'past ×1 expanded=true toggleable=false',
        'date 2026-01-20 ×1 (past)',
        '  Веб програмирање',
      ]);
    });

    test('only the nearest date ahead counts down', () {
      final rows = buildExamRows(
        [
          exam('Калкулус 1', '2026-02-08'),
          exam('Алгоритми', '2026-02-20'),
        ],
        today: today,
        showPast: false,
        now: now,
      );
      final dates = rows.whereType<ExamDateRow>().toList();

      expect(dates.first.countdown, 'за 3 дена');
      expect(dates.first.highlight, isTrue);
      expect(dates.last.countdown, isNull);
      expect(dates.last.highlight, isFalse);
    });

    test("today's exams are still ahead, and read as today", () {
      final rows = buildExamRows(
        [exam('Калкулус 1', today)],
        today: today,
        showPast: false,
        now: now,
      );

      expect(rows.whereType<ExamDateRow>().single.countdown, 'Денес');
      expect(rows.whereType<ExamDateRow>().single.past, isFalse);
      expect(rows.whereType<ExamPastRow>(), isEmpty);
    });

    test('a day runs in time order, with untimed exams last', () {
      final rows = buildExamRows(
        [
          exam('Без термин', '2026-02-08'),
          exam('Попладне', '2026-02-08', start: '14:00'),
          exam('Наутро', '2026-02-08', start: '08:00'),
        ],
        today: today,
        showPast: false,
        now: now,
      );

      expect(outline(rows), [
        'date 2026-02-08 ×3',
        '  Наутро *',
        '  Попладне *',
        '  Без термин *',
      ]);
    });

    test('an empty session produces no rows at all', () {
      expect(buildExamRows([], today: today, showPast: false, now: now), isEmpty);
    });
  });
}
