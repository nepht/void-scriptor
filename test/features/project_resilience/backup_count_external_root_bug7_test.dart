import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/backup_location_policy.dart';
import 'package:void_scriptor/features/project_resilience/application/project_resilience_controller.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/project_resilience/presentation/project_resilience_center_screen.dart';

/// vs-hunt-20260915-resilience BUG-7 (Referee: REAL BUG, Medium):
/// `Available backups` was computed by scanning only the package-internal
/// backups directory, while backups created under a configured custom root
/// are recorded in the database with an absolute path OUTSIDE the package.
/// A valid external backup therefore existed in the recorded list and the
/// restore flow but was invisible in the displayed count.
///
/// Contract proven here: the count is defined from recorded backup rows whose
/// storage currently exists (the database row stays the source of truth), so
/// external-root backups count, and a recorded row whose drive is gone is not
/// silently counted as available.
void main() {
  Future<
    (
      Directory root,
      ProjectPackage package,
      ProjectSession session,
      ProjectResilienceController controller,
      Directory customRoot,
    )
  >
  openWithCustomRoot(String name) async {
    final root = await Directory.systemTemp.createTemp('hermes-bug7-root-');
    final customRoot = await Directory.systemTemp.createTemp(
      'hermes-bug7-custom-',
    );
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: name);
    final session = await ProjectSessionManager().open(package);
    final controller = ProjectResilienceController(
      session,
      backupLocationPolicy: BackupLocationPolicy(),
    );
    controller.configureCustomBackupRoot(customRoot);
    return (root, package, session, controller, customRoot);
  }

  test(
    'scan counts a backup stored outside the package under the custom root',
    () async {
      final (root, package, session, controller, customRoot) =
          await openWithCustomRoot('Bug7A');
      addTearDown(() async {
        await session.close();
        for (final dir in [root, customRoot]) {
          if (dir.existsSync()) await dir.delete(recursive: true);
        }
      });

      final backup = await controller.createBackup(note: 'external-count');
      expect(backup.path.startsWith(customRoot.path), isTrue);
      // The defect's precondition: nothing landed in the internal directory.
      expect(
        Directory(
          package.backupDirectory.path,
        ).listSync().whereType<Directory>(),
        isEmpty,
      );

      final snapshot = await controller.scan();
      expect(snapshot.backups, hasLength(1), reason: 'row recorded');
      expect(
        snapshot.backupItems,
        1,
        reason: 'external backup is available and must be counted',
      );
    },
  );

  test(
    'recorded row whose external directory is gone is not counted available',
    () async {
      final (root, _, session, controller, customRoot) =
          await openWithCustomRoot('Bug7B');
      addTearDown(() async {
        await session.close();
        for (final dir in [root, customRoot]) {
          if (dir.existsSync()) await dir.delete(recursive: true);
        }
      });

      await controller.createBackup(note: 'external-gone');
      // Simulate the drive being absent again.
      customRoot.deleteSync(recursive: true);

      final snapshot = await controller.scan();
      expect(snapshot.backups, hasLength(1), reason: 'row kept for audit');
      expect(
        snapshot.backupItems,
        0,
        reason: 'storage is not present, so it is not an available backup',
      );
    },
  );

  testWidgets(
    'backups screen shows an external-root backup in the count line',
    (tester) async {
      final seeded = await tester.runAsync(() => openWithCustomRoot('Bug7C'));
      final (root, _, session, controller, customRoot) = seeded!;
      await tester.runAsync(() => controller.createBackup(note: 'ext-ui'));
      addTearDown(() async {
        await tester.runAsync(() => session.close());
        for (final dir in [root, customRoot]) {
          if (dir.existsSync()) await dir.delete(recursive: true);
        }
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ProjectResilienceWorkspaceScreen(
              view: ProjectResilienceView.backups,
              session: session,
            ),
          ),
        ),
      );
      // The scan performs real file-system I/O that only progresses on the
      // real event loop, so pump in real time until the line renders.
      final probe = find.text('Available backups: 1');
      final deadline = DateTime.now().add(const Duration(seconds: 30));
      while (DateTime.now().isBefore(deadline)) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        if (probe.evaluate().isNotEmpty) break;
      }
      expect(
        probe,
        findsOneWidget,
        reason: 'the recorded external backup must be visible in the count',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
