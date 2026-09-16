import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('112.2 freezes the 29 unique concepts and RC non-goals', () {
    final file = File('docs/planning/v1.2/sprint_112_scope_contract.md');
    expect(file.existsSync(), isTrue);
    final document = file.readAsStringSync();
    final lower = document.toLowerCase();

    expect(lower, contains('scope freeze & non-goals'));
    expect(lower, contains('29 konsep unik'));
    expect(lower, contains('f30'));
    expect(lower, contains('alias'));
    expect(lower, contains('non-goals'));
    expect(lower, contains('deferred'));
    expect(lower, contains('exception process'));
    expect(lower, contains('feature flag'));
    expect(lower, contains('local-first'));
    expect(lower, contains('tidak ada automatic canon mutation'));
    expect(lower, contains('tidak ada perluasan fitur baru'));

    for (final capability in <String>[
      'Inline Lore Linking',
      'Story Contradiction Detector',
      'Travel & Logistics Simulation',
      'Character Voice Interview',
      'Custom Calendar & Celestial Time',
      'Genealogy Tree',
      'Constructed Language Dictionary',
      'Focus Writing, Word Targets & Draft Snapshots',
      'Global Lore Graph',
      'Kanban Plot Board',
      'Temporal World Map',
      'Character Visual Moodboard',
      'Faction Diplomacy Grid',
      'Automatic Character Age & Location Tracker',
      'Power-System Guardrails',
      'Spoiler-Aware Sharing',
      'POV Consistency Tracker',
      'Pacing & Tension Heatmap',
      'Clean Manuscript Export',
      'Fiction Economy & Inflation Calculator',
      'Rumor Propagation',
      'Technology Tree & Civilization Limits',
      'Herbology & Alchemy Database',
      'Bestiary Journal',
      'Subplot, Mission & Quest Tracker',
      'Artifacts & Ancient Relics',
      'Myth, Legend & Theology Archive',
      'Syllable-Based Name Generator',
      'Local Idiom & Proverb Bank',
    ]) {
      expect(document, contains(capability));
    }
  });
}
