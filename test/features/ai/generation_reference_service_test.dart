import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_file_service.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/ai/application/generation_reference_service.dart';
import 'package:void_scriptor/features/ai/application/generation_repository.dart';
import 'package:void_scriptor/features/references/domain/reference_models.dart';

void main() {
  test(
    'generation output becomes managed reference with consistency review',
    () async {
      final root = await Directory.systemTemp.createTemp(
        's20-generation-reference-',
      );
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      await ProjectFileService(paths: paths).createStructure('p');
      // 145.42: open() no longer silently creates the database file.
      await ProjectDatabaseService().create((await paths.database('p')).path);
      final database = await ProjectDatabaseService().open(
        (await paths.database('p')).path,
      );
      addTearDown(database.close);
      final output = File('${root.path}/output.png')
        ..writeAsBytesSync([7, 8, 9]);
      final generations = GenerationRepository(database);
      await generations.saveOutput(
        jobId: 'job',
        outputId: 'output',
        outputType: 'image',
        localPath: output.path,
        mimeType: 'image/png',
      );
      await database.referenceDao.saveRule(
        const ConsistencyRuleModel(
          id: 'face-rule',
          assetId: 'qowner',
          type: ConsistencyRuleType.identity,
          description: 'Face must match canon',
          severity: ConsistencySeverity.critical,
        ),
      );
      final result =
          await GenerationReferenceService(
            database: database,
            paths: paths,
          ).useAsReference(
            projectId: 'p',
            outputId: 'output',
            ownerAssetId: 'qowner',
            type: ReferenceType.face,
            name: 'Generated Face',
          );
      expect(result.reference.source, ReferenceSource.generated);
      expect(result.review.status, ConsistencyReviewStatus.reviewRequired);
      final reviewItems = await database.referenceDao.itemsForReview(
        result.review.id,
      );
      expect(reviewItems, hasLength(1));
      expect(reviewItems.single.ruleId, 'face-rule');
      expect(
        (await database.referenceDao.list(ownerAssetId: 'qowner')).single.id,
        result.reference.id,
      );
    },
  );
}
