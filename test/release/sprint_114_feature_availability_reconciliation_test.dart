/// Test for Feature Availability Reconciliation (Step 114.22).
///
/// Validates the seven canonical required fields — feature, flag, entitlement,
/// documented, available, known_issues, evidence — the blocked/fail/pass state
/// of the reconciliation report, the F1-F29 coverage contract (F30 is an alias
/// of F24, never a separate entry), the two cross-field honesty rules, the
/// live reconciliation of the 112.3 inventory and 112.6 rollout matrix at
/// HEAD, and the step manifest.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/feature_availability_reconciliation.dart';

const String _inventoryPath =
    'docs/planning/v1.2/sprint_112_feature_evidence_inventory.json';
const String _matrixPath =
    'docs/planning/v1.2/sprint_112_feature_flag_rollout_matrix.json';
const String _registryPath =
    'lib/core/feature_flags/feature_flag_registry.dart';
const String _wave3Path =
    'lib/features/world_logic/domain/encyclopedia_spoiler_accessibility.dart';
const String _manifestPath =
    'docs/planning/v1.2/sprint_114_feature_availability_reconciliation.json';

/// The 10 PARTIAL features of the live inventory share the kill switch and
/// carry a recorded known issue; the remaining 19 are EVIDENCED_LOCAL with an
/// empty known_issues answer.
const List<String> _partialFeatureIds = <String>[
  'F3',
  'F5',
  'F6',
  'F10',
  'F13',
  'F17',
  'F19',
  'F21',
  'F26',
  'F28',
];

FeatureAvailabilityEntry _entry(
  String id, {
  String flag = 'vs12_example',
  String entitlement = 'internal writers',
  bool? documented = true,
  bool? available = true,
  List<String>? knownIssues,
  List<String>? evidence,
}) {
  return FeatureAvailabilityEntry(
    feature: id,
    flag: flag,
    entitlement: entitlement,
    documented: documented,
    available: available,
    knownIssues: knownIssues ?? <String>[],
    evidence:
        evidence ??
        <String>[
          'lib/features/example/$id.dart',
          'test/features/${id}_test.dart',
        ],
  );
}

List<FeatureAvailabilityEntry> _fullSet() {
  return <FeatureAvailabilityEntry>[
    for (final id in FeatureAvailabilityReconciliation.expectedFeatureIds)
      _entry(
        id,
        knownIssues: _partialFeatureIds.contains(id)
            ? <String>[
                'No dedicated per-feature flag; shared kill switch only.',
              ]
            : <String>[],
      ),
  ];
}

