import 'package:file_explorer/features/analyzer/data/storage_analyzer_scanner.dart';
import 'package:file_explorer/features/analyzer/domain/entities/storage_analysis.dart';
import 'package:flutter_riverpod/legacy.dart';

final analyzerControllerProvider =
    StateNotifierProvider<AnalyzerController, AnalyzerState>((ref) {
  return AnalyzerController();
});

class AnalyzerState {
  const AnalyzerState({
    this.scanning = false,
    this.analysis,
    this.error,
  });

  final bool scanning;
  final StorageAnalysis? analysis;
  final String? error;
}

class AnalyzerController extends StateNotifier<AnalyzerState> {
  AnalyzerController() : super(const AnalyzerState(scanning: true));

  Future<void> scan(String rootPath) async {
    state = const AnalyzerState(scanning: true);
    try {
      final analysis = await scanStorage(rootPath);
      state = AnalyzerState(scanning: false, analysis: analysis);
    } catch (error) {
      state = AnalyzerState(scanning: false, error: error.toString());
    }
  }
}
