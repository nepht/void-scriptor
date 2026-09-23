/// Test for Issue Deduplication & Root Cause (Step 113.29).
/// Validates the seven canonical required_fields — issue_id, duplicates,
/// reproduction, component, root_cause, affected_versions, owner — plus the
/// merge of duplicate reports and the blocked/fail/pass decision.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/issue_deduplication_root_cause.dart';

void main() {
  final registry = IssueRegistry();

  group('113.29 Issue Deduplication & Root Cause', () {
    test('complete report carries all seven canonical fields', () {
      const report = IssueReport(
        issueId: 'ISS-001',
        duplicates: <String>[],
        reproduction: <String>[
          'buka project fixture',
          'tekan export dua kali cepat',
          'amati dialog ganda',
        ],
        component: 'export/dialog_flow',
        rootCause: 'ExportDialog tidak mengunci state submitting.',
        affectedVersions: <String>['1.2.0', '1.2.1'],
        owner: 'cron-core-worker-v4',
      );

      expect(IssueReport.requiredFieldNames, <String>[
        'issue_id',
        'duplicates',
        'reproduction',
        'component',
        'root_cause',
        'affected_versions',
        'owner',
      ]);
      expect(registry.missingFields(report), isEmpty);
    });

    test('missing fields are reported by canonical name', () {
      const bare = IssueReport(
        issueId: 'ISS-002',
        duplicates: <String>[],
        reproduction: <String>[],
        component: '',
        rootCause: '',
        affectedVersions: <String>[],
        owner: '',
      );

      expect(registry.missingFields(bare), <String>[
        'reproduction',
        'component',
        'root_cause',
        'affected_versions',
        'owner',
      ]);
    });

    test('blank issue_id is reported as issue_id', () {
      const noId = IssueReport(
        issueId: ' ',
        duplicates: <String>['ISS-9'],
        reproduction: <String>['langkah'],
        component: 'c',
        rootCause: 'r',
        affectedVersions: <String>['1.2.0'],
        owner: 'o',
      );
      expect(registry.missingFields(noId), <String>['issue_id']);
    });

    test('empty registry is blocked pending collected reports', () {
      final decision = registry.evaluate();
      expect(decision.decision, IssueDecision.blocked);
      expect(decision.reportCount, 0);
      expect(decision.limitations.join(' '), isNotEmpty);
    });

    test('merge folds duplicate reports into the canonical report', () {
      final merged = IssueRegistry()
        ..add(
          const IssueReport(
            issueId: 'ISS-100',
            duplicates: <String>[],
            reproduction: <String>['langkah A'],
            component: 'timeline/clip',
            rootCause: 'clamp negatif pada maxStart.',
            affectedVersions: <String>['1.2.0'],
            owner: 'nephthys',
          ),
        )
        ..add(
          const IssueReport(
            issueId: 'ISS-101',
            duplicates: <String>[],
            reproduction: <String>['langkah B'],
            component: 'timeline/clip',
            rootCause: 'clamp negatif pada maxStart.',
            affectedVersions: <String>['1.2.1'],
            owner: 'nephthys',
          ),
        );

      final canonical = merged.mergeDuplicates('ISS-100', <String>['ISS-101']);

      expect(canonical.issueId, 'ISS-100');
      expect(canonical.duplicates, <String>['ISS-101']);
      expect(canonical.reproduction, <String>['langkah A', 'langkah B']);
      expect(canonical.affectedVersions, <String>['1.2.0', '1.2.1']);
      expect(merged.duplicateTargets, <String>['ISS-101']);
      expect(merged.contains('ISS-101'), isFalse);
      expect(merged.evaluate().decision, IssueDecision.pass);
    });

    test('unknown duplicate target fails the decision', () {
      final broken = IssueRegistry()
        ..add(
          const IssueReport(
            issueId: 'ISS-200',
            duplicates: <String>['GHOST-1'],
            reproduction: <String>['langkah'],
            component: 'c',
            rootCause: 'r',
            affectedVersions: <String>['1.2.0'],
            owner: 'o',
          ),
        );

      final decision = broken.evaluate();
      expect(decision.decision, IssueDecision.fail);
      expect(decision.limitations.join(' '), contains('GHOST-1'));
    });

    test('incomplete report fails the decision with the missing names', () {
      final incomplete = IssueRegistry()
        ..add(
          const IssueReport(
            issueId: 'ISS-300',
            duplicates: <String>[],
            reproduction: <String>['langkah'],
            component: 'workspace/resolver',
            rootCause: '',
            affectedVersions: <String>['1.2.0'],
            owner: '',
          ),
        );

      final decision = incomplete.evaluate();
      expect(decision.decision, IssueDecision.fail);
      expect(decision.limitations.join(' '), contains('root_cause'));
      expect(decision.limitations.join(' '), contains('owner'));
    });

    test('manifest records all seven required fields with live status', () {
      final manifest =
          json.decode(
                File(
                  'docs/planning/v1.2/sprint_113_issue_deduplication_root_cause.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;

      expect(manifest['canonical_step'], '113.29');
      final fields = manifest['required_fields'] as Map<String, dynamic>;
      expect(fields.keys.toSet(), <String>{
        'issue_id',
        'duplicates',
        'reproduction',
        'component',
        'root_cause',
        'affected_versions',
        'owner',
      });
      for (final value in fields.values) {
        final entry = value as Map<String, dynamic>;
        expect(entry['description'], isNotEmpty);
        expect(entry['status'], isNotEmpty);
      }
      expect(manifest['limits'], isNotEmpty);
      expect(manifest['decision'], isNotEmpty);
    });
  });
}
