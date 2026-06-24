import 'package:aldiafa/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots to the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AldiafaApp()));
    await tester.pump();

    // The splash tagline is shown while the auth state is resolving.
    expect(find.text('الضيافة'), findsWidgets);
  });
}
