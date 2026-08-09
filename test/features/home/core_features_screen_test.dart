import 'package:file_explorer/app/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: container.read(appRouterProvider),
        ),
      ),
    );
    container.read(appRouterProvider).go(AppRoutes.coreFeatures);
    await tester.pumpAndSettle();
  }

  testWidgets('tapping a feature card expands its description', (tester) async {
    await pumpScreen(tester);

    final descriptionFinder = find.textContaining('View images, play videos');
    expect(descriptionFinder, findsOneWidget);

    final collapsed = tester.widget<Text>(descriptionFinder);
    expect(collapsed.maxLines, 3);
    expect(collapsed.overflow, TextOverflow.ellipsis);

    await tester.tap(find.text('Built-in viewers'));
    await tester.pumpAndSettle();

    final expanded = tester.widget<Text>(descriptionFinder);
    expect(expanded.maxLines, isNull);
    expect(expanded.overflow, isNull);
  });

  testWidgets('tapping a feature card again collapses its description',
      (tester) async {
    await pumpScreen(tester);

    final descriptionFinder = find.textContaining('View images, play videos');

    await tester.tap(find.text('Built-in viewers'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(descriptionFinder).maxLines, isNull);

    await tester.tap(find.text('Built-in viewers'));
    await tester.pumpAndSettle();

    final collapsed = tester.widget<Text>(descriptionFinder);
    expect(collapsed.maxLines, 3);
    expect(collapsed.overflow, TextOverflow.ellipsis);
  });

  testWidgets('each card toggles independently', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Built-in viewers'));
    await tester.pumpAndSettle();

    final expanded = tester
        .widget<Text>(find.textContaining('View images, play videos'));
    expect(expanded.maxLines, isNull);

    final untouched = tester
        .widget<Text>(find.textContaining('Queue copy, move, rename'));
    expect(untouched.maxLines, 3);
  });
}