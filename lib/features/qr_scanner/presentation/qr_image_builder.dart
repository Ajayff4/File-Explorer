import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Direction of the gradient applied to QR modules when [useGradient] is on.
enum QrGradientDirection { horizontal, vertical, diagonal }

/// Visual style of the QR modules (the "tiles").
enum QrTileStyle { square, rounded, dot }

/// Renders a fully customizable QR code to PNG bytes.
///
/// Supports solid colors, two-color linear gradients (applied to the modules
/// and finder eyes), an optional center logo, rounded/circular modules, a
/// background color (or transparency) and configurable error correction.
///
/// The QR is rendered with a quiet zone so the result stays scannable even
/// after the center logo is overlaid.
Future<Uint8List> generateQrPng({
  required String data,
  required int size,
  QrGradientDirection gradientDirection = QrGradientDirection.diagonal,
  Color? foregroundColor,
  Color? gradientStart,
  Color? gradientEnd,
  Color? backgroundColor,
  bool useGradient = false,
  QrTileStyle tileStyle = QrTileStyle.square,
  ui.Image? logo,
  double logoFraction = 0.22,
  int errorCorrectionLevel = QrErrorCorrectLevel.M,
}) async {
  final validation = QrValidator.validate(
    data: data,
    version: QrVersions.auto,
    errorCorrectionLevel: errorCorrectionLevel,
  );
  if (!validation.isValid) {
    throw Exception('Could not encode QR code: ${validation.error}');
  }
  final qrCode = validation.qrCode;
  if (qrCode == null) {
    throw Exception('Could not encode QR code');
  }

  final quietZone = (size * 0.1).round();
  final innerSize = size - quietZone * 2;

  // For gradients we first paint the QR as a white mask so we can recolor it
  // with a gradient shader via a dstIn blend.
  final baseColor = useGradient ? Colors.white : (foregroundColor ?? Colors.black);
  final qrImage = QrImage(qrCode);
  final matrixImage = await _renderQrMatrix(
    qrImage,
    innerSize,
    tileStyle,
    baseColor,
  );

  ui.Image colorized;
  if (useGradient && gradientStart != null && gradientEnd != null) {
    colorized = await _applyGradient(
      matrixImage,
      gradientStart,
      gradientEnd,
      gradientDirection,
      innerSize,
    );
    matrixImage.dispose();
  } else {
    colorized = matrixImage;
  }

  final bytes = await _compose(
    backgroundColor: backgroundColor,
    qr: colorized,
    innerSize: innerSize,
    quietZone: quietZone,
    logo: logo,
    logoFraction: logoFraction,
  );
  colorized.dispose();
  return bytes;
}

/// Renders the QR module matrix to an image using the requested tile style.
///
/// Finder patterns ("eyes") are drawn as styled rounded frames with a filled
/// center; the remaining dark modules are drawn as squares, rounded squares or
/// dots. Everything is painted in a single [color] so the result can be used
/// directly (solid color) or as a white mask for gradient recoloring.
Future<ui.Image> _renderQrMatrix(
  QrImage qr,
  int size,
  QrTileStyle style,
  Color color,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..color = color;
  final n = qr.moduleCount;
  final module = size / n;

  final tileRadius = switch (style) {
    QrTileStyle.square => 0.0,
    QrTileStyle.rounded => module * 0.3,
    QrTileStyle.dot => module * 0.5,
  };

  for (var row = 0; row < n; row++) {
    for (var col = 0; col < n; col++) {
      if (!qr.isDark(row, col)) continue;
      if (_isInFinder(row, col, n)) continue;
      final x = col * module;
      final y = row * module;
      if (style == QrTileStyle.dot) {
        canvas.drawCircle(
          Offset(x + module / 2, y + module / 2),
          tileRadius * 0.9,
          paint,
        );
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, module, module),
            Radius.circular(tileRadius),
          ),
          paint,
        );
      }
    }
  }

  for (final finder in _finderOrigins(n)) {
    _drawFinder(
      canvas,
      finder.x * module,
      finder.y * module,
      module,
      style,
      color,
    );
  }

  return recorder.endRecording().toImage(size, size);
}

bool _isInFinder(int row, int col, int n) {
  return _inBox(row, col, 0, 0, n) ||
      _inBox(row, col, 0, n - 7, n) ||
      _inBox(row, col, n - 7, 0, n);
}

bool _inBox(int row, int col, int x, int y, int n) {
  return row >= y && row < y + 7 && col >= x && col < x + 7;
}

