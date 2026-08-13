import 'package:uuid/uuid.dart';

import '../../../core/persistence/project_paths.dart';
import '../../../database/project/project_database.dart';
import '../../references/application/reference_repository.dart';
import '../../references/domain/reference_models.dart';
import 'generation_repository.dart';

class GenerationReferenceResult {
  const GenerationReferenceResult({
    required this.reference,
    required this.review,
  });
  final ReferenceModel reference;
  final ConsistencyReviewModel review;
}

class GenerationReferenceService {
  GenerationReferenceService({required this.database, required this.paths})
    : generations = GenerationRepository(database),
      references = ReferenceDao(database);

  final ProjectDatabase database;
  final ProjectPaths paths;
  final GenerationRepository generations;
  final ReferenceDao references;

  Future<GenerationReferenceResult> useAsReference({
    required String projectId,
    required String outputId,
    required String ownerAssetId,
    required ReferenceType type,
    required String name,
    bool primary = false,
  }) async {
    final output = await generations.getOutput(outputId);
    final localPath = output?.localPath;
    if (output == null || localPath == null || localPath.trim().isEmpty) {
      throw StateError('Generation output has no local file: $outputId');
    }
    final reference =
        await ReferenceImportService(
          database: database,
          paths: paths,
        ).importFile(
          projectId: projectId,
          referenceId: const Uuid().v4(),
          sourcePath: localPath,
          name: name,
          ownerAssetId: ownerAssetId,
          type: type,
          source: ReferenceSource.generated,
          primary: primary,
        );
    final rules = await references.rulesForAsset(ownerAssetId);
    final review = ConsistencyReviewModel(
      id: const Uuid().v4(),
      generationOutputId: outputId,
      assetId: ownerAssetId,
      status: rules.isEmpty
          ? ConsistencyReviewStatus.notReviewed
          : ConsistencyReviewStatus.reviewRequired,
      notes: rules.isEmpty
          ? 'No active consistency rules.'
          : '${rules.length} active consistency rule(s) require review.',
      reviewedAt: DateTime.now().toUtc(),
    );
    await references.saveReview(review);
    for (final rule in rules) {
      await references.saveReviewItem(
        ConsistencyReviewItemModel(
          id: const Uuid().v4(),
          reviewId: review.id,
          ruleId: rule.id,
          status: ConsistencyReviewStatus.reviewRequired,
          notes: 'Awaiting evaluation: ${rule.description}',
        ),
      );
    }
    return GenerationReferenceResult(reference: reference, review: review);
  }
}