Map<String, dynamic> _readJson(String path) {
  return json.decode(File(path).readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  group('114.22 Feature Availability Reconciliation', () {
    test('seven canonical required fields in ledger order', () {
      expect(FeatureAvailabilityEntry.requiredFieldNames, <String>[
        'feature',
        'flag',
        'entitlement',
        'documented',
        'available',
        'known_issues',
        'evidence',
      ]);
    });

    test('absent entries are blocked without availability claims', () {
      final report = FeatureAvailabilityReconciliation().evaluate(null);

      expect(report.state, FeatureAvailabilityState.blocked);
      expect(report.entries, isEmpty);
      expect(report.featureCount, 0);
      expect(report.missingFields, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.notes.join(' '), contains('DEFERRED-EXTERNAL'));
    });

    test('complete entry has no missing required field', () {
      final reconciliation = FeatureAvailabilityReconciliation();
      expect(reconciliation.missingFields(_entry('F1')), isEmpty);
    });

    test('blank and absent fields are reported by canonical name', () {
      const bare = FeatureAvailabilityEntry(
        feature: '',
        flag: '',
        entitlement: '',
        documented: null,
        available: null,
        knownIssues: null,
        evidence: <String>[],
      );
      expect(FeatureAvailabilityReconciliation().missingFields(bare), <String>[
        'feature',
        'flag',
        'entitlement',
        'documented',
        'available',
        'known_issues',
        'evidence',
      ]);
    });

    test(
      'empty known_issues is a recorded answer, absent field is missing',
      () {
        final reconciliation = FeatureAvailabilityReconciliation();
        final withNone = _entry('F2', knownIssues: <String>[]);
        final withIssue = _entry(
          'F3',
          knownIssues: <String>['No dedicated per-feature flag.'],
        );
        const withoutField = FeatureAvailabilityEntry(
          feature: 'F4',
          flag: 'vs12_x',
          entitlement: 'internal writers',
          documented: true,
          available: true,
          knownIssues: null,
          evidence: <String>['lib/x.dart'],
        );
        expect(reconciliation.missingFields(withNone), isEmpty);
        expect(reconciliation.missingFields(withIssue), isEmpty);
        expect(reconciliation.missingFields(withoutField), <String>[
          'known_issues',
        ]);
      },
    );

    test('coverage incomplete fails naming the missing features', () {
      final report = FeatureAvailabilityReconciliation().evaluate(
        <FeatureAvailabilityEntry>[_entry('F1'), _entry('F2'), _entry('F3')],
      );
      expect(report.state, FeatureAvailabilityState.fail);
      expect(report.violations.join(' '), contains('coverage incomplete'));
      expect(report.violations.join(' '), contains('missing F4'));
    });

    test('duplicate feature entry fails', () {
      final entries = _fullSet();
      entries[1] = _entry('F1');
      final report = FeatureAvailabilityReconciliation().evaluate(entries);
      expect(report.state, FeatureAvailabilityState.fail);
      expect(report.violations.join(' '), contains('duplicate feature: F1'));
    });

    test('F30 alias entry is rejected as an unexpected feature id', () {
      final report = FeatureAvailabilityReconciliation().evaluate(
        <FeatureAvailabilityEntry>[..._fullSet(), _entry('F30')],
      );
      expect(report.state, FeatureAvailabilityState.fail);
      expect(
        report.violations.join(' '),
        contains('unexpected feature id: F30'),
      );
    });

    test('available feature without documentation fails', () {
      final entries = _fullSet();
      entries[6] = _entry('F7', documented: false, available: true);
      final report = FeatureAvailabilityReconciliation().evaluate(entries);
      expect(report.state, FeatureAvailabilityState.fail);
      expect(report.violations, contains('available_undocumented: F7'));
    });

    test('unavailable feature without a recorded known issue fails', () {
      final entries = _fullSet();
      entries[2] = _entry('F3', available: false, knownIssues: <String>[]);
      final report = FeatureAvailabilityReconciliation().evaluate(entries);
      expect(report.state, FeatureAvailabilityState.fail);
      expect(
        report.violations,
        contains('unavailable_without_known_issue: F3'),
      );
    });

    test('unavailable feature with a recorded reason stays consistent', () {
      final entries = _fullSet();
      entries[2] = _entry(
        'F3',
        available: false,
        knownIssues: <String>['Deferred until the flag gate lands.'],
      );
      final report = FeatureAvailabilityReconciliation().evaluate(entries);
      expect(report.state, FeatureAvailabilityState.pass);
      expect(report.violations, isEmpty);
    });

    test('full 29-feature reconciliation passes and retains every answer', () {
      final report = FeatureAvailabilityReconciliation().evaluate(_fullSet());
      expect(report.state, FeatureAvailabilityState.pass);
      expect(report.featureCount, 29);
      expect(report.missingFields, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.notes.join(' '), contains('DEFERRED-EXTERNAL'));
      expect(
        report.entries.where((e) => e.knownIssues!.isEmpty),
        hasLength(19),
      );
      expect(
        report.entries.where((e) => e.knownIssues!.isNotEmpty),
        hasLength(10),
      );
    });

    test(
      'manifest declares canonical fields, rules, and external deferral',
      () {
        final file = File(_manifestPath);
        expect(file.existsSync(), isTrue);
        final document =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

        expect(document['canonical_step'], '114.22');
        expect(document['required_fields'], <dynamic>[
          'feature',
          'flag',
          'entitlement',
          'documented',
          'available',
          'known_issues',
          'evidence',
        ]);
        expect(document['coverage_contract'], contains('29'));
        expect(document['violations'], <dynamic>[
          'available_undocumented',
          'unavailable_without_known_issue',
        ]);
        expect(
          document['runtime_availability_verification'],
          'DEFERRED-EXTERNAL',
        );
        expect(
          document['marketplace_entitlement_verification'],
          'DEFERRED-EXTERNAL',
        );
        expect(document['public_distribution_gates'], 'DEFERRED-EXTERNAL');
        final sources = document['sources'] as Map<String, dynamic>;
        expect(File(sources['inventory'] as String).existsSync(), isTrue);
        expect(File(sources['rollout_matrix'] as String).existsSync(), isTrue);
      },
    );

    test(
      'live reconciliation: 29 features, traceable flags, refs exist at HEAD',
      () {
        final inventory = _readJson(_inventoryPath);
        final matrix = _readJson(_matrixPath);
        final features = inventory['features'] as List<dynamic>;
        expect(features, hasLength(29));

        final matrixByFeature = <String, Map<String, dynamic>>{
          for (final e in matrix['entries'] as List<dynamic>)
            (e as Map<String, dynamic>)['feature'] as String: e,
        };
        final registrySource = File(_registryPath).readAsStringSync();
        final wave3Source = File(_wave3Path).readAsStringSync();

        final flagMismatches = <String>[];
        final entries = <FeatureAvailabilityEntry>[];
        for (final raw in features) {
          final feature = raw as Map<String, dynamic>;
          final id = feature['feature'] as String;
          final flagInfo = feature['feature_flag'] as Map<String, dynamic>;
          final flagId = flagInfo['id'] as String;
          final matrixEntry = matrixByFeature[id]!;
          if (matrixEntry['flag'] != flagId) {
            flagMismatches.add(id);
          }
          final traceable = flagId == 'FeatureFlagRegistry.engageKillSwitch'
              ? registrySource.contains('engageKillSwitch')
              : flagId.startsWith('vs12_')
              ? registrySource.contains('"$flagId"')
              : wave3Source.contains("'$flagId'");
          final docs = (feature['documentation_refs'] as List<dynamic>)
              .cast<String>();
          final impl = (feature['implementation_refs'] as List<dynamic>)
              .cast<String>();
          final tests = (feature['test_refs'] as List<dynamic>).cast<String>();
          entries.add(
            FeatureAvailabilityEntry(
              feature: id,
              flag: flagId,
              entitlement: matrixEntry['audience'] as String,
              documented:
                  docs.isNotEmpty && docs.every((p) => File(p).existsSync()),
              available:
                  traceable &&
                  impl.isNotEmpty &&
                  impl.every((p) => File(p).existsSync()) &&
                  tests.isNotEmpty &&
                  tests.every((p) => File(p).existsSync()),
              knownIssues: (feature['known_issues'] as List<dynamic>)
                  .cast<String>(),
              evidence: <String>[...impl, ...docs, ...tests],
            ),
          );
        }

        expect(
          flagMismatches,
          isEmpty,
          reason: 'inventory flag id must equal rollout matrix flag',
        );
        expect(matrixByFeature, hasLength(29));
        expect(
          entries.every((e) => e.entitlement.trim().isNotEmpty),
          isTrue,
          reason: 'every feature carries a rollout cohort entitlement',
        );
        expect(entries.every((e) => e.documented!), isTrue);
        expect(entries.every((e) => e.available!), isTrue);
        expect(
          entries.fold<int>(0, (n, e) => n + e.evidence!.length),
          87,
          reason: '87 evidence refs (implementation + documentation + tests)',
        );
        for (final entry in entries) {
          expect(
            entry.evidence!.every((p) => File(p).existsSync()),
            isTrue,
            reason: 'evidence path missing at HEAD for ${entry.feature}',
          );
        }
        expect(
          entries.where((e) => e.knownIssues!.isEmpty),
          hasLength(19),
          reason: '19 EVIDENCED_LOCAL features answer with no known issue',
        );
        expect(
          entries.where((e) => e.knownIssues!.isNotEmpty),
          hasLength(10),
          reason: '10 PARTIAL features carry the flag-granularity known issue',
        );

        final report = FeatureAvailabilityReconciliation().evaluate(entries);
        expect(report.state, FeatureAvailabilityState.pass);
        expect(report.featureCount, 29);
        expect(report.missingFields, isEmpty);
        expect(report.violations, isEmpty);
      },
    );
  });
}
