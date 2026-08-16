import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/creative/idea/idea_bank.dart';

void main() {
  test('Idea holds fields', () {
    const idea = Idea(
      id: 'i1',
      title: 'Void Warden rises',
      description: 'A warden awakens',
      tags: ['character', 'origin'],
    );
    expect(idea.title, 'Void Warden rises');
    expect(idea.tags, hasLength(2));
  });

  test('IdeaBank adds and queries by tag', () {
    final bank = IdeaBank();
    bank.add(
      const Idea(
        id: 'i1',
        title: 'Void Warden rises',
        description: 'A warden awakens',
        tags: ['character'],
      ),
    );
    expect(bank.queryByTag('character'), hasLength(1));
    expect(bank.queryByTag('location'), isEmpty);
  });

  test('IdeaBank dedupes by title', () {
    final bank = IdeaBank();
    bank.add(const Idea(id: 'i1', title: 'Same', description: 'a', tags: []));
    bank.add(const Idea(id: 'i2', title: 'Same', description: 'b', tags: []));
    expect(bank.all, hasLength(1));
  });
}
