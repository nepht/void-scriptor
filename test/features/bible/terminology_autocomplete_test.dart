import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/bible/application/terminology_autocomplete.dart';
import 'package:void_scriptor/features/bible/domain/terminology.dart';

void main() {
  final entries = [
    const TerminologyEntryModel(
      id: 't1',
      projectId: 'p1',
      term: 'Voidling',
      definition: 'Inhabitants of the Void.',
      category: 'species',
      alternateTerms: 'void-kin, voidfolk',
    ),
    const TerminologyEntryModel(
      id: 't2',
      projectId: 'p1',
      term: 'Void Gate',
      definition: 'Portal between realms.',
      category: 'location',
    ),
    const TerminologyEntryModel(
      id: 't3',
      projectId: 'p1',
      term: 'Aether',
      definition: 'Raw energy.',
      caseSensitive: true,
    ),
  ];

  test('suggests terms matching a case-insensitive prefix', () {
    const service = TerminologyAutocomplete();
    final results = service.suggest(entries, query: 'void');

    expect(results.map((t) => t.term), containsAll(['Voidling', 'Void Gate']));
  });

  test('matches alternate terms', () {
    const service = TerminologyAutocomplete();
    final results = service.suggest(entries, query: 'void-kin');

    expect(results.map((t) => t.term), contains('Voidling'));
  });

  test('respects case sensitivity for flagged terms', () {
    const service = TerminologyAutocomplete();
    final results = service.suggest(entries, query: 'aether');
    expect(results, isEmpty);

    final exact = service.suggest(entries, query: 'Aether');
    expect(exact.map((t) => t.term), contains('Aether'));
  });
}
