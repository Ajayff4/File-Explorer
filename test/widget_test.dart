import 'package:file_explorer/app/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('starts on the file manager dashboard', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: EsFileExplorerApp()));

    expect(find.text('File Explorer'), findsWidgets);
    expect(find.text('Internal storage'), findsOneWidget);
    expect(find.text('Images'), findsOneWidget);
  });
}
