import 'package:file_explorer/features/documents/data/platform/pdf_renderer_platform.dart';
import 'package:file_explorer/features/documents/domain/document_format.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.ajayff4.fileexplorer/pdf');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('reads the page count from the native renderer', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return 12;
    });

    final count =
        await const PdfPageRenderer().getPageCount('/docs/report.pdf');

    expect(count, 12);
    expect(calls.single.method, 'getPageCount');
    expect(calls.single.arguments, {'path': '/docs/report.pdf'});
  });

  test('renders a page at the requested width', () async {
    final bytes = Uint8List.fromList([137, 80, 78, 71]);
    MethodCall? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      received = call;
      return bytes;
    });

    final rendered = await const PdfPageRenderer().renderPage(
      '/docs/report.pdf',
      2,
      width: 1080,
    );

    expect(rendered, bytes);
    expect(received?.method, 'renderPage');
    expect(received?.arguments, {
      'path': '/docs/report.pdf',
      'page': 2,
      'width': 1080,
    });
  });

  test('surfaces native renderer failures', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'pdf_error', message: 'Encrypted PDF');
    });

    expect(
      () => const PdfPageRenderer().getPageCount('/docs/report.pdf'),
      throwsA(
        isA<PdfRenderException>().having(
          (error) => error.message,
          'message',
          'Encrypted PDF',
        ),
      ),
    );
  });

  test('reports unsupported hosts when the channel is missing', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw MissingPluginException();
    });

    expect(
      () => const PdfPageRenderer().getPageCount('/docs/report.pdf'),
      throwsA(
        isA<PdfRenderException>().having(
          (error) => error.message,
          'message',
          contains('Android'),
        ),
      ),
    );
  });

  test('detects PDF and EPUB document paths', () {
    expect(isPdfFile('/books/Manual.PDF'), isTrue);
    expect(isPdfFile('/books/Manual.epub'), isFalse);
    expect(isEpubFile('/books/Novel.epub'), isTrue);
    expect(isEpubFile('/books/Novel.pdf'), isFalse);
  });
}
