import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/performance/large_project_benchmark.dart';
import 'package:void_scriptor/core/performance/project_benchmark_runner.dart';

import 'package:void_scriptor/core/performance/benchmark_report_writer.dart'
    as writer;

/// One-shot baseline generator.
///
/// Skipped unless RUN_BASELINE_GEN=1 so ordinary test runs never write
/// repository files. Usage:
///
/// ```sh
/// RUN_BASELINE_GEN=1 \
/// BASELINE_COMMIT_SHA=$(git rev-parse HEAD) \
/// BASELINE_FLUTTER="$(flutter --version | head -1)" \
/// flutter test test/core/performance/baseline_generator_test.dart
/// ```
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates the measured performance baseline document', () async {
    if (Platform.environment['RUN_BASELINE_GEN'] != '1') {
      return;
    }

    final commitSha = Platform.environment['BASELINE_COMMIT_SHA'];
    expect(commitSha, isNotNull, reason: 'BASELINE_COMMIT_SHA is required');

    final flutterVersion =
        Platform.environment['BASELINE_FLUTTER'] ?? 'unknown';
    final generatedAt =
        Platform.environment['BASELINE_GENERATED_AT'] ??
        DateTime.now().toUtc().toIso8601String();

    const profile = LargeProjectBenchmarkProfile.defaultProfile();
    final report = await ProjectBenchmarkRunner(profile: profile).run();

    final markdown = writer.BenchmarkReportWriter.writeBaselineMarkdown(
      report: report,
      generatedAtUtcIso: generatedAt,
      commitSha: commitSha!,
      flutterVersion: flutterVersion,
      profile: profile,
    );

    final file = File('docs/benchmarks/baseline-v1.0.1.md');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(markdown);

    expect(file.existsSync(), isTrue);
    expect(
      file.readAsStringSync(),
      contains('# Void Scriptor Performance Baseline'),
    );
  });
}
