import 'package:flutter_test/flutter_test.dart';

import 'package:finki_scheduler/core/utils/mk_date.dart';

void main() {
  group('mkDuration', () {
    test('reads as minutes under an hour', () {
      expect(mkDuration('08:00', '08:45'), '45мин');
    });

    test('drops the minutes on a whole hour', () {
      expect(mkDuration('08:00', '10:00'), '2ч');
    });

    test('combines hours and minutes', () {
      expect(mkDuration('08:00', '09:45'), '1ч 45мин');
    });

    test('disappears rather than reading zero or negative', () {
      expect(mkDuration('08:00', '08:00'), isNull);
      expect(mkDuration('10:00', '09:00'), isNull);
      expect(mkDuration('oops', '09:00'), isNull);
    });
  });

  group('mkDayMonth', () {
    test('splits an ISO date into day and short month', () {
      expect(mkDayMonth('2026-01-15'), ('15', 'јан'));
      expect(mkDayMonth('2026-09-03'), ('3', 'сеп'));
    });

    test('passes through anything unparseable', () {
      expect(mkDayMonth('later'), ('later', null));
    });
  });
}
