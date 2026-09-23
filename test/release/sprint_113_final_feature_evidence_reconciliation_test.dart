/// Test for Final Feature Evidence Reconciliation (Step 113.35).
///
/// Validates the eight canonical required fields — feature, status, evidence,
/// flag, documentation, owner, known_issues, release_decision — the
/// blocked/fail/pass state of the reconciliation log, the F1-F29 coverage
/// contract (F30 is an alias of F24, never a separate entry), the live
/// reconciliation of the 112.3 inventory at HEAD, and the step manifest.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/final_feature_evidence_reconciliation.dart';

const String _inventoryPath =
    'docs/planning/v1.2/sprint_112_feature_evidence_inventory.json';
const String _matrixPath =
    'docs/planning/v1.2/sprint_112_feature_flag_rollout_matrix.json';
const String _registryPath =
    'lib/core/feature_flags/feature_flag_registry.dart';
const String _manifestPath =
    'docs/planning/v1.2/sprint_113_final_feature_evidence_reconciliation.json';

FeatureEvidenceEntry _entry(
  String id, {
  String status = 'EVIDENCED_LOCAL',
  List<String>? knownIssues,
  String decision = 'RECOMMEND_INCLUDE',
}) {
  return FeatureEvidenceEntry(
    feature: id,
    status: status,
    evidence: <String>[
      'lib/features/example/$id.dart',
      'test/features/example/${id}_test.dart',
    ],
    flag: 'vs12_example',
    documentation: <String>['docs/sprints/example.md'],
    owner: 'writer-story-lore',
    knownIssues: knownIssues ?? <String>[],
    releaseDecision: decision,
  );
}

List<FeatureEvidenceEntry> _fullSet() {
  return <FeatureEvidenceEntry>[
    for (final id in FeatureReconciliationLog.expectedFeatureIds) _entry(id),
  ];
}

