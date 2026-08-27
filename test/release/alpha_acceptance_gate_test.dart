import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    '109.51 acceptance gate records all required evidence and honest scope',
    () {
      final gate = File(
        'docs/release/v1.2.0-alpha.1-acceptance-gate.md',
      ).readAsStringSync();
      expect(gate, contains('**Decision:** `GO_WITH_DOCUMENTED_RISK`'));
      expect(gate, contains('**Public/production release:** `NO-GO`'));
      for (final evidence in <String>[
        'Feature acceptance',
        'Test results',
        'Migration results',
        'Performance results',
        'Security review',
        'Accessibility review',
        'Known issues',
        'Rollback readiness',
      ]) {
        expect(gate, contains(evidence));
      }
      expect(gate, contains('1.2.0-alpha.1'));
      expect(gate, contains('D-SCHEMA-01'));
      expect(gate, contains('No push or tag'));
    },
  );
}
