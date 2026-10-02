import 'package:drift/drift.dart';

import '../../../database/project/project_database.dart';
import '../domain/output_review.dart';

/// Persists output review decisions (Step 28.16).
class OutputReviewRepository {
  OutputReviewRepository(this.database);

  final ProjectDatabase database;

  /// Records one review decision for [generationId].
  ///
  /// Evidence rules for sprint 117.37:
  /// * a write that is not a legal transition from the stored state throws
  ///   [OutputReviewTransitionError] and leaves the row untouched, so a
  ///   caller cannot rewrite the recorded history;
  /// * `createdAt` is written once on insert and never overwritten, so it
  ///   keeps the first-seen evidence time;
  /// * [feedback] defaults to absent on update: omitting it must not erase
  ///   the feedback already recorded.
  Future<void> setReview({
    required String generationId,
    required OutputReviewState state,
    String? feedback,
  }) async {
    final now = DateTime.now();
    final row = await _readRow(generationId);
    if (row == null) {
      // First write: no stored state exists, so there is no transition to
      // check and createdAt records the first-seen evidence time.
      await database
          .into(database.aiOutputReviews)
          .insert(
            AiOutputReviewsCompanion.insert(
              generationId: generationId,
              status: state.name,
              feedback: Value(feedback),
              createdAt: now,
              updatedAt: now,
            ),
          );
      return;
    }

    final current = OutputReviewState.values.byName(row.status);
    if (!current.canTransitionTo(state)) {
      throw OutputReviewTransitionError(
        generationId: generationId,
        from: current,
        to: state,
      );
    }

    await (database.update(
      database.aiOutputReviews,
    )..where((r) => r.generationId.equals(generationId))).write(
      AiOutputReviewsCompanion(
        status: Value(state.name),
        feedback: feedback == null ? const Value.absent() : Value(feedback),
        updatedAt: Value(now),
      ),
    );
  }

  Future<AiOutputReview?> _readRow(String generationId) {
    return (database.select(
      database.aiOutputReviews,
    )..where((r) => r.generationId.equals(generationId))).getSingleOrNull();
  }

  Future<OutputReview?> getReview(String generationId) async {
    final row = await _readRow(generationId);
    if (row == null) return null;
    return OutputReview(
      generationId: row.generationId,
      state: OutputReviewState.values.byName(row.status),
      feedback: row.feedback,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
