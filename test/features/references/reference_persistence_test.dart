import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/references/domain/reference_models.dart';

void main() {
  test(
    'reference schema persists global references, locks, sets, and reviews after restart',
    () async {
      final root = await Directory.systemTemp.createTemp(
        's20-reference-persistence-',
      );
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      final databaseFile = await paths.database('project-1');
      final service = ProjectDatabaseService();
      final first = await service.open(databaseFile.path);
      await first
          .into(first.references)
          .insert(
            ReferencesCompanion.insert(
              id: 'face-master',
              projectId: 'project-1',
              ownerAssetId: const Value('qowner'),
              type: ReferenceType.face.name,
              source: ReferenceSource.imported.name,
              name: 'Master Face',
              filePath: 'assets/references/qowner/face/master.png',
              priority: const Value(100),
              primaryReference: const Value(true),
              createdAt: DateTime.utc(2026, 8),
              updatedAt: DateTime.utc(2026, 8),
            ),
          );
      await first
          .into(first.preservationLocks)
          .insert(
            PreservationLocksCompanion.insert(
              id: 'lock-face',
              assetId: 'qowner',
              type: PreservationLockType.face.name,
              instruction: const Value('Preserve jawline and eye spacing.'),
              priority: const Value(100),
            ),
          );
      await first
          .into(first.referenceSets)
          .insert(
            ReferenceSetsCompanion.insert(
              id: 'identity-set',
              projectId: 'project-1',
              ownerAssetId: const Value('qowner'),
              name: 'Qowner Master Identity',
              defaultSet: const Value(true),
              createdAt: DateTime.utc(2026, 8),
            ),
          );
      await first
          .into(first.referenceSetItems)
          .insert(
            ReferenceSetItemsCompanion.insert(
              referenceSetId: 'identity-set',
              referenceId: 'face-master',
            ),
          );
      await first
          .into(first.consistencyReviews)
          .insert(
            ConsistencyReviewsCompanion.insert(
              id: 'review-1',
              generationOutputId: 'output-1',
              assetId: 'qowner',
              status: ConsistencyReviewStatus.reviewRequired.name,
              notes: const Value('Hair geometry requires review.'),
            ),
          );
      await first.close();

      final second = await service.open(databaseFile.path);
      addTearDown(second.close);
      expect(second.schemaVersion, 17);
      expect(
        (await second.select(second.references).get()).single.name,
        'Master Face',
      );
      expect(
        (await second.select(second.preservationLocks).get()).single.enabled,
        isTrue,
      );
      expect(
        (await second.select(second.referenceSetItems).get())
            .single
            .referenceId,
        'face-master',
      );
      expect(
        (await second.select(second.consistencyReviews).get()).single.status,
        'reviewRequired',
      );
    },
  );
}
