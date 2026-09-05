import 'dart:async';
import 'dart:math' as math;

import 'package:file_explorer/features/media/data/audio_visualizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Live audio spectrum shown in place of the static artwork while audio plays.
///
/// Subscribes to native FFT frames when [active] and the platform streams
/// them; with [simulated] (ROMs like ColorOS that block output-mix capture)
/// the bars dance to a synthesized beat-synced signal instead. When paused
/// (or when no frame has arrived yet) the bars ease down to a flat glowing
/// baseline instead of freezing mid-frame.
class AudioSpectrum extends StatefulWidget {
  const AudioSpectrum({
    super.key,
    required this.active,
    required this.color,
    this.simulated = false,
  });

  final bool active;
  final Color color;
  final bool simulated;

  @override
  State<AudioSpectrum> createState() => _AudioSpectrumState();
}

class _AudioSpectrumState extends State<AudioSpectrum>
    with SingleTickerProviderStateMixin {
  final SpectrumSmoother _smoother = SpectrumSmoother();
  StreamSubscription<List<double>>? _subscription;
  late final Ticker _ticker;
  bool _settled = true;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _syncSubscription();
  }

  @override
  void didUpdateWidget(covariant AudioSpectrum oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _syncSubscription();
  }

  void _syncSubscription() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    if (widget.active) {
      _settled = false;
      _subscription = AudioVisualizer.fftFrames().listen(
        (frame) {
          if (!mounted) return;
          _smoother.update(frame);
          _settled = false;
          setState(() {});
        },
        onError: (_) {},
        cancelOnError: false,
      );
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    if (widget.active && widget.simulated) {
      _smoother.update(_syntheticFrame(elapsed));
      _settled = false;
      setState(() {});
      return;
    }
    if (widget.active || _settled) return;
    _settled = _smoother.decay();
    setState(() {});
  }

  /// Beat-like pseudo-spectrum for ROMs where native capture is blocked:
  /// layered sines per band under a slow breathing energy envelope.
  List<double> _syntheticFrame(Duration elapsed) {
    final t = elapsed.inMilliseconds / 1000.0;
    final energy = 0.55 + 0.45 * math.sin(t * 0.9);
    return List<double>.generate(_smoother.levels.length, (i) {
      final wave = (0.5 +
              0.5 * math.sin(t * 2.3 + i * 0.55) * math.sin(t * 0.7 + i * 1.7))
          .clamp(0.0, 1.0);
      // Bass-heavy tilt like real music spectra.
      final tilt = 1.0 - 0.55 * (i / _smoother.levels.length);
      return (energy * (0.15 + 0.85 * wave) * tilt).clamp(0.0, 1.0);
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SpectrumPainter(levels: _smoother.levels, color: widget.color),
    );
  }
}

class _SpectrumPainter extends CustomPainter {
  const _SpectrumPainter({required this.levels, required this.color});

  final List<double> levels;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty || size.isEmpty) return;
    final count = levels.length;
    final gap = 4.0;
    final barWidth = (size.width - gap * (count - 1)) / count;
    if (barWidth <= 0) return;

    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, color.withValues(alpha: 0.35)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final basePaint = Paint()..color = color.withValues(alpha: 0.22);

    for (var i = 0; i < count; i++) {
      final level = levels[i].clamp(0.0, 1.0);
      final barHeight =
          (4 + level * (size.height - 4)).clamp(4.0, size.height);
      final left = i * (barWidth + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, size.height - barHeight, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, basePaint);
      if (level > 0.01) {
        canvas.drawRRect(rect, glowPaint);
        canvas.drawRRect(rect, bodyPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SpectrumPainter oldDelegate) {
    // Levels mutate in place, so always repaint: 32 rounded rects at ~20fps
    // is cheap and this is the only thing animating the bars.
    return true;
  }
}
