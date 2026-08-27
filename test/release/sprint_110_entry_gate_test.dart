import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('110.1 entry gate records all required evidence and boundaries', () {
    final file = File('docs/planning/v1.2/sprint_110_entry_gate.md');
    expect(file.existsSync(), isTrue);
    final document = file.readAsStringSync();

    for (final evidence in <String>[
      'sprint_109_acceptance',
      'stable_entity_ids',
      'stable_timeline_contract',
      'migration_readiness',
      'risk_register',
    ]) {
      expect(document, contains(evidence));
    }

    expect(document, contains('1.2.0-alpha.1'));
    expect(document, contains('110.2'));
    expect(document, contains('D-SCHEMA-01'));
    expect(document, contains('NO-GO'));
    expect(document, contains('**no source\n  mutation**'));
  });
}
