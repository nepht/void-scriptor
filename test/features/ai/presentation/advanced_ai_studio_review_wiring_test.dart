// Advanced AI studio review wiring tests.
//
// The old wiring passed `() {}` for approve, reject, and feedback: the buttons
// rendered, the panel test passed, and a reviewer clicking Approve changed
// nothing at all. A presence test cannot catch that, so these assert on what
// the screen *does* - whether a row is written, and whether a control that
// cannot act says so instead of swallowing the tap.
//
// The controller is real and the database is a real in-memory ProjectDatabase.
// A fake here would be a fake for the thing under test.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/ai/application/output_review_controller.dart';
import 'package:void_scriptor/features/ai/application/output_review_repository.dart';
import 'package:void_scriptor/features/ai/domain/output_review.dart';
import 'package:void_scriptor/features/ai/presentation/advanced_ai_studio_screen.dart';

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

  Future<void> pumpStudio(
    WidgetTester tester, {
    OutputReviewController? reviewController,
    String? generationId,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdvancedAiStudioScreen(
          reviewController: reviewController ?? controller,
          reviewedGenerationId: generationId ?? 'gen-1',
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('a decision actually reaches storage', () {
    testWidgets('tapping Approve writes an approved row', (tester) async {
      await pumpStudio(tester);

      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();

      expect(
        (await repository.getReview('gen-1'))?.state,
        OutputReviewState.approved,
      );
      expect(find.textContaining('Recorded approved'), findsOneWidget);
    });

    testWidgets('tapping Reject writes a rejected row', (tester) async {
      await pumpStudio(tester);

      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();

      expect(
        (await repository.getReview('gen-1'))?.state,
        OutputReviewState.rejected,
      );
    });

    testWidgets('the screen names the generation under review', (tester) async {
      await pumpStudio(tester);

      expect(
        find.textContaining('Reviewing generation gen-1'),
        findsOneWidget,
        reason: 'a reviewer must know what they are approving',
      );
    });

    testWidgets('feedback typed before a decision rides along with it', (
      tester,
    ) async {
      await pumpStudio(tester);

      // The panel only hands feedback to the controller when it is sent, so
      // typing on its own stages nothing and must not claim otherwise.
      await tester.enterText(
        find.widgetWithText(TextField, 'Feedback for regeneration'),
        'needs more light',
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Unsaved feedback'),
        findsNothing,
        reason: 'a note still sitting in the field is not staged yet',
      );

      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Unsaved feedback'),
        findsOneWidget,
        reason: 'a staged note must not look like it was saved',
      );

      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();

      expect(
        (await repository.getReview('gen-1'))?.feedback,
        'needs more light',
      );
    });
  });

  group('a control that cannot act says so', () {
    testWidgets('with no controller the reason is on screen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AdvancedAiStudioScreen()),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('no review store is connected'),
        findsOneWidget,
      );
      expect(
        find.text('Approve'),
        findsNothing,
        reason: 'a control with nowhere to write is not offered at all',
      );
    });

    testWidgets('with no generation the reason is on screen', (tester) async {
      await pumpStudio(tester, generationId: '   ');

      expect(find.textContaining('no generation is selected'), findsOneWidget);
      expect(find.text('Approve'), findsNothing);
    });

    testWidgets('a refused decision shows the reason, not a fake success', (
      tester,
    ) async {
      await pumpStudio(tester);
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Recorded approved'), findsOneWidget);

      // The second approve is not a legal transition; the screen has to say so
      // rather than reporting a success that never happened.
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('has to be rejected before it can change again'),
        findsOneWidget,
        reason: 'a refusal must name the rule it broke, not report success',
      );
      expect(
        find.textContaining('Recorded approved'),
        findsNothing,
        reason: 'the stale success message must be cleared once refused',
      );
      expect(
        (await repository.getReview('gen-1'))?.state,
        OutputReviewState.approved,
        reason: 'a refused decision must not alter the stored row',
      );
    });
  });

  testWidgets('sections still render with review wired', (tester) async {
    await pumpStudio(tester);

    expect(find.text('Advanced AI Studio'), findsOneWidget);
    expect(find.text('Output'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Usage'), findsOneWidget);
  });
}