Map<String, dynamic> _readJson(String path) {
  return json.decode(File(path).readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  group('113.35 Final Feature Evidence Reconciliation', () {
    test('eight canonical required fields in ledger order', () {
      expect(FeatureEvidenceEntry.requiredFieldNames, <String>[
        'feature',
        'status',
        'evidence',
        'flag',
        'documentation',
        'owner',
        'known_issues',
        'release_decision',
      ]);
      expect(FeatureEvidenceEntry.releaseDecisionWireNames, <String>[
        'RECOMMEND_INCLUDE',
        'RECOMMEND_DEFER',
        'BLOCKS_RELEASE',
      ]);
    });

    test('complete entry has no missing required field', () {
      final log = FeatureReconciliationLog();
      expect(log.missingFields(_entry('F1')), isEmpty);
    });

    test('blank and absent fields are reported by canonical name', () {
      final log = FeatureReconciliationLog();
      const bare = FeatureEvidenceEntry(
        feature: '',
        status: '',
        evidence: <String>[],
        flag: '',
        documentation: <String>[],
        owner: '',
        knownIssues: null,
        releaseDecision: '',
      );
      expect(log.missingFields(bare), <String>[
        'feature',
        'status',
        'evidence',
        'flag',
        'documentation',
        'owner',
        'known_issues',
        'release_decision',
      ]);
    });

    test(
      'empty known_issues is a recorded answer, absent field is missing',
      () {
        final log = FeatureReconciliationLog();
        final withNone = _entry('F2', knownIssues: <String>[]);
        final withIssue = _entry(
          'F3',
          knownIssues: <String>['flag granularity'],
        );
        const withoutField = FeatureEvidenceEntry(
          feature: 'F4',
          status: 'PARTIAL',
          evidence: <String>['lib/x.dart'],
          flag: 'vs12_x',
          documentation: <String>['docs/x.md'],
          owner: 'world-logic-simulation',
          knownIssues: null,
          releaseDecision: 'RECOMMEND_DEFER',
        );
        expect(log.missingFields(withNone), isNot(contains('known_issues')));
        expect(log.missingFields(withIssue), isNot(contains('known_issues')));
        expect(log.missingFields(withoutField), <String>['known_issues']);
      },
    );

    test('unknown release_decision wire name is rejected', () {
      final log = FeatureReconciliationLog();
      final unknown = _entry('F5', decision: 'SHIP_NOW');
      expect(log.hasUnknownDecision(unknown), isTrue);
      expect(log.hasUnknownDecision(_entry('F6')), isFalse);

      for (final id in FeatureReconciliationLog.expectedFeatureIds) {
        log.add(id == 'F7' ? _entry(id, decision: 'SHIP_NOW') : _entry(id));
      }
      final evaluation = log.evaluate();
      expect(evaluation.state, FeatureReconciliationState.fail);
      expect(evaluation.notes.join(' '), contains('invalid release_decision'));
      expect(evaluation.notes.join(' '), contains('SHIP_NOW'));
    });

    test('empty log is blocked pending a reconciliation attempt', () {
      final evaluation = FeatureReconciliationLog().evaluate();
      expect(evaluation.state, FeatureReconciliationState.blocked);
      expect(evaluation.featureCount, 0);
      expect(evaluation.notes.join(' '), isNotEmpty);
    });

    test('partial coverage fails naming the missing features', () {
      final log = FeatureReconciliationLog()
        ..add(_entry('F1'))
        ..add(_entry('F2'))
        ..add(_entry('F3'));
      final evaluation = log.evaluate();
      expect(evaluation.state, FeatureReconciliationState.fail);
      expect(evaluation.notes.join(' '), contains('coverage incomplete'));
      expect(evaluation.notes.join(' '), contains('missing F4'));
    });

    test('duplicate feature entry fails', () {
      final log = FeatureReconciliationLog();
      for (final id in FeatureReconciliationLog.expectedFeatureIds) {
        log.add(id == 'F2' ? _entry('F1') : _entry(id));
      }
      final evaluation = log.evaluate();
      expect(evaluation.state, FeatureReconciliationState.fail);
      expect(evaluation.notes.join(' '), contains('duplicate feature: F1'));
    });

    test('F30 alias entry is rejected as an unexpected feature id', () {
      final log = FeatureReconciliationLog()..addAll(_fullSet());
      log.add(_entry('F30'));
      final evaluation = log.evaluate();
      expect(evaluation.state, FeatureReconciliationState.fail);
      expect(
        evaluation.notes.join(' '),
        contains('unexpected feature id: F30'),
      );
    });

    test(
      'full 29-feature reconciliation passes and retains every decision',
      () {
        final log = FeatureReconciliationLog();
        for (final id in FeatureReconciliationLog.expectedFeatureIds) {
          log.add(
            id == 'F5'
                ? _entry(
                    id,
                    status: 'PARTIAL',
                    knownIssues: <String>['No dedicated per-feature flag.'],
                    decision: 'RECOMMEND_DEFER',
                  )
                : _entry(id),
          );
        }
        final evaluation = log.evaluate();
        expect(evaluation.state, FeatureReconciliationState.pass);
        expect(evaluation.featureCount, 29);
        expect(evaluation.notes, hasLength(29));
        expect(
          evaluation.notes.join(' '),
          contains('F5 RECOMMEND_DEFER (PARTIAL)'),
        );
        expect(evaluation.notes.join(' '), contains('F1 RECOMMEND_INCLUDE'));
      },
    );

    test('BLOCKS_RELEASE decision fails naming the feature', () {
      final log = FeatureReconciliationLog();
      for (final id in FeatureReconciliationLog.expectedFeatureIds) {
        log.add(
          id == 'F7' ? _entry(id, decision: 'BLOCKS_RELEASE') : _entry(id),
        );
      }
      final evaluation = log.evaluate();
      expect(evaluation.state, FeatureReconciliationState.fail);
      expect(evaluation.notes.join(' '), contains('F7'));
      expect(evaluation.notes.join(' '), contains('BLOCKS_RELEASE'));
    });

    test('live inventory reconciles: 29 features, every ref and flag id '
        'resolves at HEAD', () {
      final inventory = _readJson(_inventoryPath);
      final features = inventory['features'] as List<dynamic>;
      expect(features, hasLength(29));

      final alias = inventory['alias'] as Map<String, dynamic>;
      expect(alias['feature'], 'F30');
      expect(alias['canonical_feature'], 'F24');
      expect(alias['separate_inventory_entry'], isFalse);

      final log = FeatureReconciliationLog();
      final statuses = <String, int>{};
      var refsChecked = 0;
      var withKnownIssues = 0;

      for (final raw in features) {
        final feature = raw as Map<String, dynamic>;
        final impl = (feature['implementation_refs'] as List<dynamic>)
            .cast<String>();
        final testRefs = (feature['test_refs'] as List<dynamic>).cast<String>();
        final docRefs = (feature['documentation_refs'] as List<dynamic>)
            .cast<String>();
        final flag = feature['feature_flag'] as Map<String, dynamic>;
        final flagId = flag['id'] as String;
        final flagRef = flag['ref'] as String;

        for (final path in <String>[
          ...impl,
          ...testRefs,
          ...docRefs,
          flagRef,
        ]) {
          refsChecked += 1;
          expect(
            File(path).existsSync(),
            isTrue,
            reason: '${feature['feature']} ref missing at HEAD: $path',
          );
        }

        final token = flagId.contains('.') ? flagId.split('.').last : flagId;
        expect(
          File(flagRef).readAsStringSync(),
          contains(token),
          reason: '${feature['feature']} flag $flagId not declared in $flagRef',
        );

        final status = feature['status'] as String;
        final knownIssues = (feature['known_issues'] as List<dynamic>)
            .cast<String>();
        if (knownIssues.isNotEmpty) withKnownIssues += 1;
        statuses[status] = (statuses[status] ?? 0) + 1;

        final entry = FeatureEvidenceEntry(
          feature: feature['feature'] as String,
          status: status,
          evidence: <String>[...impl, ...testRefs],
          flag: flagId,
          documentation: docRefs,
          owner: feature['owner'] as String,
          knownIssues: knownIssues,
          releaseDecision: status == 'EVIDENCED_LOCAL'
              ? 'RECOMMEND_INCLUDE'
              : 'RECOMMEND_DEFER',
        );
        expect(
          log.missingFields(entry),
          isEmpty,
          reason: '${feature['feature']} incomplete required fields',
        );
        log.add(entry);
      }

      expect(refsChecked, 116);
      expect(statuses['EVIDENCED_LOCAL'], 19);
      expect(statuses['PARTIAL'], 10);
      expect(withKnownIssues, 10);
      expect(
        log.entries.where((e) => e.releaseDecision == 'RECOMMEND_DEFER').length,
        10,
      );

      final evaluation = log.evaluate();
      expect(evaluation.state, FeatureReconciliationState.pass);
      expect(evaluation.featureCount, 29);
      expect(evaluation.notes, hasLength(29));
    });

    test('rollout-matrix flag ids are registry-backed (REC-01 resolved)', () {
      // Guards against "fixing" REC-01 by inventing dedicated Wave-2/3 flags
      // in the registry: the registry must keep its 13 Wave-1 ids only.
      final registry = File(_registryPath).readAsStringSync();
      expect(registry, isNot(contains('vs12_world_logic_shared')));
      expect(registry, isNot(contains('vs12_herbology_alchemy')));

      // Wave-3 features are gated by EncyclopediaFeatureFlags with F-labels,
      // which is what the 112.3 inventory records.
      final encyclopedia = File(
        'lib/features/world_logic/domain/encyclopedia_spoiler_accessibility.dart',
      ).readAsStringSync();
      expect(encyclopedia, contains("'F23'"));
      expect(encyclopedia, contains("'F29'"));

      final matrix = _readJson(_matrixPath);
      final entries = matrix['entries'] as List<dynamic>;
      expect(entries, hasLength(29));

      final inventory = _readJson(_inventoryPath);
      final flagsByFeature = <String, Map<String, dynamic>>{
        for (final rawFeature in inventory['features'] as List<dynamic>)
          (rawFeature as Map<String, dynamic>)['feature'] as String:
              rawFeature['feature_flag'] as Map<String, dynamic>,
      };
      expect(flagsByFeature, hasLength(29));

      for (final rawEntry in entries) {
        final entry = rawEntry as Map<String, dynamic>;
        final feature = entry['feature'] as String;
        final flag = entry['flag'] as String;
        final inventoryFlag = flagsByFeature[feature]!;

        expect(
          flag,
          inventoryFlag['id'],
          reason: '$feature flag must match the 112.3 inventory identifier',
        );

        final flagRef = File(inventoryFlag['ref'] as String);
        expect(flagRef.existsSync(), isTrue, reason: '$feature flag ref');
        final token = flag.contains('.') ? flag.split('.').last : flag;
        expect(
          flagRef.readAsStringSync(),
          contains(token),
          reason: '$feature flag $flag not declared in ${flagRef.path}',
        );
      }

      final manifest = _readJson(_manifestPath);
      final findings = (manifest['reconciliation_findings'] as List<dynamic>)
          .cast<Map>();
      expect(findings, isNotEmpty);
      final rec01 = findings.first;
      expect(rec01['id'], 'REC-01');
      expect(
        rec01['status'],
        'RESOLVED',
        reason: 'REC-01 reconciliation must be recorded as resolved',
      );
      expect(rec01['resolution'], isNotEmpty);
    });

    test('manifest records the eight required fields with live status', () {
      final manifest = _readJson(_manifestPath);
      expect(manifest['canonical_step'], '113.35');

      final required = manifest['required_fields'] as Map<String, dynamic>;
      expect(required.keys.toSet(), <String>{
        'feature',
        'status',
        'evidence',
        'flag',
        'documentation',
        'owner',
        'known_issues',
        'release_decision',
      });
      for (final value in required.values) {
        final entry = value as Map<String, dynamic>;
        expect(entry['description'], isNotEmpty);
        expect(entry['status'], isNotEmpty);
      }

      final decisions = manifest['release_decisions'] as Map<String, dynamic>;
      expect(decisions.keys.toSet(), <String>{
        'RECOMMEND_INCLUDE',
        'RECOMMEND_DEFER',
        'BLOCKS_RELEASE',
      });

      final rules = manifest['decision_rules'] as Map<String, dynamic>;
      expect(rules['EVIDENCED_LOCAL'], 'RECOMMEND_INCLUDE');
      expect(rules['PARTIAL'], 'RECOMMEND_DEFER');
      expect(rules['authority'], isNotEmpty);

      final counts = manifest['verified_counts'] as Map<String, dynamic>;
      expect(counts['features'], 29);
      expect(counts['refs_checked'], 116);
      expect(counts['refs_missing'], 0);
      expect(counts['flag_refs_resolvable'], 29);
      expect(counts['evidenced_local'], 19);
      expect(counts['partial'], 10);

      final findings = (manifest['reconciliation_findings'] as List<dynamic>)
          .cast<Map>();
      expect(findings, isNotEmpty);
      expect(findings.first['id'], 'REC-01');

      final source = manifest['source'] as Map<String, dynamic>;
      expect(source['inventory'], _inventoryPath);
      expect(source['inventory_sha256'], isNotEmpty);

      expect(manifest['limits'], isNotEmpty);
      expect(manifest['decision'], isNotEmpty);
    });
  });
}
