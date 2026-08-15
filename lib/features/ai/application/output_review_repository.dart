import 'package:drift/drift.dart';

import '../../../database/project/project_database.dart';
import '../domain/output_review.dart';

/// Persists output review decisions (Step 28.16).
class OutputReviewRepository {
  OutputReviewRepository(this.database);

  final ProjectDatabase database;

  Future<void> setReview({
    required String generationId,
    required OutputReviewState state,
    String? feedback,
  }) async {
    final now = DateTime.now();
    await database
        .into(database.aiOutputReviews)
        .insertOnConflictUpdate(
          AiOutputReviewsCompanion.insert(
            generationId: generationId,
            status: state.name,
            feedback: Value(feedback),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<OutputReview?> getReview(String generationId) async {
    final row = await (database.select(
      database.aiOutputReviews,
    )..where((r) => r.generationId.equals(generationId))).getSingleOrNull();
    if (row == null) return null;
    return OutputReview(
      generationId: row.generationId,
      state: OutputReviewState.values.byName(row.status),
      feedback: row.feedback,
    );
  }
}
