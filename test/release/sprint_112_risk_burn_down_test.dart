import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('112.7 records owned risk decisions with executable evidence', () {
    final file = File('docs/planning/v1.2/sprint_112_risk_burn_down.json');
    expect(file.existsSync(), isTrue, reason: '112.7 risk register must exist');

    final document =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(document['canonical_step'], '112.7');
    expect(document['release_channel'], 'v1.2.0-rc.1');
    expect(document['claim_boundary'], isNotEmpty);

    final risks = document['risks'] as List<dynamic>;
    expect(risks, isNotEmpty);
    final categories = <String>{};
    final ids = <String>{};
    for (final rawRisk in risks) {
      final risk = rawRisk as Map<String, dynamic>;
      expect(
        risk.keys,
        containsAll(<String>[
          'id',
          'category',
          'risk',
          'severity',
          'likelihood',
          'mitigation',
          'owner',
          'evidence',
          'residual_risk',
          'decision',
        ]),
      );
      expect(ids.add(risk['id'] as String), isTrue);
      expect(categories.add(risk['category'] as String), isTrue);
      expect(risk['risk'], isNotEmpty);
      expect(risk['mitigation'], isNotEmpty);
      expect(risk['owner'], isNotEmpty);
      expect(risk['evidence'], isA<List<dynamic>>());
      expect((risk['evidence'] as List<dynamic>), isNotEmpty);
      expect(risk['residual_risk'], isNotEmpty);
      expect(risk['decision'], isIn(<String>['mitigate', 'accept', 'defer']));
    }

    expect(
      categories,
      containsAll(<String>[
        'product',
        'data',
        'security',
        'performance',
        'accessibility',
        'compatibility',
      ]),
    );
  });
}
