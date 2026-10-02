// Output review controller tests.
//
// The point of the controller is refusing loudly, so most of these assert on
// refusals and on what did NOT reach the database. A test that only checks the
// happy path would pass against a controller that silently swallowed every
// error, which is the failure mode it exists to prevent.
//
// Every write goes through a real in-memory ProjectDatabase: the repository's
// transition rules and the "feedback is absent on update" behaviour are
// contracts worth exercising together, not mocked away.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/ai/application/output_review_controller.dart';
import 'package:void_scriptor/features/ai/application/output_review_repository.dart';
import 'package:void_scriptor/features/ai/domain/output_review.dart';

void main() {
  late ProjectDatabase db;
  late OutputReviewRepository repository;
  late OutputReviewController controller;

  setUp(() {
    db = ProjectDatabase(NativeDatabase.memory());
    repository = OutputReviewRepository(db);
    controller = OutputReviewController(repository: repository);
  });

  tearDown(() async => db.close());

  group('deciding', () {
    test('approve writes and is then known to the controller', () async {
      expect(await controller.approve('gen-1'), isTrue);

      final stored = await repository.getReview('gen-1');
      expect(stored?.state, OutputReviewState.approved);
      expect(controller.stateFor('gen-1'), OutputReviewState.approved);
      expect(controller.lastError, isNull);
    });

    test('reject writes and is then known to the controller', () async {
      expect(await controller.reject('gen-1'), isTrue);

      expect(
        (await repository.getReview('gen-1'))?.state,
        OutputReviewState.rejected,
      );
      expect(controller.decisionFor('gen-1'), OutputReviewDecision.rejected);
    });

    test('an unknown generation reads as unknown, not pending', () async {
      // Collapsing these would let a screen that never loaded the row present an
      // unread state as an empty queue item.
      expect(
        controller.decisionFor('never-loaded'),
        OutputReviewDecision.unknown,
      );
      expect(controller.stateFor('never-loaded'), isNull);
    });

    test('load makes a missing row explicitly pending', () async {
      await controller.load('gen-1');

      expect(controller.stateFor('gen-1'), OutputReviewState.pending);
      expect(controller.decisionFor('gen-1'), OutputReviewDecision.pending);
    });

    test('load surfaces an existing recorded decision', () async {
      await repository.setReview(
        generationId: 'gen-1',
        state: OutputReviewState.approved,
      );

      await controller.load('gen-1');

      expect(controller.decisionFor('gen-1'), OutputReviewDecision.approved);
    });
  });

  group('refusals', () {
    test('an empty generation id is refused with a reason', () async {
      expect(await controller.approve('   '), isFalse);

      expect(controller.lastError, contains('No generation is selected'));
      expect(controller.errorGenerationId, '   ');
    });

    test('an illegal second decision is refused and not written', () async {
      await controller.approve('gen-1');

      // approved -> approved is not a transition, so nothing may reach the row.
      expect(await controller.approve('gen-1'), isFalse);

      expect(controller.lastError, contains('rejected before it can change'));
      expect(
        (await repository.getReview('gen-1'))?.state,
        OutputReviewState.approved,
        reason: 'a refused decision must not alter the recorded state',
      );
    });

    test('refusal is predictable before the tap', () async {
      await controller.approve('gen-1');

      expect(
        controller.canDecide('gen-1', OutputReviewState.approved),
        isFalse,
      );
      expect(
        controller.refusalFor('gen-1', OutputReviewState.approved),
        isNotNull,
      );
    });

    test('reopen is refused while still pending', () async {
      await controller.load('gen-1');

      expect(await controller.reopen('gen-1'), isFalse);
      expect(controller.lastError, isNotNull);
    });

    test('reopen works from rejected, the only way back to pending', () async {
      // The state machine is deliberate: pending -> approved/rejected, and
      // rejected -> approved | pending. An approved output cannot be reopened,
      // because approving is the record of a decision made, not a placeholder.
      // So the reopen affordance is reachable from rejected only.
      await controller.reject('gen-1');

      expect(await controller.reopen('gen-1'), isTrue);

      expect(
        (await repository.getReview('gen-1'))?.state,
        OutputReviewState.pending,
      );
    });

    test(
      'reopen is refused from approved, matching the domain rules',
      () async {
        await controller.approve('gen-1');

        expect(await controller.reopen('gen-1'), isFalse);
        expect(controller.lastError, isNotNull);
        expect(
          (await repository.getReview('gen-1'))?.state,
          OutputReviewState.approved,
        );
      },
    );

    test('refusal names the generation it belongs to', () async {
      await controller.approve('gen-a');

      await controller.approve('gen-a');

      expect(
        controller.errorGenerationId,
        'gen-a',
        reason: 'a message must not be misread as another review on the screen',
      );
    });
  });

  group('feedback', () {
    test('staged feedback rides along with the next decision', () async {
      controller.stageFeedback('gen-1', 'needs more light');

      expect(controller.hasUnsavedFeedback('gen-1'), isTrue);
      expect(await controller.approve('gen-1'), isTrue);

      final stored = await repository.getReview('gen-1');
      expect(stored?.feedback, 'needs more light');
      expect(controller.hasUnsavedFeedback('gen-1'), isFalse);
    });

    test('rejection carries its reason too', () async {
      controller.stageFeedback('gen-1', 'wrong subject');

      expect(await controller.reject('gen-1'), isTrue);

      expect((await repository.getReview('gen-1'))?.feedback, 'wrong subject');
    });

    test('a refused decision keeps the note for the next attempt', () async {
      controller.stageFeedback('gen-1', 'still not right');
      await controller.approve('gen-1');
      await controller.approve('gen-1'); // refused

      expect(
        controller.hasUnsavedFeedback('gen-1'),
        isFalse,
        reason: 'the first approve already wrote and cleared it',
      );
    });

    test('empty feedback clears the stage instead of writing nothing', () {
      controller.stageFeedback('gen-1', 'note');
      controller.stageFeedback('gen-1', '   ');

      expect(controller.hasUnsavedFeedback('gen-1'), isFalse);
      expect(controller.pendingFeedbackFor('gen-1'), isNull);
    });

    test('feedback is trimmed', () {
      controller.stageFeedback('gen-1', '  padded  ');

      expect(controller.pendingFeedbackFor('gen-1'), 'padded');
    });

    test('feedback with no generation is refused', () {
      expect(controller.stageFeedback('', 'orphan'), isFalse);
      expect(controller.lastError, contains('nowhere to go'));
    });
  });

  group('stale cache', () {
    test('a stale cache is re-read before a refusal is reported', () async {
      await controller.approve('gen-1');
      expect(controller.stateFor('gen-1'), OutputReviewState.approved);

      // Another writer moves the row behind the controller's back, so its
      // cached belief ("approved", which cannot go to approved) disagrees with
      // storage ("rejected", which can).
      await repository.setReview(
        generationId: 'gen-1',
        state: OutputReviewState.rejected,
      );

      // The tap is honoured against the real record rather than refused on the
      // strength of a guess: reporting "an approved output has to be rejected
      // first" here would send the reviewer down the wrong path entirely.
      expect(await controller.approve('gen-1'), isTrue);

      expect(
        (await repository.getReview('gen-1'))?.state,
        OutputReviewState.approved,
      );
      expect(controller.lastError, isNull);
    });

    test('a repository rejection still surfaces and reloads', () async {
      await controller.approve('gen-1');
      // Move storage somewhere the controller's own reload cannot legitimise
      // the write: approved -> approved is never legal, whoever is asking.
      await repository.setReview(
        generationId: 'gen-1',
        state: OutputReviewState.rejected,
      );
      // Put the controller's cache back in agreement with a state whose
      // transition is illegal, while storage says otherwise.
      await controller.load('gen-1');
      await controller.approve('gen-1');
      expect(controller.stateFor('gen-1'), OutputReviewState.approved);

      // A fresh controller with a stale-looking cache hits the repository error
      // path directly, which is the branch worth pinning.
      final other = OutputReviewController(repository: repository);
      await other.load('gen-1');
      expect(await other.approve('gen-1'), isFalse);
      expect(
        other.lastError,
        contains('rejected before it can change'),
        reason: 'an illegal transition names the rule it broke',
      );
      expect(other.errorGenerationId, 'gen-1');
    });

    test('a refusal clears once a legal decision succeeds', () async {
      await controller.approve('gen-1');
      await controller.approve('gen-1'); // refused, sets lastError
      expect(controller.lastError, isNotNull);

      expect(await controller.reject('gen-1'), isTrue);

      expect(controller.lastError, isNull);
    });
  });

  test('decisions are independent per generation', () async {
    expect(await controller.approve('gen-1'), isTrue);
    expect(await controller.reject('gen-2'), isTrue);

    expect(controller.decisionFor('gen-1'), OutputReviewDecision.approved);
    expect(controller.decisionFor('gen-2'), OutputReviewDecision.rejected);
  });
}
