import 'package:flutter_test/flutter_test.dart';

import 'package:finki_scheduler/models/models.dart';

void main() {
  group('TimetableFilters day-of-week filtering', () {
    test('selecting a day adds it to the API query', () {
      final filters = const TimetableFilters().copyWith(dayOfWeek: () => 2);
      expect(filters.dayOfWeek, 2);
      expect(filters.activeCount, 1);
      expect(filters.toQuery()['dayOfWeek'], '2');
    });

    test('clearing the day removes it from the API query', () {
      const selected = TimetableFilters(dayOfWeek: 4);
      final cleared = selected.copyWith(dayOfWeek: () => null);
      expect(cleared.dayOfWeek, isNull);
      expect(cleared.isEmpty, isTrue);
      expect(cleared.toQuery().containsKey('dayOfWeek'), isFalse);
    });

    test('clearing the day keeps other filters intact', () {
      const filters = TimetableFilters(dayOfWeek: 1, year: 2);
      final cleared = filters.copyWith(dayOfWeek: () => null);
      expect(cleared.year, 2);
      expect(cleared.activeCount, 1);
    });
  });
}
