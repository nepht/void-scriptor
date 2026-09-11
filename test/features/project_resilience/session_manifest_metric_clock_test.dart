import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';

/// vs-hunt-20260911 BUG-25 (Low): the open metrics recorded the manifest
/// phase with a clock started AFTER the manifest read had already completed,
/// so `durationOf('manifest')` was two back-to-back DateTime.now() calls
/// (~0 ms) regardless of how long the read actually took. Contract: the
/// recorded duration covers the real read — a stalled manifest read must
/// show up in the metric.
///
/// Harness: overrides the [ProjectSessionManager.readManifest] seam with a
/// deterministic stall, mirroring the probe-seam pattern of the run218
/// durability test. No wall-clock sleeps outside the measured window.
void main() {
  test(
    'the manifest metric measures the real read, not a post-read stamp '
    '(vs-hunt-20260911 BUG-25)',
    skip: !Platform.isWindows,
    () async {
      final root = await Directory.systemTemp.createTemp('bug25-metrics-');
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Metric Probe');

      const stall = Duration(milliseconds: 150);
      final manager = _StalledManifestManager(stall: stall);
      final session = await manager.open(package);
      addTearDown(session.close);

      final recorded = session.openMetrics.durationOf('manifest');
      expect(recorded, isNotNull, reason: 'metric manifest tercatat');
      expect(
        recorded! >= const Duration(milliseconds: 120),
        isTrue,
        reason:
            'durasi tercatat ($recorded) harus mencakup baca manifest yang '
            'dilambatkan ~${stall.inMilliseconds}ms; nilai ~0ms berarti '
            'clock masih distempel SETELAH baca selesai (BUG-25)',
      );
    },
  );
}

class _StalledManifestManager extends ProjectSessionManager {
  _StalledManifestManager({required this.stall});

  final Duration stall;

  @override
  Future<String> readManifest(ProjectPackage package) async {
    await Future<void>.delayed(stall);
    return package.manifestFile.readAsString();
  }
}
