import 'package:file_explorer/features/history_backup/presentation/history_backup_controller.dart';
import 'package:file_explorer/features/settings/data/repositories/in_memory_settings_store.dart';
import 'package:file_explorer/features/settings/data/repositories/settings_store_provider.dart';
import 'package:file_explorer/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHistoryBackupController extends HistoryBackupController {
  _FakeHistoryBackupController([this._state = const HistoryBackupState(isWorking: true)]);

  final HistoryBackupState _state;

  @override
  HistoryBackupState build() => _state;
}

Widget _harness({
  bool withHorizontalAncestor = false,
  HistoryBackupState historyState = const HistoryBackupState(isWorking: true),
}) {
  Widget screen = const SettingsScreen();
  if (withHorizontalAncestor) {
    // Mirrors _SwipeEdgeFeedback in window_manager.dart (multi-window case).
    screen = GestureDetector(
      onHorizontalDragEnd: (_) {},
      child: screen,
    );
  }
  return ProviderScope(
    overrides: [
      settingsStoreProvider.overrideWithValue(InMemorySettingsStore()),
      historyBackupControllerProvider
          .overrideWith(() => _FakeHistoryBackupController(historyState)),
    ],
    child: MaterialApp(home: screen),
  );
}

// pumpAndSettle never finishes (spinner animates forever), so advance
// the clock manually.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
double _pixels(WidgetTester tester) {
  final state = tester.state<ScrollableState>(find.byType(Scrollable).first);
  return state.position.pixels;
}

Future<void> _pumpSettings(
  WidgetTester tester, {
  bool withHorizontalAncestor = false,
}) async {
  // Phone viewport (matches RMX3031 ~360dp). Fake backup state keeps the
  // wide-trailing layout bug out of this mechanics test.
  tester.view.physicalSize = const Size(1080, 2220);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    _harness(withHorizontalAncestor: withHorizontalAncestor),
  );
  await _settle(tester);
  final position =
      tester.state<ScrollableState>(find.byType(Scrollable).first).position;
  expect(position.maxScrollExtent, greaterThan(0),
      reason: 'test needs overflowing content');
}

Future<void> _dragDownThenReverseUp(WidgetTester tester) async {
  final center = tester.getCenter(find.byType(ListView));
  final gesture = await tester.startGesture(center);
  await gesture.moveBy(const Offset(0, 250));
  await tester.pump(const Duration(milliseconds: 100));
  // Reverse direction mid-gesture without lifting the finger.
  await gesture.moveBy(const Offset(0, -350));
  await tester.pump(const Duration(milliseconds: 100));
  await gesture.up();
  await _settle(tester);
}

Future<void> _expectStillScrollable(WidgetTester tester) async {
  final before = _pixels(tester);
  await tester.drag(find.byType(ListView), const Offset(0, -300));
  await _settle(tester);
  final after = _pixels(tester);
  expect(after, isNot(equals(before)),
      reason: 'ListView stuck after drag reversal: $before -> $after');
}

void main() {
  testWidgets('settings list scrolls after drag-down-then-reverse-up',
      (tester) async {
    await _pumpSettings(tester);
    expect(_pixels(tester), 0);
    await _dragDownThenReverseUp(tester);
    await _expectStillScrollable(tester);
  });

  testWidgets('settings list scrolls with horizontal-drag ancestor',
      (tester) async {
    await _pumpSettings(tester, withHorizontalAncestor: true);
    expect(_pixels(tester), 0);
    await _dragDownThenReverseUp(tester);
    await _expectStillScrollable(tester);
  });

  testWidgets('backup card trailing shrink-wraps at phone width',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    // unavailable state shows the wide GlowButton trailing + long subtitle:
    // must not throw ListTile's full-width-trailing assertion.
    await tester.pumpWidget(_harness(
      historyState: const HistoryBackupState(unavailable: true),
    ));
    await tester.pumpAndSettle();
    // Sliver builds lazily: bring the card into view first.
    await tester.dragUntilVisible(
      find.text('Back up now'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    final buttonWidth = tester.getSize(find.text('Back up now')).width;
    expect(buttonWidth, lessThan(360));
  });
}
