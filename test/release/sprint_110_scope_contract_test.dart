import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('110.2 scope contract lists ten capabilities and hard boundaries', () {
    final file = File('docs/planning/v1.2/sprint_110_scope_contract.md');
    expect(file.existsSync(), isTrue);
    final document = file.readAsStringSync();

    for (final capability in <String>[
      'Travel & Logistics Simulation',
      'Custom Calendar & Celestial Time',
      'Genealogy Tree',
      'Temporal World Map',
      'Faction Diplomacy Grid',
      'Automatic Character Age & Location Tracker',
      'Power-System Guardrails',
      'Fiction Economy & Inflation Calculator',
      'Rumor Propagation',
      'Technology Tree & Civilization Limits',
    ]) {
      expect(document, contains(capability));
    }
    for (final boundary in <String>[
      'non-goals',
      'dependenc',
      'acceptance boundary',
      'feature flag',
      'local-first',
      'backward compatibility',
      'D-SCHEMA-01',
    ]) {
      expect(document.toLowerCase(), contains(boundary.toLowerCase()));
    }
    expect(document, contains('110.3'));
    expect(document, contains('no automatic canon mutation'));
  });
}
