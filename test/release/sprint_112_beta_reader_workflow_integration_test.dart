import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/spoiler/domain/reader_redaction.dart';
import 'package:void_scriptor/features/spoiler/domain/spoiler_classification.dart';
import 'package:void_scriptor/features/world_logic/domain/end_to_end_beta_reader_workflow.dart';

void main() {
  test(
    '112.35 runs clearance, sharing, comments, revoke, and sanitization',
    () {
      final registry = SpoilerRegistry()
        ..addAudience(const SpoilerAudience('beta-clean', SpoilerLevel.clean))
        ..classify('ending', SpoilerLevel.major);
      final redactor = ReaderRedactor(registry: registry);
      final workflow = EndToEndBetaReaderWorkflow(redactor: redactor);
      redactor.grant(readerId: 'reader-1', audience: 'beta-clean');

      final result = workflow.run(
        const BetaReaderWorkflowInput(
          documentId: 'novel-1',
          title: 'Ash Coast',
          readerId: 'reader-1',
          audienceId: 'beta-clean',
          currentScene: 'chapter-1',
          sections: [
            BetaReaderSection(id: 'opening', text: 'Public prose.'),
            BetaReaderSection(
              id: 'ending',
              text: 'The hidden ending.',
              spoilerItemId: 'ending',
            ),
          ],
          metadata: {'internalPath': 'D:/private/project'},
          comment: 'The opening is clear.',
        ),
      );

      expect(result.audienceProfiles, contains('beta-clean'));
      expect(result.redactionResults, contains('[disensor]'));
      expect(result.shareResults, contains('Public prose.'));
      expect(result.shareResults, isNot(contains('The hidden ending.')));
      expect(result.commentResults, contains('The opening is clear.'));
      expect(result.leakageTests, isTrue);
      expect(result.revocationResults, isTrue);
      expect(result.sanitizedShare, isNot(contains('internalPath')));
      expect(result.sanitizedShare, isNot(contains('reader-1')));

      final decoded = jsonDecode(result.sanitizedShare) as Map<String, dynamic>;
      expect(
        decoded.keys,
        containsAll(<String>['documentId', 'title', 'entries']),
      );
    },
  );

  test('112.35 fails closed for blank identity and revoked reader', () {
    final registry = SpoilerRegistry()
      ..addAudience(const SpoilerAudience('beta', SpoilerLevel.clean));
    final redactor = ReaderRedactor(registry: registry);
    final workflow = EndToEndBetaReaderWorkflow(redactor: redactor);

    expect(
      () => workflow.run(
        const BetaReaderWorkflowInput(
          documentId: '',
          title: 'Ash Coast',
          readerId: 'reader-1',
          audienceId: 'beta',
          currentScene: 'chapter-1',
          sections: [BetaReaderSection(id: 's1', text: 'Text')],
          comment: 'Comment',
        ),
      ),
      throwsArgumentError,
    );

    redactor.grant(readerId: 'reader-1', audience: 'beta');
    redactor.revoke('reader-1');
    expect(
      () => workflow.run(
        const BetaReaderWorkflowInput(
          documentId: 'doc',
          title: 'Ash Coast',
          readerId: 'reader-1',
          audienceId: 'beta',
          currentScene: 'chapter-1',
          sections: [BetaReaderSection(id: 's1', text: 'Text')],
          comment: 'Comment',
        ),
      ),
      throwsStateError,
    );
  });
}
