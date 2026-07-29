import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finki_scheduler/core/theme/app_colors.dart';
import 'package:finki_scheduler/features/auth/login_screen.dart';

/// Pumped with the default theme on purpose: the app theme pulls Inter through
/// google_fonts, which tries to fetch over HTTP under `flutter test`.
Widget host() => const ProviderScope(child: MaterialApp(home: LoginScreen()));

void main() {
  setUp(() {
    // No Keychain in tests — every read resolves to null, so the auth
    // controller settles on "unauthenticated" without touching the network.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  testWidgets('both fields carry a persistent label', (tester) async {
    await tester.pumpWidget(host());
    expect(find.text('Е-пошта'), findsOneWidget);
    expect(find.text('Лозинка'), findsOneWidget);
  });

  testWidgets('the button is disabled until both fields have content',
      (tester) async {
    await tester.pumpWidget(host());
    FilledButton button() => tester.widget<FilledButton>(find.byType(FilledButton));

    expect(button().onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'student@finki.ukim.mk');
    await tester.pump();
    expect(button().onPressed, isNull, reason: 'password still empty');

    await tester.enterText(find.byType(TextField).last, 'secret123');
    await tester.pump();
    expect(button().onPressed, isNotNull);
  });

  testWidgets('an invalid address shows an inline error in the danger colour',
      (tester) async {
    await tester.pumpWidget(host());

    await tester.enterText(find.byType(TextField).first, 'student');
    await tester.enterText(find.byType(TextField).last, 'secret123');
    await tester.pump();
    await tester.tap(find.text('Најави се'));
    await tester.pump();

    final email = tester.widget<TextField>(find.byType(TextField).first);
    expect(email.decoration!.errorText, 'Внесете валидна е-пошта');
    expect(
      (email.decoration!.errorBorder as OutlineInputBorder).borderSide.color,
      AppColors.danger,
    );
    expect(find.text('Внесете валидна е-пошта'), findsOneWidget);

    // ...and it clears as soon as the student corrects it.
    await tester.enterText(find.byType(TextField).first, 'student@finki.ukim.mk');
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).decoration!.errorText,
      isNull,
    );
  });

  testWidgets('iOS input traits are set for Keychain autofill', (tester) async {
    await tester.pumpWidget(host());

    final email = tester.widget<TextField>(find.byType(TextField).first);
    expect(email.keyboardType, TextInputType.emailAddress);
    expect(email.autocorrect, isFalse);
    expect(email.textCapitalization, TextCapitalization.none);
    expect(email.textInputAction, TextInputAction.next);
    expect(email.autofillHints, contains(AutofillHints.username));

    final password = tester.widget<TextField>(find.byType(TextField).last);
    expect(password.obscureText, isTrue);
    expect(password.autofillHints, contains(AutofillHints.password));
    expect(password.textInputAction, TextInputAction.done);
    expect(find.byType(AutofillGroup), findsOneWidget);
  });

  testWidgets('the show/hide toggle flips secure entry', (tester) async {
    await tester.pumpWidget(host());
    expect(tester.widget<TextField>(find.byType(TextField).last).obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField).last).obscureText, isFalse);
  });

  testWidgets('the form scrolls so the keyboard cannot cover it', (tester) async {
    await tester.pumpWidget(host());
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('offers a way to create an account', (tester) async {
    await tester.pumpWidget(host());
    expect(find.text('Немате профил?'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Регистрирајте се'), findsOneWidget);
  });
}
