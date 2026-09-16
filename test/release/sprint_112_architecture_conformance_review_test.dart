import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('112.4 records all architecture review areas with live evidence', () {
    final file = File(
      'docs/planning/v1.2/sprint_112_architecture_conformance_review.json',
    );
    expect(file.existsSync(), isTrue, reason: '112.4 review must exist');

    final document =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(document['canonical_step'], '112.4');
    expect(document['claim_boundary'], contains('local architecture review'));

    final reviews = (document['reviews'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(reviews.map((review) => review['area']).toSet(), <String>{
      'module_boundaries',
      'data_ownership',
      'dependency_cycles',
      'event_contracts',
      'plugin_boundaries',
      'failure_isolation',
    });

    const allowedStatuses = <String>{'CONFORMANT', 'PARTIAL', 'NON_CONFORMANT'};
    for (final review in reviews) {
      expect(
        review.keys,
        containsAll(<String>['status', 'evidence', 'findings']),
      );
      expect(allowedStatuses, contains(review['status']));
      expect((review['evidence'] as List<dynamic>), isNotEmpty);
      expect((review['findings'] as List<dynamic>), isNotEmpty);
      for (final evidence in (review['evidence'] as List<dynamic>)) {
        final path = (evidence as Map<String, dynamic>)['path'] as String;
        expect(
          FileSystemEntity.typeSync(path),
          isNot(FileSystemEntityType.notFound),
          reason: 'architecture evidence must exist: $path',
        );
      }
    }

    final summary = document['summary'] as Map<String, dynamic>;
    expect(summary['reviewed_areas'], 6);
    expect(summary['release_decision'], 'NO_GO');
    expect(summary['blocking_findings'], isNotEmpty);
  });
}
