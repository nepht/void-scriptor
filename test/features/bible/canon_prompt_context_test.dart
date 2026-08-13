import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/bible/application/canon_prompt_context.dart';
import 'package:void_scriptor/features/bible/domain/bible_entry.dart';

void main() {
  test('prompt context composes bounded canon block with source labels', () {
    final now = DateTime.utc(2026, 8, 14);
    final context = CanonPromptContextComposer().compose([
      BibleEntry(
        id: 'rule-1',
        projectId: 'p1',
        type: BibleEntryType.canonRule,
        title: 'Void Black rule',
        content: 'Cannot be created artificially.',
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    expect(context, contains('[RELEVANT CANON CONTEXT]'));
    expect(context, contains('Void Black rule'));
    expect(context, contains('Cannot be created artificially.'));
    expect(context, contains('Do not invent facts'));
  });

  test('empty context returns explicit empty marker', () {
    expect(
      CanonPromptContextComposer().compose(const []),
      '[RELEVANT CANON CONTEXT]\n(none)',
    );
  });
}