List<_Point> _finderOrigins(int n) => [
      const _Point(0, 0),
      _Point(0, n - 7),
      _Point(n - 7, 0),
    ];

void _drawFinder(
  Canvas canvas,
  double x,
  double y,
  double m,
  QrTileStyle style,
  Color color,
) {
  final paint = Paint()..color = color;
  final eyeRadius = switch (style) {
    QrTileStyle.square => m * 0.15,
    QrTileStyle.rounded => m * 0.35,
    QrTileStyle.dot => m * 0.5,
  };

  // Outer 7x7 frame (1 module thick) via an even-odd fill so it stays inside
  // the finder box and keeps a clean rounded border.
  final outer = Rect.fromLTWH(x, y, 7 * m, 7 * m);
  final inner = Rect.fromLTWH(x + m, y + m, 5 * m, 5 * m);
  final frame = Path()
    ..fillType = ui.PathFillType.evenOdd
    ..addRRect(
      RRect.fromRectAndRadius(outer, Radius.circular(eyeRadius)),
    )
    ..addRRect(
      RRect.fromRectAndRadius(inner, Radius.circular(eyeRadius * 0.7)),
    );
  canvas.drawPath(frame, paint);

  // Filled 3x3 center.
  final center = Rect.fromLTWH(x + 2 * m, y + 2 * m, 3 * m, 3 * m);
  canvas.drawRRect(
    RRect.fromRectAndRadius(center, Radius.circular(eyeRadius * 0.6)),
    paint,
  );
}

class _Point {
  const _Point(this.x, this.y);
  final int x;
  final int y;
}

Future<ui.Image> _applyGradient(
  ui.Image mask,
  Color start,
  Color end,
  QrGradientDirection direction,
  int innerSize,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final rect =
      Rect.fromLTWH(0, 0, innerSize.toDouble(), innerSize.toDouble());
  final shader = LinearGradient(
    begin: _gradientBegin(direction),
    end: _gradientEnd(direction),
    colors: [start, end],
  ).createShader(rect);
  canvas.drawRect(rect, Paint()..shader = shader);
  canvas.drawImage(mask, Offset.zero, Paint()..blendMode = ui.BlendMode.dstIn);
  return recorder.endRecording().toImage(innerSize, innerSize);
}

Future<Uint8List> _compose({
  required Color? backgroundColor,
  required ui.Image qr,
  required int innerSize,
  required int quietZone,
  required ui.Image? logo,
  required double logoFraction,
}) async {
  final size = innerSize + quietZone * 2;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  if (backgroundColor != null) {
    canvas.drawColor(backgroundColor, ui.BlendMode.src);
  }

  canvas.drawImage(
    qr,
    Offset(quietZone.toDouble(), quietZone.toDouble()),
    Paint(),
  );

  if (logo != null) {
    final logoSize = innerSize * logoFraction;
    final center = size / 2;
    final backing = Rect.fromLTWH(
      center - logoSize / 2,
      center - logoSize / 2,
      logoSize,
      logoSize,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        backing,
        Radius.circular(logoSize * 0.18),
      ),
      Paint()..color = Colors.white,
    );

    final src = Rect.fromLTWH(
      0,
      0,
      logo.width.toDouble(),
      logo.height.toDouble(),
    );
    final pad = logoSize * 0.12;
    final boxW = logoSize - pad * 2;
    final boxH = logoSize - pad * 2;
    final scale = math.min(boxW / src.width, boxH / src.height);
    final drawW = src.width * scale;
    final drawH = src.height * scale;
    final dst = Rect.fromLTWH(
      center - drawW / 2,
      center - drawH / 2,
      drawW,
      drawH,
    );
    canvas.drawImageRect(
      logo,
      src,
      dst,
      Paint()..filterQuality = ui.FilterQuality.high,
    );
  }

  final image = await recorder.endRecording().toImage(size, size);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return byteData!.buffer.asUint8List();
}

Alignment _gradientBegin(QrGradientDirection direction) {
  return switch (direction) {
    QrGradientDirection.horizontal => Alignment.centerLeft,
    QrGradientDirection.vertical => Alignment.topCenter,
    QrGradientDirection.diagonal => Alignment.topLeft,
  };
}

Alignment _gradientEnd(QrGradientDirection direction) {
  return switch (direction) {
    QrGradientDirection.horizontal => Alignment.centerRight,
    QrGradientDirection.vertical => Alignment.bottomCenter,
    QrGradientDirection.diagonal => Alignment.bottomRight,
  };
}
