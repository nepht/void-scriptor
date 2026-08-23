import 'large_project_benchmark.dart';
import 'project_benchmark_runner.dart';

/// Renders a deterministic Markdown baseline report from a measured
/// [ProjectBenchmarkReport].
///
/// The output must stay stable so successive baselines can be diffed
/// line-by-line; do not add timestamps or machine-specific values beyond
/// the explicitly provided metadata fields.
abstract final class BenchmarkReportWriter {
  static String writeBaselineMarkdown({
    required ProjectBenchmarkReport report,
    required String generatedAtUtcIso,
    required String commitSha,
    required String flutterVersion,
    required LargeProjectBenchmarkProfile profile,
  }) {
    if (commitSha.isEmpty) {
      throw ArgumentError.value(commitSha, 'commitSha', 'must not be empty');
    }
    final buffer = StringBuffer()
      ..writeln('# Void Scriptor Performance Baseline')
      ..writeln()
      ..writeln('- Generated at: $generatedAtUtcIso')
      ..writeln('- Commit: $commitSha')
      ..writeln('- Flutter: $flutterVersion')
      ..writeln(
        '- Profile: characters=${profile.characters}, '
        'references=${profile.references}, '
        'generations=${profile.generations}, '
        'scenes=${profile.scenes}, '
        'timelineClips=${profile.timelineClips}',
      )
      ..writeln()
      ..writeln('| metric | micros |')
      ..writeln('|---|---|')
      ..writeln('| reference_list | ${report.referenceListMicros} |')
      ..writeln('| timeline_range | ${report.timelineRangeMicros} |')
      ..writeln('| total | ${report.totalMicros} |');
    return buffer.toString();
  }
}
