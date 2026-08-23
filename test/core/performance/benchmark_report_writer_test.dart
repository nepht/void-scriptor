import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/performance/benchmark_report_writer.dart';
import 'package:void_scriptor/core/performance/large_project_benchmark.dart';
import 'package:void_scriptor/core/performance/project_benchmark_runner.dart';

void main() {
  test('writes deterministic baseline markdown from a benchmark report', () {
    const report = ProjectBenchmarkReport(
      referenceCount: 200,
      timelineClipCount: 1000,
      referenceListMicros: 1234,
      timelineRangeMicros: 567,
    );
    const profile = LargeProjectBenchmarkProfile(
      characters: 10,
      references: 200,
      generations: 50,
      scenes: 100,
      timelineClips: 1000,
    );

    final md = BenchmarkReportWriter.writeBaselineMarkdown(
      report: report,
      generatedAtUtcIso: '2026-08-24T00:00:00Z',
      commitSha: 'abc1234',
      flutterVersion: 'Flutter 3.x channel stable',
      profile: profile,
    );

    expect(md, contains('# Void Scriptor Performance Baseline'));
    expect(md, contains('- Generated at: 2026-08-24T00:00:00Z'));
    expect(md, contains('- Commit: abc1234'));
    expect(md, contains('- Flutter: Flutter 3.x channel stable'));
    expect(
      md,
      contains(
        '- Profile: characters=10, references=200, '
        'generations=50, scenes=100, timelineClips=1000',
      ),
    );
    expect(md, contains('| reference_list | 1234 |'));
    expect(md, contains('| timeline_range | 567 |'));
    expect(md, contains('| total | 1801 |'));
    expect(md, endsWith('\n'));
  });

  test('writer rejects empty commit sha', () {
    const report = ProjectBenchmarkReport(
      referenceCount: 0,
      timelineClipCount: 0,
      referenceListMicros: 0,
      timelineRangeMicros: 0,
    );

    expect(
      () => BenchmarkReportWriter.writeBaselineMarkdown(
        report: report,
        generatedAtUtcIso: 'x',
        commitSha: '',
        flutterVersion: 'y',
        profile: const LargeProjectBenchmarkProfile.defaultProfile(),
      ),
      throwsArgumentError,
    );
  });
}
