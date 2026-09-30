/// Canonical step 117.13 — Cloud Storage & Quota Validation.
///
/// Objective (external canonical JSON): test quota accuracy, units, freshness,
/// partial totals, unavailable values, local separation, and refresh.
///
/// The seven evidence names are properties of the numbers a user is shown, so
/// this test is the place that has to say plainly what ships and what does not.
/// The shipped code is a set of local, injectable domain contracts and no
/// provider read at all: `ProviderQuotaAdapter` declares an interface with zero
/// implementations in `lib/`, so every quota below is fixture data that entered
/// through a shipped contract. The check and the drill are therefore
/// deliberately separate classes, and the one acceptance that shipped code
/// cannot satisfy — `provider_api_values` — is recorded as `acceptance_unmet`
/// with the exact reason, never folded into a pass.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_cloud_storage_quota_validation.dart';

void main() {
  const step = Sprint117CloudStorageQuotaContract.canonicalStep;

  group('contract surface', () {
    test('covers the seven canonical checks in canonical order', () {
      expect(Sprint117CloudStorageQuotaContract.requiredChecks, <String>[
        'provider_api_values',
        'raw_bytes',
        'display_units',
        'freshness',
        'partial_total',
        'unavailable',
        'local_separation',
      ]);
    });

    test('declares the canonical step as 117.13', () {
      expect(step, '117.13');
    });

    test('every source manifest it depends on is committed', () {
      for (final path in Sprint117CloudStorageQuotaContract.sourceManifests) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: 'source manifest must be committed: $path',
        );
      }
    });

    test(
      'drills the last_updated and free_space acceptances the sources declare',
      () {
        final anchor = const Sprint117CloudStorageQuotaLoader().load().anchor!;
        expect(anchor.lastUpdatedAcceptanceDeclared, isTrue);
        expect(anchor.freeSpaceAcceptanceDeclared, isTrue);
        expect(
          Sprint117CloudStorageQuotaContract.lastUpdatedAcceptance,
          'last_updated',
        );
        expect(
          Sprint117CloudStorageQuotaContract.freeSpaceAcceptance,
          'free_space',
        );
      },
    );

    test('every source manifest states where its own evidence stops', () {
      final anchor = const Sprint117CloudStorageQuotaLoader().load().anchor;
      expect(anchor, isNotNull);
      for (final entry in anchor!.boundariesDeclared.entries) {
        expect(
          entry.value,
          isTrue,
          reason: 'source must declare a boundary: ${entry.key}',
        );
      }
    });
  });

  group('external pins', () {
    test('resolves and matches every external spec it pins', () {
      final anchor = const Sprint117CloudStorageQuotaLoader().load().anchor;
      expect(anchor, isNotNull);
      expect(
        anchor!.externalPinsResolved,
        isTrue,
        reason:
            'all external pins must be readable to prove anything from them',
      );
      expect(
        anchor.allExternalPinsMatch,
        isTrue,
        reason: 'external source drift invalidates every decision from it',
      );
      expect(anchor.externalPinsChecked, 3);
    });
  });

  group('loader', () {
    test('maps every canonical check to a declared source contract', () {
      final input = const Sprint117CloudStorageQuotaLoader().load();
      expect(input.anchor, isNotNull);
      final ids = input.rows!.map((row) => row.checkId).toList();
      expect(ids, Sprint117CloudStorageQuotaContract.requiredChecks);
      for (final row in input.rows!) {
        expect(row.method, isNotEmpty, reason: row.checkId);
        expect(row.expectedOutcome, isNotEmpty, reason: row.checkId);
        expect(row.sourceManifest, isNotEmpty, reason: row.checkId);
      }
    });

    test('never claims a live provider result for any check', () {
      final input = const Sprint117CloudStorageQuotaLoader().load();
      for (final row in input.rows!) {
        expect(row.liveProviderResult, isFalse, reason: row.checkId);
        expect(row.drilledAgainstLiveProvider, isFalse, reason: row.checkId);
      }
    });

    test('leaves every check undetermined before a drill has run', () {
      final input = const Sprint117CloudStorageQuotaLoader().load();
      for (final row in input.rows!) {
        expect(row.executed, isFalse, reason: row.checkId);
        expect(row.observedOutcome, isNull, reason: row.checkId);
      }
    });
  });

  group('drill — provider_api_values', () {
    test(
      'counts the shipped quota adapters rather than assuming there are some',
      () async {
        final run = await const Sprint117CloudStorageQuotaDrill().run();
        final provider = run.observationFor('provider_api_values')!;
        expect(provider.passed, isTrue, reason: provider.outcome);
        expect(provider.facts['shipped_adapter_implementations'], 0);
        expect(
          provider.facts['test_only_adapter_implementations'],
          greaterThan(0),
        );
        expect(provider.facts['quota_support_acceptance_declared'], isTrue);
        // The contract still holds even with no provider behind it.
        expect(provider.facts['contract_preserved_used_bytes'], 12);
        expect(provider.facts['contract_preserved_available_bytes'], 8);
      },
    );

    test(
      'records provider_api_values as an acceptance no mechanism can satisfy',
      () async {
        final run = await const Sprint117CloudStorageQuotaDrill().run();
        final provider = run.observationFor('provider_api_values')!;
        expect(
          provider.acceptance,
          Sprint117CloudStorageQuotaAcceptance.mechanismAbsent,
        );
        expect(
          provider.unresolvable,
          contains('no_shipped_provider_quota_adapter'),
        );
      },
    );
  });

  group('drill — raw_bytes', () {
    test('preserves provider byte counts through the aggregation', () async {
      final run = await const Sprint117CloudStorageQuotaDrill().run();
      final raw = run.observationFor('raw_bytes')!;
      expect(raw.passed, isTrue, reason: raw.outcome);
      expect(raw.facts['reading_used_bytes'], 2147483648);
      expect(raw.facts['reading_quota_bytes'], 5368709120);
      expect(raw.facts['aggregated_used_bytes'], 2147483648);
      expect(raw.facts['aggregated_status'], 'complete');
    });

    test('refuses an impossible reading instead of repairing it', () async {
      final run = await const Sprint117CloudStorageQuotaDrill().run();
      final raw = run.observationFor('raw_bytes')!;
      expect(raw.facts['negative_reading_error'], 'ArgumentError');
      expect(raw.facts['inconsistent_reading_error'], 'ArgumentError');
      expect(raw.facts['blank_provider_id_error'], 'ArgumentError');
    });
  });

  group('drill — display_units', () {
    test('renders decimal units and keeps an unknown quota unknown', () async {
      final run = await const Sprint117CloudStorageQuotaDrill().run();
      final units = run.observationFor('display_units')!;
      expect(units.passed, isTrue, reason: units.outcome);
      expect(units.facts['known_quota_label'], '10.74 GB');
      expect(units.facts['progress_percent_parsed'], 20);
      expect(units.facts['unknown_quota_bytes'], isNull);
      expect(units.facts['unknown_quota_label'], 'Quota unavailable');
      expect(units.facts['unknown_percentage'], isNull);
    });

    test('refuses a quota smaller than the reported use', () async {
      final run = await const Sprint117CloudStorageQuotaDrill().run();
      final units = run.observationFor('display_units')!;
      expect(units.facts['over_quota_error'], 'ArgumentError');
      expect(units.facts['negative_used_error'], 'ArgumentError');
    });
  });

  group('drill — freshness', () {
    test(
      'states a reading fresh, stale, or unknown on its own merits',
      () async {
        final run = await const Sprint117CloudStorageQuotaDrill().run();
        final freshness = run.observationFor('freshness')!;
        expect(freshness.passed, isTrue, reason: freshness.outcome);
        expect(freshness.facts['fresh_status'], 'fresh');
        expect(freshness.facts['stale_status'], 'stale');
        // Exactly at the window is still fresh; the boundary is inclusive.
        expect(freshness.facts['boundary_status'], 'fresh');
        expect(freshness.facts['stale_card_freshness'], 'stale');
        expect(freshness.facts['future_card_freshness'], 'unknown');
      },
    );

    test(
      'dates an aggregate by its newest included measurement, not its oldest',
      () async {
        final run = await const Sprint117CloudStorageQuotaDrill().run();
        final freshness = run.observationFor('freshness')!;
        expect(
          freshness.facts['mixed_last_updated'],
          freshness.facts['mixed_expected_newest'],
          reason: 'a total is only as current as its newest member',
        );
        expect(
          freshness.facts['mixed_last_updated'],
          isNot(freshness.facts['mixed_oldest_measured_at']),
        );
        expect(freshness.facts['mixed_aggregation_status'], 'stale');
        expect(
          freshness.facts['distribution_last_updated'],
          freshness.facts['mixed_expected_newest'],
          reason:
              'the distribution report must agree on which instant is newest',
        );
      },
    );
  });

  group('drill — partial_total', () {
    test(
      'names every excluded account instead of dropping it silently',
      () async {
        final run = await const Sprint117CloudStorageQuotaDrill().run();
        final partial = run.observationFor('partial_total')!;
        expect(partial.passed, isTrue, reason: partial.outcome);
        expect(partial.facts['partial_status'], 'partial');
        expect(partial.facts['partial_used_bytes'], 500);
        expect(partial.facts['partial_quota_bytes'], 3000);
        expect(partial.facts['partial_available_bytes'], 2500);
        expect(partial.facts['partial_excluded'], <String>['onedrive']);
      },
    );

    test('refuses to total a provider-defined unit with bytes', () async {
      final run = await const Sprint117CloudStorageQuotaDrill().run();
      final partial = run.observationFor('partial_total')!;
      expect(partial.facts['mixed_unit_status'], 'partial');
      expect(partial.facts['mixed_unit_used_bytes'], 100);
      expect(partial.facts['mixed_unit_excluded'], <String>['vendor']);
      expect(partial.facts['empty_status'], 'unavailable');
      expect(partial.facts['empty_used_bytes'], isNull);
    });
  });

  group('drill — unavailable', () {
    test('yields no bytes, no quota, and no percentage', () async {
      final run = await const Sprint117CloudStorageQuotaDrill().run();
      final unavailable = run.observationFor('unavailable')!;
      expect(unavailable.passed, isTrue, reason: unavailable.outcome);
      expect(unavailable.facts['result_reading_is_null'], isTrue);
      expect(unavailable.facts['row_is_measured'], isFalse);
      expect(unavailable.facts['row_published_bytes'], isNull);
      expect(unavailable.facts['row_percent_of_quota'], isNull);
      expect(unavailable.facts['row_display_unit'], '');
    });

    test('refuses an unattributable or falsely attributed reading', () async {
      final run = await const Sprint117CloudStorageQuotaDrill().run();
      final unavailable = run.observationFor('unavailable')!;
      expect(unavailable.facts['missing_account_error'], 'ArgumentError');
      expect(unavailable.facts['false_attribution_error'], 'ArgumentError');
      expect(unavailable.facts['blank_reason_error'], 'ArgumentError');
    });
  });

  group('drill — local_separation', () {
    test('never lets local bytes enter a cloud quota total', () async {
      final run = await const Sprint117CloudStorageQuotaDrill().run();
      final local = run.observationFor('local_separation')!;
      expect(local.passed, isTrue, reason: local.outcome);
      expect(local.facts['local_cloud_bytes_is_null'], isTrue);
      expect(local.facts['local_only_merged_bytes'], isNull);
      expect(local.facts['remote_only_merged_bytes'], isNull);
      expect(local.facts['local_only_total_bytes'], 1000);
      expect(local.facts['remote_only_total_bytes'], 200);
    });

    test('labels a merged total and never folds in free space', () async {
      final run = await const Sprint117CloudStorageQuotaDrill().run();
      final local = run.observationFor('local_separation')!;
      expect(local.facts['merged_bytes'], 1200);
      expect(local.facts['merged_label'], 'Local + remote combined');
      // Free space sits beside the used total, never inside it.
      expect(local.facts['merged_total_bytes'], 1200);
      expect(
        (local.facts['merged_warnings'] as List<dynamic>),
        contains(
          'Local and remote storage are combined in one total; they are not '
          'the same pool of bytes.',
        ),
      );
      expect(
        (local.facts['merged_warnings'] as List<dynamic>),
        contains(
          'Free device space is shown next to the used total and is never '
          'added to it.',
        ),
      );
    });

    test('reports a scope filter that matched nothing', () async {
      final run = await const Sprint117CloudStorageQuotaDrill().run();
      final local = run.observationFor('local_separation')!;
      expect(local.facts['typo_filter_empty_reason'], 'filteredOut');
      expect(local.facts['typo_filter_unknown_values'], <String>['remot']);
    });
  });

  group('gate', () {
    test('passes with every canonical check decided by a real drill', () async {
      final report = await const Sprint117CloudStorageQuotaGate()
          .evaluateWithDrill();
      expect(report.status, Sprint117CloudStorageQuotaState.pass);
      expect(report.verdict, 'CLOUD_STORAGE_QUOTA_VALIDATED_LOCAL');
      expect(report.coverage, 1.0);
      expect(report.missingFields, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.undeterminedChecks, isEmpty);
      expect(report.unmappedChecks, isEmpty);
    });

    test('is blocked, not passed, when no drill has run', () {
      final report = const Sprint117CloudStorageQuotaGate().evaluate();
      expect(report.status, Sprint117CloudStorageQuotaState.blocked);
      expect(report.missingFields, contains('drill_run'));
      expect(report.coverage, 0.0);
      for (final checkId in Sprint117CloudStorageQuotaContract.requiredChecks) {
        expect(report.undeterminedChecks, contains(checkId));
      }
    });

    test('refuses a recorded outcome no drill produced', () async {
      final run = await const Sprint117CloudStorageQuotaDrill().run();
      final input = const Sprint117CloudStorageQuotaLoader().loadWithDrill(run);
      final forged = <Sprint117CloudStorageQuotaCheck>[
        for (final row in input.rows!)
          if (row.checkId == 'raw_bytes')
            Sprint117CloudStorageQuotaCheck(
              checkId: row.checkId,
              method: row.method,
              expectedOutcome: row.expectedOutcome,
              observedOutcome: 'TOTALLY_DIFFERENT_OUTCOME',
              sourceManifest: row.sourceManifest,
              liveProviderResult: false,
              drilledAgainstLiveProvider: false,
            )
          else
            row,
      ];
      final report = const Sprint117CloudStorageQuotaGate().evaluateWith(
        Sprint117CloudStorageQuotaInput(rows: forged, drillRun: run),
      );
      expect(report.status, Sprint117CloudStorageQuotaState.fail);
      expect(
        report.violations,
        contains('check_outcome_contradicts_drill:raw_bytes'),
      );
    });

    test('rejects a claim of a live provider result', () async {
      final run = await const Sprint117CloudStorageQuotaDrill().run();
      final input = const Sprint117CloudStorageQuotaLoader().loadWithDrill(run);
      final forged = <Sprint117CloudStorageQuotaCheck>[
        for (final row in input.rows!)
          if (row.checkId == 'display_units')
            Sprint117CloudStorageQuotaCheck(
              checkId: row.checkId,
              method: row.method,
              expectedOutcome: row.expectedOutcome,
              observedOutcome: row.observedOutcome,
              sourceManifest: row.sourceManifest,
              liveProviderResult: true,
              drilledAgainstLiveProvider: false,
            )
          else
            row,
      ];
      final report = const Sprint117CloudStorageQuotaGate().evaluateWith(
        Sprint117CloudStorageQuotaInput(rows: forged, drillRun: run),
      );
      expect(report.status, Sprint117CloudStorageQuotaState.fail);
      expect(report.violations, contains('live_provider_claim:display_units'));
    });

    test('rejects an acceptance claimed without a mechanism', () async {
      final run = await const Sprint117CloudStorageQuotaDrill().run();
      final lying = Sprint117CloudStorageQuotaDrillRun(
        observations: <Sprint117CloudStorageQuotaObservation>[
          for (final entry in run.observations)
            if (entry.checkId == 'provider_api_values')
              Sprint117CloudStorageQuotaObservation(
                checkId: entry.checkId,
                outcome: entry.outcome,
                facts: const <String, Object?>{
                  'acceptance_mechanism_present': false,
                },
                passed: true,
                acceptance: Sprint117CloudStorageQuotaAcceptance.satisfied,
                unresolvable: const <String>[],
              )
            else
              entry,
        ],
        liveProviderTouched: false,
        userProjectTouched: false,
        liveSecretObserved: false,
        externalPinsMatched: run.externalPinsMatched,
        externalPinsChecked: run.externalPinsChecked,
      );
      final report = const Sprint117CloudStorageQuotaGate().evaluateWith(
        Sprint117CloudStorageQuotaInput(
          rows: const <Sprint117CloudStorageQuotaCheck>[],
          anchor: const Sprint117CloudStorageQuotaLoader().load().anchor,
          drillRun: lying,
        ),
      );
      expect(report.status, Sprint117CloudStorageQuotaState.fail);
      expect(
        report.violations,
        contains('acceptance_claimed_without_mechanism:provider_api_values'),
      );
    });

    test('rejects a drill run that touched a live provider', () {
      final leaky = Sprint117CloudStorageQuotaDrillRun(
        observations: <Sprint117CloudStorageQuotaObservation>[
          Sprint117CloudStorageQuotaObservation(
            checkId: 'provider_api_values',
            outcome: 'X',
            facts: const <String, Object?>{
              'acceptance_mechanism_present': true,
            },
            passed: true,
          ),
        ],
        liveProviderTouched: true,
        userProjectTouched: false,
        liveSecretObserved: false,
        externalPinsMatched: 0,
        externalPinsChecked: 0,
      );
      final report = const Sprint117CloudStorageQuotaGate().evaluateWith(
        Sprint117CloudStorageQuotaInput(
          rows: const <Sprint117CloudStorageQuotaCheck>[],
          anchor: const Sprint117CloudStorageQuotaLoader().load().anchor,
          drillRun: leaky,
        ),
      );
      expect(report.status, Sprint117CloudStorageQuotaState.fail);
      expect(report.violations, contains('live_provider_touched'));
    });

    test('rejects a drill run that opened a user project', () {
      final leaky = Sprint117CloudStorageQuotaDrillRun(
        observations: <Sprint117CloudStorageQuotaObservation>[
          Sprint117CloudStorageQuotaObservation(
            checkId: 'local_separation',
            outcome: 'X',
            facts: const <String, Object?>{
              'acceptance_mechanism_present': true,
            },
            passed: true,
          ),
        ],
        liveProviderTouched: false,
        userProjectTouched: true,
        liveSecretObserved: false,
        externalPinsMatched: 0,
        externalPinsChecked: 0,
      );
      final report = const Sprint117CloudStorageQuotaGate().evaluateWith(
        Sprint117CloudStorageQuotaInput(
          rows: const <Sprint117CloudStorageQuotaCheck>[],
          anchor: const Sprint117CloudStorageQuotaLoader().load().anchor,
          drillRun: leaky,
        ),
      );
      expect(report.status, Sprint117CloudStorageQuotaState.fail);
      expect(report.violations, contains('user_project_touched'));
    });

    test(
      'rejects a failed observation as a violation, not an open item',
      () async {
        final failing = Sprint117CloudStorageQuotaDrillRun(
          observations: <Sprint117CloudStorageQuotaObservation>[
            Sprint117CloudStorageQuotaObservation(
              checkId: 'freshness',
              outcome: 'AGGREGATE_DATED_BY_OLDEST_READING',
              facts: const <String, Object?>{
                'acceptance_mechanism_present': true,
              },
              passed: false,
            ),
          ],
          liveProviderTouched: false,
          userProjectTouched: false,
          liveSecretObserved: false,
          externalPinsMatched: 0,
          externalPinsChecked: 0,
        );
        final report = const Sprint117CloudStorageQuotaGate().evaluateWith(
          Sprint117CloudStorageQuotaInput(
            rows: const <Sprint117CloudStorageQuotaCheck>[],
            anchor: const Sprint117CloudStorageQuotaLoader().load().anchor,
            drillRun: failing,
          ),
        );
        expect(report.status, Sprint117CloudStorageQuotaState.fail);
        expect(
          report.violations,
          contains('drill_observation_failed:freshness'),
        );
        expect(
          report.violations,
          contains('drill_outcome:AGGREGATE_DATED_BY_OLDEST_READING'),
        );
      },
    );

    test('rejects a run that left a canonical check undecided', () async {
      final run = await const Sprint117CloudStorageQuotaDrill().run();
      final input = const Sprint117CloudStorageQuotaLoader().loadWithDrill(run);
      final dropped = <Sprint117CloudStorageQuotaCheck>[
        for (final row in input.rows!)
          if (row.checkId != 'local_separation') row,
      ];
      final report = const Sprint117CloudStorageQuotaGate().evaluateWith(
        Sprint117CloudStorageQuotaInput(
          rows: dropped,
          // The anchor decides which canonical checks must be mapped, so a
          // missing one would report `blocked` for an unrelated reason and the
          // unmapped check would never be reached.
          anchor: const Sprint117CloudStorageQuotaLoader().load().anchor,
          drillRun: run,
        ),
      );
      expect(report.status, Sprint117CloudStorageQuotaState.fail);
      expect(report.violations, contains('check_unmapped:local_separation'));
    });

    test(
      'carries the unmet acceptance and the integration gap as open items',
      () async {
        final report = await const Sprint117CloudStorageQuotaGate()
            .evaluateWithDrill();
        expect(
          report.openItems,
          contains('check_acceptance_unmet:provider_api_values'),
        );
        expect(
          report.openItems,
          contains('unresolvable_reference:no_shipped_provider_quota_adapter'),
        );
        expect(report.openItems, contains('quota_defined_not_executed_live'));
        expect(
          report.openItems,
          contains('external_storage_specs_outside_repository'),
        );
      },
    );
  });

  group('report serialisation', () {
    test(
      'emits the verdict and every evidence class it decided from',
      () async {
        final report = await const Sprint117CloudStorageQuotaGate()
            .evaluateWithDrill();
        final json = report.toJson();
        expect(json['verdict'], 'CLOUD_STORAGE_QUOTA_VALIDATED_LOCAL');
        expect(json['status'], 'pass');
        expect(json['coverage'], 1.0);
        expect((json['acceptance_unmet'] as List<dynamic>).toList(), <String>[
          'provider_api_values',
        ]);
        expect(json['anchor'], isA<Map<String, dynamic>>());
        expect((json['checks'] as List<dynamic>).length, 7);
        // The emitted manifest must itself be valid JSON, byte-for-byte
        // round-trippable, so a generator can write it without a second pass.
        expect(() => jsonDecode(jsonEncode(json)), returnsNormally);
      },
    );
  });
}
