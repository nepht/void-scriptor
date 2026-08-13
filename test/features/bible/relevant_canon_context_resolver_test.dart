import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/bible/application/relevant_canon_context_resolver.dart';
import 'package:void_scriptor/features/bible/domain/bible_entry.dart';
import 'package:void_scriptor/features/story/domain/canon_status.dart';

void main() {
  final now = DateTime.utc(2026, 8, 14);

  test(
    'resolver keeps project scoped global and relevant canon entries only',
    () {
      final entries = [
        BibleEntry(
          id: 'global',
          projectId: 'p1',
          type: BibleEntryType.canonRule,
          title: 'Void Black',
          content: 'Cannot be created artificially.',
          tags: const ['void', 'power'],
          createdAt: now,
          updatedAt: now,
        ),
        BibleEntry(
          id: 'character',
          projectId: 'p1',
          type: BibleEntryType.lore,
          title: 'Reika Canon',
          content: 'Reika survived the fall.',
          tags: const ['reika', 'clan-kokuen'],
          createdAt: now,
          updatedAt: now,
        ),
        BibleEntry(
          id: 'other-project',
          projectId: 'p2',
          type: BibleEntryType.lore,
          title: 'Leak',
          content: 'Must not appear.',
          createdAt: now,
          updatedAt: now,
        ),
        BibleEntry(
          id: 'deprecated',
          projectId: 'p1',
          type: BibleEntryType.lore,
          title: 'Old canon',
          content: 'Deprecated.',
          status: CanonStatus.deprecated,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final result = RelevantCanonContextResolver().resolve(
        entries,
        projectId: 'p1',
        entityIds: const {'reika'},
        tags: const {'reika'},
      );

      expect(
        result.map((item) => item.id),
        containsAll(<String>['global', 'character']),
      );
      expect(result.map((item) => item.id), isNot(contains('other-project')));
      expect(result.map((item) => item.id), isNot(contains('deprecated')));
      expect(result.length, 2);
    },
  );

  test('resolver enforces deterministic result limit and ordering', () {
    final entries = List.generate(
      5,
      (index) => BibleEntry(
        id: 'entry-$index',
        projectId: 'p1',
        type: BibleEntryType.lore,
        title: 'Entry $index',
        content: 'Content',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final result = RelevantCanonContextResolver().resolve(
      entries,
      projectId: 'p1',
      entityIds: const {'entry-0', 'entry-1', 'entry-2', 'entry-3', 'entry-4'},
      limit: 3,
    );

    expect(result.length, 3);
    expect(result.map((item) => item.id).toList(), [
      'entry-0',
      'entry-1',
      'entry-2',
    ]);
  });
}
