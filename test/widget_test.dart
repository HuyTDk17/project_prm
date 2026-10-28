import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_prm393/app.dart';
import 'package:project_prm393/features/auth/data/auth_repository.dart';
import 'package:project_prm393/features/home/data/video_repository.dart';

void main() {
  // WT-01: a guest can open Login from Home, and "Log in" with empty fields
  // shows the validation messages.
  testWidgets('Guest opens Login and sees validation messages', (tester) async {
    // The in-memory mocks keep the test independent from Firebase.
    await tester.pumpWidget(MiniTubeApp(
      authRepository: MockAuthRepository(),
      videoRepository: MockVideoRepository(),
    ));
    // Home is public: let the mock feed finish loading (900 ms).
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.byKey(const Key('appbar_login')));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);

    final loginButton = find.widgetWithText(FilledButton, 'Log in');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pump();

    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Password must be 6-32 characters.'), findsOneWidget);
  });
}
