import 'package:flutter_test/flutter_test.dart';

import 'package:finki_scheduler/core/utils/mk_date.dart';

void main() {
  // A Thursday, so the weekday cases are unambiguous.
  final today = DateTime(2026, 2, 5, 14, 30);

  group('mkRelativeDays', () {
    test('names the day itself rather than counting to it', () {
      expect(mkRelativeDays('2026-02-05', from: today), 'Денес');
      expect(mkRelativeDays('2026-02-06', from: today), 'Утре');
    });

    test('counts whole days from further out', () {
      expect(mkRelativeDays('2026-02-08', from: today), 'за 3 дена');
      expect(mkRelativeDays('2026-03-05', from: today), 'за 28 дена');
    });

    test('counts calendar days, not 24-hour blocks', () {
      // Just after midnight is still "tomorrow" from a mid-afternoon today.
      expect(mkRelativeDays('2026-02-06', from: DateTime(2026, 2, 5, 23, 59)), 'Утре');
    });

    test('goes quiet once the date is behind us', () {
      expect(mkRelativeDays('2026-02-04', from: today), isNull);
      expect(mkRelativeDays('2025-12-31', from: today), isNull);
    });

    test('goes quiet on a date it cannot read', () {
      expect(mkRelativeDays('some day', from: today), isNull);
      expect(mkRelativeDays('2026-13-01', from: today), isNull);
    });
  });

  group('counted nouns', () {
    test('exams follow the same rule', () {
      expect(mkExamCount(1), '1 испит');
      expect(mkExamCount(3), '3 испити');
      expect(mkExamCount(21), '21 испит');
      expect(mkExamCount(11), '11 испити');
    });
  });
}
