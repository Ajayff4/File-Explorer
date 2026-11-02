import 'dart:io';

import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/media/domain/text_file_encoding.dart';
import 'package:file_explorer/features/media/presentation/text_file_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDirectory;
  late File file;
  late FileSystemEntry entry;

  setUpAll(() {
    EditableText.debugDeterministicCursor = true;
  });

  tearDownAll(() {
    EditableText.debugDeterministicCursor = false;
  });

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('text_editor_test_');
    file = File('${tempDirectory.path}/notes.txt');
    await file.writeAsString('hello world');
    entry = FileSystemEntry(
      name: 'notes.txt',
      path: file.path,
      type: FileSystemEntryType.document,
      modifiedAt: DateTime.now(),
    );
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  Future<void> pumpFrames(WidgetTester tester) async {
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump(const Duration(milliseconds: 20));
      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: TextFileViewerScreen(entry: entry)),
    );
    for (var attempt = 0; attempt < 40; attempt++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump();
      if (find.byType(SelectableText).evaluate().isNotEmpty ||
          find.text('Empty file').evaluate().isNotEmpty ||
          find.text('Could not read file').evaluate().isNotEmpty) {
        return;
      }
    }
  }

  testWidgets('edits and saves a text file', (tester) async {
    await pumpScreen(tester);

    expect(find.text('hello world'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit'));
    await pumpFrames(tester);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'updated content');
    await pumpFrames(tester);

    await tester.tap(find.byTooltip('Save'));
    await pumpUntilFound(tester, find.text('File saved'));

    expect(file.readAsStringSync(), 'updated content');
    expect(find.text('File saved'), findsOneWidget);
    expect(find.text('Unsaved changes'), findsNothing);
  });

  testWidgets('discards edits when editing stops', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Edit'));
    await pumpFrames(tester);
    await tester.enterText(find.byType(TextField), 'do not save');
    await pumpFrames(tester);

    await tester.tap(find.byTooltip('Stop editing'));
    await pumpFrames(tester);
    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await pumpFrames(tester);

    expect(find.text('hello world'), findsOneWidget);
    expect(file.readAsStringSync(), 'hello world');
  });

  testWidgets('keeps editing when discard is cancelled', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Edit'));
    await pumpFrames(tester);
    await tester.enterText(find.byType(TextField), 'draft');
    await pumpFrames(tester);

    await tester.tap(find.byTooltip('Stop editing'));
    await pumpFrames(tester);
    await tester.tap(find.text('Keep editing'));
    await pumpFrames(tester);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('draft'), findsOneWidget);
  });

  testWidgets('loads and saves UTF-16 text with a BOM', (tester) async {
    file.writeAsBytesSync(
      encodeTextFile(
        'wide text',
        encoding: TextFileEncoding.utf16le,
        withBom: true,
      ),
    );
    await pumpScreen(tester);

    expect(find.text('wide text'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit'));
    await pumpFrames(tester);
    await tester.enterText(find.byType(TextField), 'wide text updated');
    await pumpFrames(tester);
    await tester.tap(find.byTooltip('Save'));
    await pumpUntilFound(tester, find.text('File saved'));

    final decoded = decodeTextFile(file.readAsBytesSync());
    expect(decoded.text, 'wide text updated');
    expect(decoded.encoding, TextFileEncoding.utf16le);
    expect(decoded.hasBom, isTrue);
  });

  testWidgets('can edit an empty file', (tester) async {
    file.writeAsStringSync('');
    await pumpScreen(tester);

    expect(find.text('Empty file'), findsOneWidget);

    await tester.tap(find.text('Edit file'));
    await pumpFrames(tester);
    await tester.enterText(find.byType(TextField), 'first line');
    await pumpFrames(tester);
    await tester.tap(find.byTooltip('Save'));
    await pumpUntilFound(tester, find.text('File saved'));

    expect(file.readAsStringSync(), 'first line');
  });
}
