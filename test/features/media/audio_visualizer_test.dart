import 'package:file_explorer/features/media/data/audio_visualizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpectrumSmoother', () {
    test('attacks fast toward rising targets', () {
      final smoother = SpectrumSmoother(bands: 4, attack: 0.6, release: 0.1);
      smoother.update(const [1, 1, 1, 1]);
      expect(smoother.levels, everyElement(closeTo(0.6, 1e-9)));
    });

    test('releases slowly toward falling targets', () {
      final smoother = SpectrumSmoother(bands: 2, attack: 1, release: 0.1);
      smoother.update(const [1, 1]);
      smoother.update(const [0, 0]);
      expect(smoother.levels, everyElement(closeTo(0.9, 1e-9)));
    });

    test('clamps out-of-range targets', () {
      final smoother = SpectrumSmoother(bands: 2, attack: 1, release: 1);
      smoother.update(const [-0.5, 2.5]);
      expect(smoother.levels, [0.0, 1.0]);
    });

    test('decay settles to zero and reports it', () {
      final smoother = SpectrumSmoother(bands: 2, attack: 1, release: 0.5);
      smoother.update(const [1, 1]);
      var settled = false;
      for (var i = 0; i < 100 && !settled; i++) {
        settled = smoother.decay();
      }
      expect(settled, isTrue);
      expect(smoother.levels, [0.0, 0.0]);
    });

    test('ignores extra target values beyond band count', () {
      final smoother = SpectrumSmoother(bands: 2, attack: 1, release: 1);
      smoother.update(const [0.5, 0.5, 0.9, 0.9]);
      expect(smoother.levels, [0.5, 0.5]);
    });
  });
}
