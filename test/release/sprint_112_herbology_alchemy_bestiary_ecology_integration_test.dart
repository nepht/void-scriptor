import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('112.21 manifest maps all canonical integration acceptance', () {
    final file = File(
      'docs/planning/v1.2/sprint_112_herbology_alchemy_bestiary_ecology_integration.json',
    );
    expect(file.existsSync(), isTrue);
    final document =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(document['step'], '112.21');
    expect(document['status'], 'VERIFIED-LOCAL');
    expect(
      (document['acceptance'] as List<dynamic>).map(
        (entry) => (entry as Map<String, dynamic>)['id'],
      ),
      containsAll(<String>[
        'ingredient_sources',
        'harvest_materials',
        'habitat_links',
        'seasonal_availability',
        'recipe_effects',
        'ecological_consequences',
      ]),
    );
  });
}
