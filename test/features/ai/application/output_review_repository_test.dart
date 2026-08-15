import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/ai/application/output_review_repository.dart';
import 'package:void_scriptor/features/ai/domain/output_review.dart';

void main() {
  late ProjectDatabase db;
  late OutputReviewRepository repository;

  setUp(() {
    db = ProjectDatabase(NativeDatabase.memory());
    repository = OutputReviewRepository(db);
  });

  tearDown(() async => db.close());

  test('review state machine transitions', () {
    const pending = OutputReviewState.pending;
    expect(pending.canTransitionTo(OutputReviewState.approved), isTrue);
    expect(pending.canTransitionTo(OutputReviewState.rejected), isTrue);
    expect(pending.canTransitionTo(OutputReviewState.pending), isFalse);

    const approved = OutputReviewState.approved;
    expect(approved.canTransitionTo(OutputReviewState.rejected), isTrue);
  });

  test('sets and reads review with feedback', () async {
    await repository.setReview(
      generationId: 'gen-1',
      state: OutputReviewState.approved,
      feedback: 'looks good',
    );
    final review = await repository.getReview('gen-1');
    expect(review, isNotNull);
    expect(review!.state, OutputReviewState.approved);
    expect(review.feedback, 'looks good');
  });

  test('records regenerate-with-feedback by overwriting status', () async {
    await repository.setReview(
      generationId: 'gen-2',
      state: OutputReviewState.rejected,
      feedback: 'too dark',
    );
    await repository.setReview(
      generationId: 'gen-2',
      state: OutputReviewState.pending,
      feedback: 'too dark',
    );
    final review = await repository.getReview('gen-2');
    expect(review!.state, OutputReviewState.pending);
    expect(review.feedback, 'too dark');
  });
}
