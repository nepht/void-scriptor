import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/bible/domain/bible_entry.dart';
import 'package:void_scriptor/features/story/domain/canon_status.dart';

void main() {
  test('BibleEntry preserves canon metadata and immutable tags', () {
    final created = DateTime.utc(2026, 8, 13);
    final entry = BibleEntry(
      id: 'entry-1',
      projectId: 'project-1',
      type: BibleEntryType.faction,
      title: 'Clan Kokuen',
      content: 'A surviving void clan.',
      createdAt: created,
      updatedAt: created,
      tags: ['clan', 'void'],
    );

    expect(entry.type, BibleEntryType.faction);
    expect(entry.status, CanonStatus.canon);
    expect(entry.tags, ['clan', 'void']);
  });
}
