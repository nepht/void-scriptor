import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_backup_restore_preview.dart';
import 'package:void_scriptor/features/project_resilience/application/project_recovery_services.dart';
import 'package:void_scriptor/features/project_resilience/application/project_resilience_controller.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';

/// Sprint 145.34 — Free-access proof for Local Backup and Restore.
///
/// Local backup/restore is a Core data-safety flow: a novelist working
/// offline without any account must be able to create backups, enforce
/// retention, preview a restore, restore in place, and restore to an
/// alternate destination. The acceptance contract forbids gating this flow
/// behind any account, plan, or entitlement mechanism.
///
/// These tests execute the complete flow through the production APIs only
/// (no auth session, no login, no plan provider — none exist on these
/// APIs) and then statically guard the resilience persistence tree so a
/// future account/plan/paywall coupling cannot silently regress the
/// free-access guarantee.
void main() {
  test(
    'backup, retention, preview, and restore complete without any account or plan',
    () async {
      final root = await Directory.systemTemp.createTemp('hermes-s34-free-');
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'FreeAccess');

      // Session, controller, and backup APIs take no auth/plan parameters;
      // there is no account to sign into and no entitlement to satisfy.
      final session = await ProjectSessionManager().open(package);
      final controller = ProjectResilienceController(session);

      final first = await controller.createBackup(note: 'manual one');
      final second = await controller.createBackup(note: 'manual two');
      final rows = await session.database.projectResilienceRepository
          .backupsFor(package.projectId);
      expect(rows, hasLength(2));

      // Restore preview is readable with no account present.
      final preview = await ProjectBackupRestorePreview.compute(
        package: package,
        backup: second,
      );
      expect(preview.compatibility, RestoreCompatibility.current);
      expect(preview.backupName, 'FreeAccess');

      // In-place restore: close the session first (WAL-safe), mutate the
      // live manifest, then restore and verify the original content.
      await session.close();
      final manifest = package.manifestFile;
      final liveName =
          jsonDecode(await manifest.readAsString())['name'] as String;
      manifest.writeAsStringSync(
        (await manifest.readAsString()).replaceFirst(
          '"name": "$liveName"',
          '"name": "$liveName-dirty"',
        ),
      );
      await ProjectBackupService().restore(package: package, backup: first);
      expect(
        (jsonDecode(manifest.readAsStringSync())['name'] as String),
        liveName,
      );

      // Alternate-destination restore also needs nothing but a directory.
      final destination = await Directory.systemTemp.createTemp(
        'hermes-s34-free-dest-',
      );
      addTearDown(() => destination.delete(recursive: true));
      final restored =
          await ProjectBackupRestorePreview.restoreToAlternateDestination(
            backup: first,
            destinationRoot: destination,
          );
      final restoredManifest = File(
        p.join(restored.root.path, 'manifest', 'project.json'),
      );
      expect(restoredManifest.existsSync(), isTrue);
      expect(
        (jsonDecode(restoredManifest.readAsStringSync())['name'] as String),
        liveName,
      );
    },
  );

  test(
    'resilience persistence tree has no account, plan, or paywall coupling',
    () {
      final banned = RegExp(
        'premium|paywall|subscription|entitlement|licensing|monetization|requirePlan|currentPlan|core/auth|features/account|features/collaboration',
        caseSensitive: false,
      );
      final violations = <String>[];
      for (final directory in [
        Directory('lib/features/project_resilience'),
        Directory('lib/core/persistence'),
      ]) {
        for (final entity in directory.listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          final lines = entity.readAsLinesSync();
          for (var i = 0; i < lines.length; i++) {
            if (banned.hasMatch(lines[i])) {
              violations.add('${entity.path}:${i + 1}: ${lines[i].trim()}');
            }
          }
        }
      }
      expect(
        violations,
        isEmpty,
        reason:
            'Backup/restore is a free Core flow (Step 145.34): no account, '
            'plan, paywall, or cloud-sync coupling may enter the resilience '
            'persistence tree. Violations:\n${violations.join('\n')}',
      );
    },
  );
}
