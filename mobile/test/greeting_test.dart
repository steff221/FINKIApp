import 'package:flutter_test/flutter_test.dart';

import 'package:finki_scheduler/core/utils/mk_date.dart';

void main() {
  group('mkGreeting', () {
    test('greets by first name at each time of day', () {
      expect(mkGreeting(DateTime(2026, 7, 26, 8), name: 'Стефан'), 'Добро утро, Стефан');
      expect(mkGreeting(DateTime(2026, 7, 26, 14), name: 'Стефан'), 'Добар ден, Стефан');
      expect(mkGreeting(DateTime(2026, 7, 26, 21), name: 'Стефан'), 'Добра вечер, Стефан');
    });

    test('uses only the first word of a full name', () {
      expect(mkGreeting(DateTime(2026, 7, 26, 8), name: 'Стефан Перовски'),
          'Добро утро, Стефан');
    });

    test('falls back to the plain greeting without a name', () {
      expect(mkGreeting(DateTime(2026, 7, 26, 8)), 'Добро утро');
      expect(mkGreeting(DateTime(2026, 7, 26, 8), name: ''), 'Добро утро');
      expect(mkGreeting(DateTime(2026, 7, 26, 8), name: '   '), 'Добро утро');
    });
  });
}
