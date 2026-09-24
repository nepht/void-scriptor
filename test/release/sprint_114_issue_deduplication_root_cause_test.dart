import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/issue_deduplication_root_cause_v114.dart';

void main() {
  group('114.26 Issue Deduplication & Root Cause', () {
    test('complete issue contains the seven canonical fields', () {
      const issue = IssueRecord(
        issueId: 'ISS-001',
        duplicates: <String>[],
        reproduction: <String>[
          'open fixture',
          'repeat export',
          'observe failure',
        ],
        affectedVersions: <String>['1.2.0'],
        rootCause: 'duplicate export command is accepted while busy',
        owner: 'core-worker',
        fixPath: 'guard export submission and add regression coverage',
      );

      expect(IssueRecord.requiredFieldNames, <String>[
        'issue_id',
        'duplicates',
        'reproduction',
        'affected_versions',
        'root_cause',
        'owner',
        'fix_path',
      ]);
      expect(IssueRegister.missingFields(issue), isEmpty);
    });

    test('empty register is blocked without claiming an incident', () {
      final decision = IssueRegister().evaluate();
      expect(decision.status, IssueStatus.blocked);
      expect(decision.issueCount, 0);
      expect(decision.limitations, isNotEmpty);
    });

    test('duplicate reports are folded into one canonical issue', () {
      final register = IssueRegister()
        ..add(
          const IssueRecord(
            issueId: 'ISS-100',
            duplicates: <String>[],
            reproduction: <String>['open project'],
            affectedVersions: <String>['1.2.0'],
            rootCause: 'stale export state',
            owner: 'nephthys',
            fixPath: 'export guard',
          ),
        )
        ..add(
          const IssueRecord(
            issueId: 'ISS-101',
            duplicates: <String>[],
            reproduction: <String>['open project', 'export twice'],
            affectedVersions: <String>['1.2.1'],
            rootCause: 'stale export state',
            owner: 'nephthys',
            fixPath: 'export guard',
          ),
        );

      final canonical = register.mergeDuplicates('ISS-100', <String>[
        'ISS-101',
      ]);
      expect(canonical.issueId, 'ISS-100');
      expect(canonical.duplicates, <String>['ISS-101']);
      expect(canonical.reproduction, <String>['open project', 'export twice']);
      expect(canonical.affectedVersions, <String>['1.2.0', '1.2.1']);
      expect(register.evaluate().status, IssueStatus.pass);
    });

    test('unknown duplicate or incomplete issue fails with field evidence', () {
      final register = IssueRegister()
        ..add(
          const IssueRecord(
            issueId: 'ISS-200',
            duplicates: <String>['GHOST-1'],
            reproduction: <String>['reproduce'],
            affectedVersions: <String>['1.2.0'],
            rootCause: '',
            owner: '',
            fixPath: 'triage',
          ),
        );

      final decision = register.evaluate();
      expect(decision.status, IssueStatus.fail);
      expect(decision.limitations.join(' '), contains('root_cause'));
      expect(decision.limitations.join(' '), contains('owner'));
      expect(decision.limitations.join(' '), contains('GHOST-1'));
    });

    test('manifest records the canonical contract and local limitations', () {
      final manifest =
          json.decode(
                File(
                  'docs/planning/v1.2/sprint_114_issue_deduplication_root_cause.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(manifest['canonical_step'], '114.26');
      expect(
        (manifest['required_fields'] as List<dynamic>).cast<String>(),
        IssueRecord.requiredFieldNames,
      );
      expect(manifest['limits'], isNotEmpty);
      expect(manifest['status'], isNotEmpty);
    });
  });
}
