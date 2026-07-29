import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finki_scheduler/core/theme/app_colors.dart';
import 'package:finki_scheduler/features/auth/register_screen.dart';

/// Pumped with the default theme on purpose: the app theme pulls Inter through
/// google_fonts, which tries to fetch over HTTP under `flutter test`.
Widget host() => const ProviderScope(child: MaterialApp(home: RegisterScreen()));

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  TextField fieldAt(WidgetTester tester, int i) =>
      tester.widgetList<TextField>(find.byType(TextField)).elementAt(i);

  /// Field order on screen: name, e-mail, password, confirmation.
  Future<void> fill(WidgetTester tester,
      {String name = 'Стефан',
      required String email,
      required String password,
      required String confirm}) async {
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), name);
    await tester.enterText(fields.at(1), email);
    await tester.enterText(fields.at(2), password);
    await tester.enterText(fields.at(3), confirm);
    await tester.pump();
  }

  testWidgets('asks for a name, e-mail, password and a confirmation', (tester) async {
    await tester.pumpWidget(host());
    expect(find.text('Име'), findsOneWidget);
    expect(find.text('Е-пошта'), findsOneWidget);
    expect(find.text('Лозинка'), findsOneWidget);
    expect(find.text('Потврди лозинка'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(4));
  });

  testWidgets('the button is disabled until every field has content',
      (tester) async {
    await tester.pumpWidget(host());
    FilledButton button() => tester.widget<FilledButton>(find.byType(FilledButton));

    expect(button().onPressed, isNull);

    await fill(tester,
        name: '', email: 'student@finki.ukim.mk', password: 'secret123', confirm: 'secret123');
    expect(button().onPressed, isNull, reason: 'name still empty');

    await fill(tester, email: 'student@finki.ukim.mk', password: 'secret123', confirm: '');
    expect(button().onPressed, isNull, reason: 'confirmation still empty');

    await fill(tester,
        email: 'student@finki.ukim.mk', password: 'secret123', confirm: 'secret123');
    expect(button().onPressed, isNotNull);
  });

  testWidgets('a one-character name is rejected', (tester) async {
    await tester.pumpWidget(host());
    await fill(tester,
        name: 'С', email: 'student@finki.ukim.mk', password: 'secret123', confirm: 'secret123');
    await tester.tap(find.text('Креирај профил'));
    await tester.pump();

    expect(fieldAt(tester, 0).decoration!.errorText, 'Внесете го вашето име');
  });

  testWidgets('a short password is rejected before the request goes out',
      (tester) async {
    await tester.pumpWidget(host());
    await fill(tester, email: 'student@finki.ukim.mk', password: 'short', confirm: 'short');
    await tester.tap(find.text('Креирај профил'));
    await tester.pump();

    expect(fieldAt(tester, 2).decoration!.errorText,
        'Лозинката мора да има барем 8 знаци');
    expect(
      (fieldAt(tester, 2).decoration!.errorBorder as OutlineInputBorder).borderSide.color,
      AppColors.danger,
    );
  });

  testWidgets('mismatched passwords are caught on the confirmation field',
      (tester) async {
    await tester.pumpWidget(host());
    await fill(tester,
        email: 'student@finki.ukim.mk', password: 'secret123', confirm: 'secret124');
    await tester.tap(find.text('Креирај профил'));
    await tester.pump();

    expect(fieldAt(tester, 3).decoration!.errorText, 'Лозинките не се совпаѓаат');
    expect(fieldAt(tester, 2).decoration!.errorText, isNull);

    // Correcting the confirmation clears it.
    await tester.enterText(find.byType(TextField).at(3), 'secret123');
    await tester.pump();
    expect(fieldAt(tester, 3).decoration!.errorText, isNull);
  });

  testWidgets('an invalid address is caught on the e-mail field', (tester) async {
    await tester.pumpWidget(host());
    await fill(tester, email: 'student', password: 'secret123', confirm: 'secret123');
    await tester.tap(find.text('Креирај профил'));
    await tester.pump();

    expect(fieldAt(tester, 1).decoration!.errorText, 'Внесете валидна е-пошта');
  });

  testWidgets('both password fields ask iOS for a new-password suggestion',
      (tester) async {
    await tester.pumpWidget(host());

    expect(fieldAt(tester, 2).obscureText, isTrue);
    expect(fieldAt(tester, 2).autofillHints, contains(AutofillHints.newPassword));
    expect(fieldAt(tester, 3).obscureText, isTrue);
    expect(fieldAt(tester, 3).autofillHints, contains(AutofillHints.newPassword));
    expect(find.byType(AutofillGroup), findsOneWidget);
  });

  testWidgets('the toggle reveals both password fields at once', (tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    expect(fieldAt(tester, 2).obscureText, isFalse);
    expect(fieldAt(tester, 3).obscureText, isFalse);
  });
}
