import 'dart:io';

import 'package:void_scriptor/core/roadmap/roadmap_guard.dart';

Future<void> main(List<String> arguments) async {
  final repository = Directory.current;
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
