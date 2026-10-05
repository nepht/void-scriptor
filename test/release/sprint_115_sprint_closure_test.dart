/// Sprint 115.56 — Sprint Closure contract tests.
///
/// Locks the eight canonical definition-of-done criteria of step 115.56
/// against sprint_115.json, proves the fail-closed closure contract, and
/// grounds every committed manifest row in the live repository.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_115_closure.dart';
import '../canonical_source_support.dart';

void main() {
  const canonicalSprintPath =
      'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/'
      'sprint_115.json';
  const canonicalSprintSha256 =
      'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba';

  final manifestFile = File(
    'docs/planning/v1.2/sprint_115_sprint_closure.json',
  );

  Map<String, dynamic> readManifest() {
    expect(manifestFile.existsSync(), isTrue, reason: '115.56 manifest');
    return jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  }

  List<Sprint115ClosureCriterion> completeCriteria() =>
      <Sprint115ClosureCriterion>[
        for (final name in Sprint115Closure.criteriaNames)
          Sprint115ClosureCriterion(
            name: name,
            passed: true,
            evidence: 'docs/planning/v1.2/sprint_115_sprint_closure.json',
          ),
      ];

  group('115.56 canonical definition of done', () {
    test('declares the canonical eight criteria', () {
      expect(Sprint115Closure.canonicalStep, '115.56');
      expect(Sprint115Closure.criteriaNames, <String>[
        'entry_gate_passed',
        'global_scope_enforced',
        'reference_layout_implemented',
        'provider_icons_registry_complete',
        'mock_values_blocked_from_production',
        'security_privacy_verified',
        'responsive_accessible',
        'alpha_decision_recorded',
      ]);
      expect(
        Sprint115Closure.manifestPath,
        endsWith('sprint_115_sprint_closure.json'),
      );
    });

    test('matches definition_of_done of step 115.56 in sprint_115.json', () {
      if (skipUnlessExternalCanonical(
        "matches definition_of_done of step 115.56 in sprint_115.json",
      )) {
        return;
      }
      final file = File(canonicalSprintPath);
      expect(file.existsSync(), isTrue, reason: 'canonical sprint_115.json');
      expect(
        sha256.convert(file.readAsBytesSync()).toString(),
        canonicalSprintSha256,
        reason: 'canonical sprint hash drift',
      );
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final step = (document['steps'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((entry) => entry['id'] == '115.56');
      expect(step['title'], 'Sprint Closure');
      expect(
        step['definition_of_done'],
        Sprint115Closure.criteriaNames,
        reason: 'definition_of_done must be transcribed, not invented',
      );
    });
  });

  group('fail-closed closure contract', () {
    test('closes the local sprint when every criterion passes', () {
      final report = Sprint115Closure.evaluate(
        criteria: completeCriteria(),
        alphaDecision: Sprint115Closure.alphaDecisionLocalScope,
      );

      expect(report.passedCount, 8);
      expect(report.unmetCriteria, isEmpty);
      expect(report.isClosed, isTrue);
      expect(
        report.decision,
        Sprint115ClosureDecision.closedLocalDeferredExternal,
      );
    });

    test('rejects a criteria list that is not exactly the canonical eight', () {
      expect(
        () => Sprint115Closure.evaluate(
          criteria: <Sprint115ClosureCriterion>[completeCriteria().first],
          alphaDecision: Sprint115Closure.alphaDecisionLocalScope,
        ),
        throwsArgumentError,
      );
      expect(
        () => Sprint115Closure.evaluate(
          criteria: <Sprint115ClosureCriterion>[
            ...completeCriteria(),
            const Sprint115ClosureCriterion(
              name: 'unexpected_criterion',
              passed: true,
              evidence: 'fixture',
            ),
          ],
          alphaDecision: Sprint115Closure.alphaDecisionLocalScope,
        ),
        throwsArgumentError,
      );
    });

    test('rejects an alpha decision other than the local-scope constant', () {
      expect(
        () => Sprint115Closure.evaluate(
          criteria: completeCriteria(),
          alphaDecision: 'ALPHA_ACCEPTED',
        ),
        throwsArgumentError,
      );
      expect(
        () => Sprint115Closure.evaluate(
          criteria: completeCriteria(),
          alphaDecision: 'ALPHA_REJECTED',
        ),
        throwsArgumentError,
      );
    });

    test('blocks closure when any criterion is unmet', () {
      final criteria = completeCriteria();
      final unmet = Sprint115ClosureCriterion(
        name: criteria[3].name,
        passed: false,
        evidence: criteria[3].evidence,
      );
      final report = Sprint115Closure.evaluate(
        criteria: <Sprint115ClosureCriterion>[
          ...criteria.take(3),
          unmet,
          ...criteria.skip(4),
        ],
        alphaDecision: Sprint115Closure.alphaDecisionLocalScope,
      );

      expect(report.passedCount, 7);
      expect(report.unmetCriteria, <String>[criteria[3].name]);
      expect(report.isClosed, isFalse);
      expect(report.decision, Sprint115ClosureDecision.blocked);
    });
  });

  group('committed manifest', () {
    test('records local deferred closure and external boundary', () {
      final manifest = readManifest();

      expect(manifest['canonical_step'], '115.56');
      expect(manifest['status'], 'VERIFIED-LOCAL');
      expect(manifest['release_path'], 'DELAYED');
      expect(manifest['closure_decision'], 'CLOSED_LOCAL_DEFERRED_EXTERNAL');
      expect(
        manifest['alpha_decision'],
        'ALPHA_ACCEPTED_LOCAL_DEFERRED_EXTERNAL',
      );
      expect(manifest['definition_of_done'], hasLength(8));
      expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
      expect(manifest['limitations'], isNotEmpty);
    });

    test('every criterion row cites evidence that exists on disk', () {
      final manifest = readManifest();
      final criteria = manifest['criteria'] as Map<String, dynamic>;

      expect(
        criteria.keys.toSet(),
        Sprint115Closure.criteriaNames.toSet(),
        reason: 'manifest criteria must match the canonical eight',
      );

      for (final entry in criteria.entries) {
        final row = entry.value as Map<String, dynamic>;
        expect(row['status'], 'VERIFIED-LOCAL', reason: entry.key);
        final evidence = (row['evidence'] as List<dynamic>).cast<String>();
        expect(evidence, isNotEmpty, reason: entry.key);
        for (final path in evidence) {
          expect(path, isNot(contains('..')), reason: path);
          expect(File(path).existsSync(), isTrue, reason: '$path missing');
        }
        expect(
          (row['summary'] as String).trim().length,
          greaterThanOrEqualTo(30),
          reason: entry.key,
        );
      }
    });

    test('deferred external gates stay parked', () {
      final manifest = readManifest();
      final deferred = (manifest['deferred_checks'] as List<dynamic>)
          .cast<String>();
      expect(deferred.length, greaterThanOrEqualTo(4));
      expect(
        deferred.any((entry) => entry.toLowerCase().contains('connector')),
        isTrue,
      );
      expect(
        deferred.any((entry) => entry.toLowerCase().contains('publication')),
        isTrue,
      );
      for (final entry in deferred) {
        expect(entry, isNot(contains('PASS')));
      }
    });
  });
}
