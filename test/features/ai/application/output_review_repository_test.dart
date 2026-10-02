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

  // --- sprint 117.37 evidence-integrity regressions ----------------------
  // The review row is the only shipped persistence of user feedback about an
  // AI output, so it is evidence. These tests pin the three defects found
  // while reading it: illegal transitions were writable, createdAt was
  // overwritten on every write, and an omitted feedback erased the record.

  test('rejects a transition the domain state machine forbids', () async {
    await repository.setReview(
      generationId: 'gen-3',
      state: OutputReviewState.pending,
      feedback: 'first pass',
    );

    await expectLater(
      repository.setReview(
        generationId: 'gen-3',
        state: OutputReviewState.pending,
        feedback: 'first pass',
      ),
      throwsA(isA<OutputReviewTransitionError>()),
    );

    // The forbidden write must leave the stored evidence untouched.
    final review = await repository.getReview('gen-3');
    expect(review!.state, OutputReviewState.pending);
    expect(review.feedback, 'first pass');
  });

  test(
    'second write preserves createdAt as the first-seen evidence time',
    () async {
      await repository.setReview(
        generationId: 'gen-4',
        state: OutputReviewState.rejected,
        feedback: 'too dark',
      );
      final first = await repository.getReview('gen-4');

      // Stored as unix seconds (drift default), so a sub-second gap is invisible.
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await repository.setReview(
        generationId: 'gen-4',
        state: OutputReviewState.pending,
        feedback: 'too dark',
      );
      final second = await repository.getReview('gen-4');

      expect(first!.createdAt, isNotNull);
      expect(second!.createdAt, first.createdAt);
      expect(second.updatedAt!.isAfter(first.createdAt!), isTrue);
    },
  );

  test('a write without feedback does not erase recorded feedback', () async {
    await repository.setReview(
      generationId: 'gen-5',
      state: OutputReviewState.rejected,
      feedback: 'too dark',
    );

    await repository.setReview(
      generationId: 'gen-5',
      state: OutputReviewState.pending,
    );

    final review = await repository.getReview('gen-5');
    expect(review!.state, OutputReviewState.pending);
    expect(review.feedback, 'too dark');
  });

  test('a first write creates a row without a transition check', () async {
    await repository.setReview(
      generationId: 'gen-6',
      state: OutputReviewState.approved,
      feedback: 'ship it',
    );
    final review = await repository.getReview('gen-6');
    expect(review!.state, OutputReviewState.approved);
    expect(review.createdAt, isNotNull);
  });
}
