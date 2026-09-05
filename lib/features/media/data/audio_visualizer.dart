import 'package:flutter/services.dart';

/// Native live-spectrum client for the built-in audio player.
///
/// Android hooks the output mix via `Visualizer(0)` and streams 32
/// log-spaced FFT magnitudes (0..1) at ~20 fps. Everywhere else (or when the
/// effect is unsupported) [start] resolves false and callers fall back to a
/// static visual.
class AudioVisualizer {
  const AudioVisualizer._();

  static const int bands = 32;

  static const MethodChannel _method =
      MethodChannel('com.ajayff4.fileexplorer/audio_visualizer');
  static const EventChannel _fft =
      EventChannel('com.ajayff4.fileexplorer/audio_visualizer/fft');

  /// Starts native capture. Resolves true only when frames will flow.
  static Future<bool> start() async {
    try {
      return await _method.invokeMethod<bool>('start') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Stops native capture and releases the effect. Best-effort.
  static Future<void> stop() async {
    try {
      await _method.invokeMethod<void>('stop');
    } catch (_) {
      // Missing plugin / already released: nothing to do.
    }
  }

  /// Broadcast stream of FFT magnitude frames, each [bands] values in 0..1.
  static Stream<List<double>> fftFrames() {
    return _fft.receiveBroadcastStream().map((event) {
      if (event is List) {
        return event
            .map((v) => v is num ? v.toDouble().clamp(0.0, 1.0) : 0.0)
            .toList();
      }
      return const <double>[];
    });
  }
}

/// Fast-attack / slow-release smoothing for spectrum levels, so bars jump
/// with the beat but fall gracefully.
class SpectrumSmoother {
  SpectrumSmoother({
    this.bands = AudioVisualizer.bands,
    this.attack = 0.6,
    this.release = 0.18,
  }) : levels = List<double>.filled(bands, 0);

  final int bands;
  final double attack;
  final double release;
  final List<double> levels;

  void update(List<double> target) {
    final count = levels.length < target.length ? levels.length : target.length;
    for (var i = 0; i < count; i++) {
      final t = target[i].clamp(0.0, 1.0);
      final current = levels[i];
      levels[i] = current + (t - current) * (t > current ? attack : release);
    }
  }

  /// Eases every level toward zero. Resolves true once fully settled.
  bool decay() {
    var settled = true;
    for (var i = 0; i < levels.length; i++) {
      final next = levels[i] * (1 - release);
      levels[i] = next < 0.004 ? 0 : next;
      if (levels[i] != 0) settled = false;
    }
    return settled;
  }

  void reset() => levels.fillRange(0, levels.length, 0);
}
