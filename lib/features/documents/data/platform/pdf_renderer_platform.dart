import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PdfRenderException implements Exception {
  const PdfRenderException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PdfPageRenderer {
  const PdfPageRenderer();

  static const _channel = MethodChannel('com.ajayff4.fileexplorer/pdf');

  Future<int> getPageCount(String path) async {
    try {
      final count = await _channel.invokeMethod<int>(
        'getPageCount',
        {'path': path},
      );
      return count ?? 0;
    } on MissingPluginException {
      throw const PdfRenderException(
        'PDF preview is available on Android only',
      );
    } on PlatformException catch (error) {
      throw PdfRenderException(error.message ?? 'Could not open PDF');
    }
  }

  Future<Uint8List> renderPage(
    String path,
    int page, {
    required int width,
  }) async {
    try {
      final bytes = await _channel.invokeMethod<Uint8List>(
        'renderPage',
        {
          'path': path,
          'page': page,
          'width': width,
        },
      );
      if (bytes == null) {
        throw const PdfRenderException('Could not render PDF page');
      }
      return bytes;
    } on MissingPluginException {
      throw const PdfRenderException(
        'PDF preview is available on Android only',
      );
    } on PlatformException catch (error) {
      throw PdfRenderException(error.message ?? 'Could not render PDF page');
    }
  }

  Future<void> close() async {
    try {
      await _channel.invokeMethod<void>('close');
    } on MissingPluginException {
      // Nothing to release when the native renderer is unavailable.
    } on PlatformException {
      // Closing is best-effort; the activity releases the renderer too.
    }
  }
}

final pdfPageRendererProvider = Provider<PdfPageRenderer>((ref) {
  return const PdfPageRenderer();
});
