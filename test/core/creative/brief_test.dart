import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/creative/brief/creative_brief.dart';

void main() {
  test('CreativeBrief holds fields', () {
    const brief = CreativeBrief(
      id: 'b1',
      title: 'The Void Warden',
      genre: 'dark fantasy',
      tone: 'melancholic',
      goals: ['worldbuild', 'publish'],
    );
    expect(brief.title, 'The Void Warden');
    expect(brief.goals, hasLength(2));
  });

  test('CreativeBrief validation rejects empty title', () {
    const brief = CreativeBrief(
      id: 'b1',
      title: '',
      genre: 'fantasy',
      tone: 'dark',
      goals: [],
    );
    expect(brief.isValid, isFalse);
  });

  test('CreativeBrief.fromMap', () {
    final brief = CreativeBrief.fromMap(const {
      'id': 'b1',
      'title': 'Void',
      'genre': 'fantasy',
      'tone': 'dark',
      'goals': ['publish'],
    });
    expect(brief.title, 'Void');
    expect(brief.goals, ['publish']);
  });
}
