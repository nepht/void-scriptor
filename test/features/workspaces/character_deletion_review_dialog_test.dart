import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/character/presentation/widgets/character_deletion_review_dialog.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_character_deletion_service.dart';

void main() {
  Future<void> openDialog(
    WidgetTester tester,
    Future<CharacterDeletionReview> Function() loadReview,
    ValueChanged<CharacterDeletionDecision?> onPopped, {
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                final decision = await showCharacterDeletionReviewDialog(
                  context: context,
                  loadReview: loadReview,
                );
                onPopped(decision);
              },
              child: const Text('OPEN'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  CharacterDeletionReview reviewWith(List<String> novelIds) =>
      CharacterDeletionReview(
        characterWorkspaceId: 'character-1',
        affectedNovelWorkspaceIds: novelIds,
        availableDecisions: const {CharacterDeletionDecision.unlink},
      );

  testWidgets(
    'shows loading, then affected novels with disabled confirm until explicit unlink choice',
    (tester) async {
      final completer = Completer<CharacterDeletionReview>();
      await openDialog(tester, () => completer.future, (_) {}, settle: false);
      expect(find.text('Reviewing linked novels…'), findsOneWidget);

      completer.complete(reviewWith(const ['novel-a', 'novel-b']));
      await tester.pumpAndSettle();

      expect(find.text('novel-a'), findsOneWidget);
      expect(find.text('novel-b'), findsOneWidget);
      final confirmBefore = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Delete Character'),
      );
      expect(confirmBefore.onPressed, isNull);

      await tester.tap(
        find.text('Unlink from all listed Novels (keep their content)'),
      );
      await tester.pump();

      final confirmAfter = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Delete Character'),
      );
      expect(confirmAfter.onPressed, isNotNull);
    },
  );

  testWidgets(
    'empty link list explains no-unlink and enables confirm directly',
    (tester) async {
      CharacterDeletionDecision? popped;
      await openDialog(
        tester,
        () async => reviewWith(const []),
        (d) => popped = d,
      );

      expect(
        find.text(
          'This character has no Novel links. Nothing will be unlinked.',
        ),
        findsOneWidget,
      );
      final confirm = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Delete Character'),
      );
      expect(confirm.onPressed, isNotNull);

      await tester.tap(find.text('Delete Character'));
      await tester.pumpAndSettle();
      expect(popped, CharacterDeletionDecision.unlink);
      expect(find.byType(Dialog), findsNothing);
    },
  );

  testWidgets('confirm pops the explicitly chosen unlink decision and closes', (
    tester,
  ) async {
    CharacterDeletionDecision? popped;
    await openDialog(
      tester,
      () async => reviewWith(const ['novel-a']),
      (d) => popped = d,
    );
    await tester.tap(
      find.text('Unlink from all listed Novels (keep their content)'),
    );
    await tester.pump();
    await tester.tap(find.text('Delete Character'));
    await tester.pumpAndSettle();

    expect(popped, CharacterDeletionDecision.unlink);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('cancel pops null without deciding', (tester) async {
    CharacterDeletionDecision? popped = CharacterDeletionDecision.unlink;
    await openDialog(
      tester,
      () async => reviewWith(const ['novel-a']),
      (d) => popped = d,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(popped, isNull);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets(
    'load failure surfaces an error state instead of pretending success',
    (tester) async {
      await openDialog(
        tester,
        () async => throw StateError('no session'),
        (_) {},
      );
      expect(find.text('Failed to load deletion review.'), findsOneWidget);
      final confirm = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Delete Character'),
      );
      expect(confirm.onPressed, isNull);
    },
  );
}
