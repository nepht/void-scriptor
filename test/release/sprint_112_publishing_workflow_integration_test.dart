import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/end_to_end_publishing_workflow.dart';

void main() {
  test('112.36 preflights and renders clean DOCX, text, and web outputs', () {
    const input = PublishingWorkflowInput(
      title: 'The Void',
      author: 'Choirudin',
      chapters: <PublishingChapter>[
        PublishingChapter(
          title: 'Arrival',
          body: 'Neon rain [[PRIVATE:editor note]] over [[Harbor]].',
        ),
      ],
    );

    final result = const EndToEndPublishingWorkflow().run(input);

    expect(result.preflight.isAccepted, isTrue);
    expect(
      result.outputs.keys,
      containsAll(<PublishingFormat>[
        PublishingFormat.docx,
        PublishingFormat.plainText,
        PublishingFormat.webNovel,
      ]),
    );
    expect(result.outputs[PublishingFormat.plainText], contains('Neon rain'));
    expect(result.outputs[PublishingFormat.plainText], contains('Harbor.'));
    expect(result.outputs[PublishingFormat.webNovel], contains('<article>'));
    expect(result.outputs[PublishingFormat.docx], contains('<w:document'));
    for (final output in result.outputs.values) {
      expect(output, isNot(contains('PRIVATE')));
      expect(output, isNot(contains('internal')));
    }
    expect(result.isAccepted, isTrue);
  });

  test('112.36 fails closed for empty title and metadata-shaped content', () {
    const workflow = EndToEndPublishingWorkflow();
    expect(
      () => workflow.run(
        const PublishingWorkflowInput(
          title: ' ',
          author: 'Choirudin',
          chapters: <PublishingChapter>[],
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => workflow.run(
        const PublishingWorkflowInput(
          title: 'The Void',
          author: 'Choirudin',
          chapters: <PublishingChapter>[
            PublishingChapter(
              title: 'Chapter',
              body: '<internal>secret</internal>',
            ),
          ],
        ),
      ),
      throwsArgumentError,
    );
  });
}
