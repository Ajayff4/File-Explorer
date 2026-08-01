import 'package:flutter/services.dart';
import 'package:mime/mime.dart';

const _mediaActionsChannel =
    MethodChannel('com.ajayff4.fileexplorer/media_actions');

Future<void> shareLocalFile(String path, {String fallbackMimeType = '*/*'}) {
  return _mediaActionsChannel.invokeMethod<void>(
    'shareFile',
    {
      'path': path,
      'mimeType': lookupMimeType(path) ?? fallbackMimeType,
    },
  );
}

Future<void> openLocalFileWithSystem(
  String path, {
  String fallbackMimeType = '*/*',
}) {
  return _mediaActionsChannel.invokeMethod<void>(
    'openFile',
    {
      'path': path,
      'mimeType': lookupMimeType(path) ?? fallbackMimeType,
    },
  );
}
