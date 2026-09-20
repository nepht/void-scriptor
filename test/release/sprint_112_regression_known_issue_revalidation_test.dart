import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('112.41 records executable regression and known-issue outcomes', () {
    final file = File(
      'docs/planning/v1.2/sprint_112_regression_known_issue_revalidation.json',
    );
    expect(
      file.existsSync(),
      isTrue,
      reason: '112.41 result manifest must exist',
    );

    final document =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(document['canonical_step'], '112.41');
    expect(
      document.keys,
      containsAll(<String>[
        'regression_results',
        'known_issue_results',
        'reopened_issues',
        'new_issues',
        'release_blockers',
      ]),
    );

    final regressions = (document['regression_results'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(regressions, hasLength(greaterThanOrEqualTo(4)));
    for (final result in regressions) {
      expect(result['status'], 'PASS');
      expect(result['test_refs'], isNotEmpty);
      expect(result['command'], isNotEmpty);
    }

    final knownIssues = (document['known_issue_results'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(knownIssues, isNotEmpty);
    for (final issue in knownIssues) {
      expect(issue.keys, containsAll(<String>['id', 'disposition', 'owner']));
      expect(
        issue['disposition'],
        isIn(<String>['RESOLVED', 'ACCEPTED', 'DEFERRED', 'BLOCKED']),
      );
    }

    expect(document['reopened_issues'], isEmpty);
    expect(document['new_issues'], isEmpty);
    expect(document['release_blockers'], isEmpty);
    expect(document['decision'], 'PASS_LOCAL_WITH_ACCEPTED_LIMITATIONS');
  });
}
