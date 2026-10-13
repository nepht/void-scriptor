import 'dart:io';

import 'package:void_scriptor/core/roadmap/roadmap_guard.dart';

Future<void> main(List<String> arguments) async {
  final repository = Directory.current;
  if (arguments.contains('--stability-gateway')) {
    final evidenceIndex = arguments.indexOf('--evidence');
    final evidencePath = evidenceIndex >= 0 && evidenceIndex + 1 < arguments.length
        ? arguments[evidenceIndex + 1]
        : null;
    if (evidencePath == null || evidencePath.trim().isEmpty) {
      stderr.writeln('STABILITY_GATEWAY: REJECTED');
      stderr.writeln('- argumen --evidence <path> wajib');
      exitCode = 1;
      return;
    }
    final gateway = await RoadmapGuard.applyStabilityGate(
      repository: repository,
      evidenceFile: File(evidencePath),
    );
    stdout.writeln(
      'STABILITY_GATEWAY: ${gateway.applied ? 'APPLIED' : 'REJECTED'}',
    );
    for (final rejection in gateway.rejections) {
      stderr.writeln('REJECT: $rejection');
    }
    if (!gateway.applied) exitCode = 1;
    return;
  }
  final repair = arguments.contains('--repair');
  final syncPointer = arguments.contains('--sync-pointer');
  final result = repair
      ? await RoadmapGuard.repair(repository: repository)
      : syncPointer
      ? await RoadmapGuard.syncRuntimePointer(repository: repository)
      : await RoadmapGuard.inspect(repository: repository);

  stdout.writeln('ROADMAP_GUARD: ${result.ok ? 'PASS' : 'FAIL'}');
  stdout.writeln('canonical_sprint: ${result.canonicalSprint ?? '-'}');
  stdout.writeln(
    'recommended_step: ${result.recommendedStep ?? 'SPRINT_COMPLETE'}',
  );
  stdout.writeln('last_resolved_step: ${result.lastResolvedStep ?? '-'}');
  stdout.writeln('canonical_sha256: ${result.canonicalHash ?? '-'}');
  for (final warning in result.warnings) {
    stdout.writeln('WARNING: $warning');
  }
  for (final issue in result.issues) {
    stderr.writeln('ERROR: $issue');
  }
  if (!result.ok) exitCode = 1;
}
