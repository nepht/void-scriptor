import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/restore_staging_journal.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_recovery_services.dart';

import '../../support/real_dart_executable.dart';

/// 145.42 interrupted_restore — hard process kill NYATA pada jendela swap
/// restore dua-fase. Child Dart murni me-replay staging + jurnal + swap
/// pertama memakai primitif produksi yang sama, lalu di-TerminateProcess
/// oleh parent tepat setelah live workspaces terhapus dan sebelum rename
/// penempatan. `RestoreCrashRecovery.recover` produksi (jalur yang sama
/// dengan session open) wajib menggulirkan restore selesai dari corpse.
void main() {
  test('OS kill inside the swap window: journal roll-forward completes the '
      'restore with zero live-byte corruption', () async {
    final root = await Directory.systemTemp.createTemp('hermes-restore-kill-');
    addTearDown(() => root.delete(recursive: true));
    final projectsRoot = Directory('${root.path}/projects')
      ..createSync(recursive: true);
    final package = await ProjectPackageService(
      rootDirectory: projectsRoot,
    ).create(name: 'Kill Harness');
    final workspaces = Directory('${package.root.path}/workspaces')
      ..createSync(recursive: true);
    await File(
      '${package.assetsDirectory.path}/portrait.txt',
    ).writeAsString('live portrait');
    await File('${workspaces.path}/novel.json').writeAsString('{"live":true}');
    final service = ProjectBackupService();
    final backup = await service.create(package: package, type: 'manual');
    // The emergency pre-restore snapshot: restore() creates this BEFORE
    // staging, so the kill corpse already carries it. The harness mirrors
    // that order explicitly.
    final emergency = await service.create(
      package: package,
      type: 'pre-restore',
      note: 'Emergency backup before restore',
    );
    service.lastEmergencyBackupPath = emergency.path;
    // Live evolves after the backup; the killed restore must still land
    // the backup payload for every area it had verified.
    await File(
      '${package.assetsDirectory.path}/portrait.txt',
    ).writeAsString('newer portrait');
    await File('${workspaces.path}/novel.json').writeAsString('{"newer":true}');

    final dartExe = await resolveRealDartExecutable();
    final childScript = File(
      'test/features/project_resilience/fixtures/'
      'restore_two_phase_kill_child.dart',
    );
    expect(
      await childScript.exists(),
      isTrue,
      reason: 'child script fixture must exist for the kill harness',
    );

    final process = await Process.start(dartExe, <String>[
      childScript.absolute.path,
      package.root.path,
      backup.path,
    ], workingDirectory: Directory.current.path);
    final staged = Completer<void>();
    final assetsPlaced = Completer<void>();
    final lines = <String>[];
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          lines.add(line);
          if (line.trim() == 'STAGED' && !staged.isCompleted) {
            staged.complete();
          }
          if (line.trim() == 'ASSETS_PLACED' && !assetsPlaced.isCompleted) {
            assetsPlaced.complete();
          }
        });
    final stderrText = StringBuffer();
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          stderrText.writeln(line);
          // Child died before staging: surface it as a test failure rather
          // than a 30s timeout.
          if (!staged.isCompleted && !assetsPlaced.isCompleted) {
            staged.completeError(
              StateError('child failed before STAGED: $line'),
            );
          }
        });

    await staged.future.timeout(const Duration(seconds: 60));
    await assetsPlaced.future.timeout(const Duration(seconds: 60));
    // The child has already deleted live workspaces (first line after
    // ASSETS_PLACED) and hangs before the rename: kill inside the window.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final killed = process.kill();
    expect(killed, isTrue, reason: 'hard kill must succeed');
    final exitCode = await process.exitCode.timeout(
      const Duration(seconds: 15),
    );
    expect(
      exitCode,
      isNot(0),
      reason: 'hard-killed child must exit nonzero (stderr: $stderrText)',
    );

    // Precondition of the corpse: live workspaces gone, journal + staged
    // copy present, assets area already placed from the backup.
    expect(await workspaces.exists(), isFalse);
    expect(
      await RestoreStagingJournal.load(package),
      isNotNull,
      reason: 'the kill must have landed inside the swap window',
    );
    expect(
      await File('${package.assetsDirectory.path}/portrait.txt').readAsString(),
      'live portrait',
      reason: 'the first placement completed before the kill',
    );

    // Production recovery (same entry point as ProjectSessionManager.open).
    final healed = await RestoreCrashRecovery.recover(package);

    expect(healed, greaterThan(0));
    expect(
      await workspaces.exists(),
      isTrue,
      reason: 'roll-forward must re-materialize the deleted live area',
    );
    expect(
      await File('${workspaces.path}/novel.json').readAsString(),
      '{"live":true}',
      reason:
          'the rolled-forward workspaces payload is the journaled '
          'backup content, not the post-backup live edit',
    );
    expect(
      await RestoreStagingJournal.load(package),
      isNull,
      reason: 'a completed roll-forward consumes the journal',
    );
    expect(
      await Directory('${package.assetsDirectory.path}.tmp').exists(),
      isFalse,
    );
    expect(
      await Directory('${package.root.path}/workspaces.tmp').exists(),
      isFalse,
    );
    // Emergency snapshot survives for user-driven decisions.
    expect(await Directory(service.lastEmergencyBackupPath!).exists(), isTrue);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
