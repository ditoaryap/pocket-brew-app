import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_brew/app/app.dart';
import 'package:pocket_brew/features/quick_brew/quick_brew_screen.dart';

void main() {
  testWidgets('Pocket Brew renders Home Morning Ritual & 5-tab Floating Dock', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: PocketBrewApp()));
    await tester.pumpAndSettle();

    expect(find.text('Hot V60'), findsWidgets);
    expect(find.text('Japanese Iced'), findsWidgets);
    expect(find.text('Edit Tahapan Seduh'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Beans'), findsOneWidget);
    expect(find.text('Brew'), findsOneWidget);
    expect(find.text('Log'), findsOneWidget);
    expect(find.text('Alat'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Belajar Seduh'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Belajar Seduh'), findsOneWidget);

    // Tap "Brew" tab to open Brew screen and verify live g/ml/oz pill
    await tester.tap(find.text('Brew'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(QuickBrewScreen), matching: find.text('Brew')),
      findsOneWidget,
    );
    expect(find.text('ml'), findsOneWidget);
    expect(find.text('oz'), findsOneWidget);

    // Switch to Japanese Iced mode inside QuickBrewScreen and verify 2-option Ice Order!
    await tester.tap(
      find.descendant(
        of: find.byType(QuickBrewScreen),
        matching: find.text('Japanese Iced'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Es Duluan (Server)'), findsOneWidget);
    expect(find.text('Seduh Dulu → Es'), findsOneWidget);
  });
}
