import 'package:aldiafa/core/theme/app_theme.dart';
import 'package:aldiafa/features/auth/forgot_password_screen.dart';
import 'package:aldiafa/features/auth/login_screen.dart';
import 'package:aldiafa/features/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    // The test font draws every glyph as a full em square, so Arabic labels
    // measure far wider here than on a device; a phone-width surface would
    // report overflows that do not exist. Give the rows room.
    tester.view.physicalSize = const Size(2400, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Directionality(textDirection: TextDirection.rtl, child: child),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  }

  testWidgets('login asks for a phone only', (tester) async {
    await pump(tester, const LoginScreen());
    expect(find.text('رقم الجوال (05XXXXXXXX)'), findsOneWidget);
    expect(find.textContaining('البريد'), findsNothing);

    // A bad number must be refused before any network call.
    await tester.enterText(find.byType(TextFormField).first, '12345');
    await tester.enterText(find.byType(TextFormField).last, 'Passw0rd!');
    await tester.tap(find.text('تسجيل الدخول').last);
    await tester.pump();
    expect(find.text('أدخل رقم جوال سعودي صحيح (05XXXXXXXX)'), findsOneWidget);
  });

  testWidgets('register has no email field', (tester) async {
    await pump(tester, const RegisterScreen());
    expect(find.text('الاسم الكامل'), findsOneWidget);
    expect(find.text('رقم الجوال السعودي'), findsOneWidget);
    expect(find.text('كلمة المرور'), findsOneWidget);
    expect(find.textContaining('البريد'), findsNothing);
  });

  testWidgets('password reset asks for a phone only', (tester) async {
    await pump(tester, const ForgotPasswordScreen());
    expect(find.text('رقم الجوال'), findsOneWidget);
    expect(find.textContaining('البريد'), findsNothing);
  });
}
