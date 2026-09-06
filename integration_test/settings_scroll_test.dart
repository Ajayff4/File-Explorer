import 'package:file_explorer/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('settings list keeps scrolling after drag reversal',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FileExplorerApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Open settings via the bottom nav bar.
    await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final list = find.byType(ListView).first;
    expect(list, findsOneWidget);

    double pixels() =>
        tester.state<ScrollableState>(find.byType(Scrollable).first).position.pixels;
    final maxExtent = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .maxScrollExtent;
    expect(maxExtent, greaterThan(0),
        reason: 'settings content must overflow on this device');

    // Drag down, then reverse up mid-gesture without lifting, then release.
    final center = tester.getCenter(list);
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(0, 250));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, -350));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // A fresh drag must still move the list.
    final before = pixels();
    await tester.drag(list, const Offset(0, -300));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(pixels(), isNot(equals(before)),
        reason: 'settings ListView stuck after drag reversal');
  });
}
