import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/domain/asset_type.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/selection/selection_memory_snapshot.dart';
import 'package:void_scriptor/core/selection/selection_model.dart';
import 'package:void_scriptor/features/explorer/presentation/explorer_panel.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

/// Regression for void-scriptor-hunt-run171 BUG-3 (Referee: REAL BUG, Low):
/// the selection-memory persist listener fired the synchronous writer with no
/// try/catch, so a disk failure (createSync/writeAsStringSync/renameSync)
/// escaped every selection change as an unhandled zone error — directly
/// contradicting the documented contract "disk failures are swallowed by
/// contract ... but are observable via debugPrint". The load side already
/// catches all errors; the sync persist side did not.
void main() {
  group(
    'selection memory sync persist failure contract (hunt-run171 BUG-3)',
    () {
      test(
        'sync persist never throws and reports the failure via debugPrint',
        () async {
          final root = await Directory.systemTemp.createTemp(
            'void-selmem-persistfail-',
          );
          addTearDown(() async {
            try {
              await root.delete(recursive: true);
            } catch (_) {}
          });

          final service = ProjectPackageService(rootDirectory: root);
          final package = await service.create(name: 'Projek Uji');

          // Make the cache directory path unusable: the writer's
          // `file.parent.createSync` must hit a FileSystemException against a
          // regular file squatting on the directory path.
          final cachePath = package.cacheDirectory.path;
          try {
            await Directory(cachePath).delete(recursive: true);
          } catch (_) {}
          await File(cachePath).writeAsString('blocker');

          final file = selectionMemoryFileFor(package);
          final printed = <String>[];

          // RED: on the current code the raw call throws out of the function
          // and nothing is printed — the contract comment is false on both
          // halves (swallowed AND observable via debugPrint).
          runZoned<void>(
            () {
              persistSelectionMemorySnapshotSync(file, {
                (package.projectId, AssetType.story): 'story-picked',
              });
            },
            zoneSpecification: ZoneSpecification(
              print: (_, __, ___, line) => printed.add(line),
            ),
          );

          expect(
            printed.any((line) => line.contains('selection memory')),
            isTrue,
            reason:
                'disk failure must be observable via debugPrint per the '
                'documented persistence contract',
          );
        },
      );

      test(
        'persist listener surfaces no unhandled zone error on disk failure',
        () async {
          final root = await Directory.systemTemp.createTemp(
            'void-selmem-listener-',
          );
          addTearDown(() async {
            try {
              await root.delete(recursive: true);
            } catch (_) {}
          });

          final service = ProjectPackageService(rootDirectory: root);
          final package = await service.create(name: 'Projek Dengar');
          final cachePath = package.cacheDirectory.path;
          try {
            await Directory(cachePath).delete(recursive: true);
          } catch (_) {}
          await File(cachePath).writeAsString('blocker');

          final container = ProviderContainer(
            overrides: [
              projectPathsProvider.overrideWithValue(
                ProjectPaths(rootDirectory: root),
              ),
            ],
          );
          addTearDown(container.dispose);
          await container.read(projectSessionProvider.future);
          final notifier = container.read(projectSessionProvider.notifier);
          await notifier.openProject(package.projectId);

          final unhandled = <Object>[];
          container.listen(selectionMemoryPersistenceProvider, (_, __) {});

          // RED: the listener's unguarded sync write rethrows through the
          // provider plumbing and lands as an unhandled error below this zone.
          await runZonedGuarded(() async {
            container
                .read(selectionProvider.notifier)
                .select(
                  SelectionModel(
                    assetId: 'story-picked',
                    assetType: AssetType.story,
                    projectId: package.projectId,
                  ),
                );
            await Future<void>.delayed(Duration.zero);
          }, (error, _) => unhandled.add(error));

          expect(
            unhandled.whereType<FileSystemException>(),
            isEmpty,
            reason:
                'a failing disk write must not escape the listener as an '
                'unhandled zone error on every selection change',
          );

          await notifier.closeProject();
        },
      );
    },
  );
}
