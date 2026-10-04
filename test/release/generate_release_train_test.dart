import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/release/artifact_manifest.dart';

/// Sprint 102 / C6 — release-train generator.
///
/// Executes the real chain when RUN_RELEASE_TRAIN=1:
///   analyze -> focused gates -> linux debug build -> measure -> manifest.
///
/// Without the guard flag it is a no-op so plain `flutter test` stays fast.
/// Authority note (runbook D6): this tool NEVER creates tags or releases;
/// it only prepares the measured manifest for an authorized RC.
void main() {
  test('release train: analyze, gates, build, measure, manifest', () async {
    if (Platform.environment['RUN_RELEASE_TRAIN'] != '1') {
      return;
    }
    final release = Platform.environment['RELEASE_VERSION']!;
    final candidate =
        Platform.environment['RELEASE_CANDIDATE'] ?? 'untagged-rehearsal';

    Future<(String, int)> run(String exec, List<String> args) async {
      final p = await Process.run(exec, args);
      return ((p.stdout.toString() + p.stderr.toString()).trim(), p.exitCode);
    }

    final gates = <ManifestGate>[];

    // 1. Analyze.
    final (analyzeOut, analyzeCode) = await run('flutter', ['analyze']);
    gates.add(
      ManifestGate(
        name: 'flutter analyze',
        result: analyzeCode == 0 ? 'PASS' : 'FAIL',
      ),
    );
    expect(analyzeCode, 0, reason: analyzeOut);

    // 2. Focused gates: version lockstep + performance regression.
    final (gatesOut, gatesCode) = await run('flutter', [
      'test',
      'test/version_single_source_test.dart',
      'test/core/performance',
      '--reporter',
      'compact',
    ]);
    final gatesPass = RegExp(r'\+\d+: All tests passed!').hasMatch(gatesOut);
    gates.add(
      ManifestGate(
        name: 'focused gates (version + perf)',
        result: gatesCode == 0 && gatesPass ? 'PASS' : 'FAIL',
      ),
    );
    expect(gatesCode, 0, reason: gatesOut);

    // 3. Linux debug build.
    final (buildOut, buildCode) = await run('flutter', [
      'build',
      'linux',
      '--debug',
    ]);
    gates.add(
      ManifestGate(
        name: 'Linux debug build',
        result: buildCode == 0 ? 'PASS' : 'FAIL',
      ),
    );
    expect(buildCode, 0, reason: buildOut);

    // 4. Measure the produced artifact.
    final bin = File('build/linux/x64/debug/bundle/void_scriptor');
    expect(bin.existsSync(), true, reason: buildOut);
    final size = bin.lengthSync();
    final shaProc = await Process.run('sha256sum', [bin.path]);
    expect(shaProc.exitCode, 0);
    final sha256 = (shaProc.stdout as String).trim().split(' ').first;

    // 5. Commit identity (never from memory).
    final head = await Process.run('git', ['rev-parse', 'HEAD']);
    expect(head.exitCode, 0);
    final commitSha = (head.stdout as String).trim();

    // 6. Write the generated manifest.
    final manifest = ArtifactManifest(
      release: release,
      candidate: candidate,
      commitSha: commitSha,
      tagObjectSha: Platform.environment['RELEASE_TAG_OBJECT'] ?? commitSha,
      platform: 'Linux (Ubuntu WSL)',
      architecture: 'x64',
      buildMode: 'debug',
      buildCommand: 'flutter build linux --debug',
      artifactPath: bin.path,
      artifactSizeBytes: size,
      sha256: sha256,
    );
    File(
      'docs/release/v$release-artifact-manifest.md',
    ).writeAsStringSync(manifest.toMarkdown(gates: gates));
  }, timeout: const Timeout(Duration(minutes: 25)));
}
