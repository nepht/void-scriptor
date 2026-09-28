import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_quota_usage_cross_provider_contract.dart';

void main() {
  group('116.41 Quota & Usage Cross-Provider Contract Tests', () {
    test('locks the seven quota and usage acceptance areas', () {
      expect(Sprint116QuotaContract.requiredAcceptance, <String>[
        'raw_units',
        'display_units',
        'freshness',
        'unavailable',
        'partial_total',
        'stale_warning',
        'no_mock_values',
      ]);
    });

    test(
      'raw units are preserved exactly and display units add no false precision',
      () {
        const asOf = 1700000001000;
        final report = Sprint116QuotaUsageCertification().certify(
          records: const <Sprint116QuotaRecord>[
            Sprint116QuotaRecord(
              recordId: 'bytes_1536',
              providerId: 'provider_a',
              unitKind: 'bytes',
              observedAtEpochMs: 1700000000000,
              source: 'synthetic_local',
              rawUnits: 1536,
            ),
            Sprint116QuotaRecord(
              recordId: 'bytes_1024',
              providerId: 'provider_a',
              unitKind: 'bytes',
              observedAtEpochMs: 1700000000000,
              source: 'synthetic_local',
              rawUnits: 1024,
            ),
            Sprint116QuotaRecord(
              recordId: 'bytes_512',
              providerId: 'provider_a',
              unitKind: 'bytes',
              observedAtEpochMs: 1700000000000,
              source: 'synthetic_local',
              rawUnits: 512,
            ),
            Sprint116QuotaRecord(
              recordId: 'bytes_gib',
              providerId: 'provider_a',
              unitKind: 'bytes',
              observedAtEpochMs: 1700000000000,
              source: 'synthetic_local',
              rawUnits: 1073741824,
            ),
            Sprint116QuotaRecord(
              recordId: 'percent_whole',
              providerId: 'provider_b',
              unitKind: 'percent',
              observedAtEpochMs: 1700000000000,
              source: 'synthetic_local',
              rawUnits: 50,
            ),
            Sprint116QuotaRecord(
              recordId: 'percent_fraction',
              providerId: 'provider_b',
              unitKind: 'percent',
              observedAtEpochMs: 1700000000000,
              source: 'synthetic_local',
              rawUnits: 87.5,
            ),
            Sprint116QuotaRecord(
              recordId: 'requests_count',
              providerId: 'provider_c',
              unitKind: 'requests',
              observedAtEpochMs: 1700000000000,
              source: 'synthetic_local',
              rawUnits: 1500,
            ),
            Sprint116QuotaRecord(
              recordId: 'neg_1',
              providerId: 'provider_c',
              unitKind: 'bytes',
              observedAtEpochMs: 1700000000000,
              source: 'synthetic_local',
              rawUnits: -5,
            ),
            Sprint116QuotaRecord(
              recordId: 'over_1',
              providerId: 'provider_c',
              unitKind: 'percent',
              observedAtEpochMs: 1700000000000,
              source: 'synthetic_local',
              rawUnits: 150,
            ),
            Sprint116QuotaRecord(
              recordId: 'frac_1',
              providerId: 'provider_c',
              unitKind: 'requests',
              observedAtEpochMs: 1700000000000,
              source: 'synthetic_local',
              rawUnits: 10.5,
            ),
            Sprint116QuotaRecord(
              recordId: 'frac_bytes_1',
              providerId: 'provider_c',
              unitKind: 'bytes',
              observedAtEpochMs: 1700000000000,
              source: 'synthetic_local',
              rawUnits: 1536.5,
            ),
          ],
          asOfEpochMs: asOf,
        );

        final byId = <String, Sprint116QuotaReading>{
          for (final reading in report.readings)
            reading.record.recordId: reading,
        };

        expect(byId['bytes_1536']!.rawUnits, 1536);
        expect(byId['bytes_1536']!.displayValue, '1.5 KiB');
        expect(byId['bytes_1024']!.displayValue, '1 KiB');
        expect(byId['bytes_512']!.displayValue, '512 B');
        expect(byId['bytes_gib']!.displayValue, '1 GiB');
        // A whole percent never grows a decimal it did not report.
        expect(byId['percent_whole']!.displayValue, '50%');
        expect(byId['percent_fraction']!.displayValue, '87.5%');
        expect(byId['requests_count']!.displayValue, '1500');

        expect(report.state, Sprint116QuotaState.fail);
        expect(report.invalidRecords, contains('raw_units:neg_1'));
        expect(report.invalidRecords, contains('display_units:over_1'));
        expect(report.invalidRecords, contains('display_units:frac_1'));
        expect(report.invalidRecords, contains('raw_units:frac_bytes_1'));
        expect(byId['neg_1']!.displayValue, isNull);
        expect(byId['frac_1']!.displayValue, isNull);
      },
    );

    test(
      'freshness is measured against as_of and explicit records never borrow '
      'the manifest timestamp',
      () {
        const observed = 1700000000000;
        const ttlMs = Sprint116QuotaContract.freshTtlSeconds * 1000;
        Sprint116QuotaRecord record(String id, int at) => Sprint116QuotaRecord(
          recordId: id,
          providerId: 'provider_a',
          unitKind: 'requests',
          observedAtEpochMs: at,
          source: 'synthetic_local',
          rawUnits: 10,
        );

        final fresh = Sprint116QuotaUsageCertification().certify(
          records: <Sprint116QuotaRecord>[record('fresh_1', observed)],
          asOfEpochMs: observed + 600000,
        );
        expect(fresh.state, Sprint116QuotaState.pass);
        expect(fresh.readings.single.status, Sprint116QuotaStatus.available);
        expect(fresh.readings.single.ageMs, 600000);
        expect(fresh.readings.single.staleWarning, isFalse);
        expect(fresh.staleWarningIds, isEmpty);

        final stale = Sprint116QuotaUsageCertification().certify(
          records: <Sprint116QuotaRecord>[record('stale_1', observed)],
          asOfEpochMs: observed + ttlMs + 1,
        );
        expect(stale.state, Sprint116QuotaState.fail);
        expect(stale.readings.single.status, Sprint116QuotaStatus.stale);
        expect(stale.readings.single.staleWarning, isTrue);
        expect(stale.staleWarningIds, <String>['stale_1']);
        expect(stale.invalidRecords, contains('stale_warning:stale_1'));

        final brokenClock = Sprint116QuotaUsageCertification().certify(
          records: <Sprint116QuotaRecord>[
            record('future_1', observed),
            record('zero_1', 0),
          ],
          asOfEpochMs: observed - 1,
        );
        expect(brokenClock.state, Sprint116QuotaState.fail);
        expect(brokenClock.invalidRecords, contains('freshness:future_1'));
        expect(brokenClock.invalidRecords, contains('freshness:zero_1'));
        expect(
          brokenClock.invalidRecords.any(
            (entry) => entry.startsWith('stale_warning:'),
          ),
          isFalse,
        );

        // The manifest as_of is 1700001200000. A record observed after it
        // certifies cleanly, proving explicit records never borrow it.
        final noBorrow = Sprint116QuotaUsageCertification().certify(
          records: <Sprint116QuotaRecord>[
            record('after_manifest', 1700002000000),
          ],
        );
        expect(noBorrow.state, Sprint116QuotaState.pass);
        expect(noBorrow.readings.single.ageMs, 0);
      },
    );

    test('unavailable values never become zero and empty sets block', () {
      const observed = 1700000000000;
      final report = Sprint116QuotaUsageCertification().certify(
        records: const <Sprint116QuotaRecord>[
          Sprint116QuotaRecord(
            recordId: 'tokens_missing',
            providerId: 'provider_a',
            unitKind: 'tokens',
            observedAtEpochMs: observed,
            source: 'synthetic_local',
          ),
        ],
        asOfEpochMs: observed,
      );

      expect(report.state, Sprint116QuotaState.pass);
      expect(report.invalidRecords, isEmpty);
      expect(report.readings.single.status, Sprint116QuotaStatus.unavailable);
      expect(report.readings.single.displayValue, isNull);
      expect(report.unavailableIds, <String>['tokens_missing']);
      final total = report.totals['tokens']!;
      expect(total.availableCount, 0);
      expect(total.unavailableCount, 1);
      expect(total.rawTotal, isNull);
      expect(total.displayTotal, isNull);
      expect(total.partial, isTrue);

      final blocked = Sprint116QuotaUsageCertification().certify(
        records: const <Sprint116QuotaRecord>[],
      );
      expect(blocked.state, Sprint116QuotaState.blocked);

      final emptyId = Sprint116QuotaUsageCertification().certify(
        records: const <Sprint116QuotaRecord>[
          Sprint116QuotaRecord(
            recordId: '  ',
            providerId: 'provider_a',
            unitKind: 'requests',
            observedAtEpochMs: observed,
            source: 'synthetic_local',
            rawUnits: 1,
          ),
        ],
        asOfEpochMs: observed,
      );
      expect(emptyId.state, Sprint116QuotaState.fail);
      expect(emptyId.invalidRecords, contains('record_id:0'));
    });

    test(
      'cross-provider totals stay partial until every record reports a value',
      () {
        const asOf = 1700000000000;
        const records = <Sprint116QuotaRecord>[
          Sprint116QuotaRecord(
            recordId: 'bytes_have_a',
            providerId: 'provider_a',
            unitKind: 'bytes',
            observedAtEpochMs: asOf,
            source: 'synthetic_local',
            rawUnits: 1024,
          ),
          Sprint116QuotaRecord(
            recordId: 'bytes_missing_b',
            providerId: 'provider_b',
            unitKind: 'bytes',
            observedAtEpochMs: asOf,
            source: 'synthetic_local',
          ),
          Sprint116QuotaRecord(
            recordId: 'percent_have_c',
            providerId: 'provider_c',
            unitKind: 'percent',
            observedAtEpochMs: asOf,
            source: 'synthetic_local',
            rawUnits: 87.5,
          ),
        ];

        final report = Sprint116QuotaUsageCertification().certify(
          records: records,
          asOfEpochMs: asOf,
        );
        expect(report.state, Sprint116QuotaState.pass);
        expect(
          report.readings.map((reading) => reading.record.providerId).toSet(),
          <String>{'provider_a', 'provider_b', 'provider_c'},
        );
        final bytes = report.totals['bytes']!;
        expect(bytes.rawTotal, 1024);
        expect(bytes.displayTotal, '1 KiB');
        expect(bytes.availableCount, 1);
        expect(bytes.unavailableCount, 1);
        expect(bytes.partial, isTrue);
        final percent = report.totals['percent']!;
        expect(percent.rawTotal, 87.5);
        expect(percent.displayTotal, '87.5%');
        expect(percent.partial, isFalse);

        final strict = Sprint116QuotaUsageCertification().certify(
          records: records,
          asOfEpochMs: asOf,
          requireComplete: true,
        );
        expect(strict.state, Sprint116QuotaState.fail);
        expect(
          strict.invalidRecords,
          contains('partial_total:bytes_missing_b'),
        );
      },
    );

    test('live claims without evidence and unknown sources fail closed', () {
      const asOf = 1700000000000;
      Sprint116QuotaRecord record(
        String id, {
        required String source,
        String? evidenceRef,
      }) => Sprint116QuotaRecord(
        recordId: id,
        providerId: 'provider_live',
        unitKind: 'requests',
        observedAtEpochMs: asOf,
        source: source,
        rawUnits: 42,
        evidenceRef: evidenceRef,
      );

      final verified = Sprint116QuotaUsageCertification().certify(
        records: <Sprint116QuotaRecord>[
          record('live_ok_1', source: 'live', evidenceRef: 'trace://usage/1'),
        ],
        asOfEpochMs: asOf,
      );
      expect(verified.state, Sprint116QuotaState.pass);

      final report = Sprint116QuotaUsageCertification().certify(
        records: <Sprint116QuotaRecord>[
          record('live_ok_1', source: 'live', evidenceRef: 'trace://usage/1'),
          record('live_bare_1', source: 'live'),
          record('mock_1', source: 'mocked', evidenceRef: 'trace://usage/2'),
        ],
        asOfEpochMs: asOf,
      );
      expect(report.state, Sprint116QuotaState.fail);
      expect(report.invalidRecords, contains('no_mock_values:live_bare_1'));
      expect(report.invalidRecords, contains('no_mock_values:mock_1'));
      expect(
        report.invalidRecords,
        isNot(contains('no_mock_values:live_ok_1')),
      );
    });

    test(
      'manifest fixture certifies locally without live provider claims or secrets',
      () {
        final report = Sprint116QuotaUsageCertification().certify();
        expect(report.state, Sprint116QuotaState.pass);
        expect(report.invalidRecords, isEmpty);
        expect(report.externalGates, 'DEFERRED-EXTERNAL');
        expect(report.unavailableIds, <String>['synth_tokens_4']);
        expect(report.totals['bytes']!.rawTotal, 1075314688);
        expect(report.totals['bytes']!.availableCount, 2);
        expect(report.totals['bytes']!.partial, isFalse);
        expect(report.totals['percent']!.rawTotal, 87.5);
        expect(report.totals['requests']!.rawTotal, 1500);
        expect(report.totals['tokens']!.rawTotal, isNull);
        expect(report.totals['tokens']!.partial, isTrue);

        final manifest =
            jsonDecode(
                  File(Sprint116QuotaContract.manifestPath).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(manifest['canonical_step'], '116.41');
        expect(manifest['status'], 'VERIFIED-LOCAL');
        expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
        expect(manifest['live_provider_verification'], false);
        expect(
          manifest['fresh_ttl_seconds'],
          Sprint116QuotaContract.freshTtlSeconds,
        );
        expect(manifest['required_acceptance'], <String>[
          'raw_units',
          'display_units',
          'freshness',
          'unavailable',
          'partial_total',
          'stale_warning',
          'no_mock_values',
        ]);
        final records = manifest['records'] as List<dynamic>;
        expect(records, isNotEmpty);
        for (final record in records) {
          final map = record as Map<String, dynamic>;
          expect(map['source'], 'synthetic_local');
          expect(map['observed_at_epoch_ms'], isA<num>());
          expect(
            Sprint116QuotaContract.supportedUnitKinds.contains(
              map['unit_kind'],
            ),
            isTrue,
          );
        }
        expect(
          manifest.keys
              .where(
                (key) =>
                    key.toLowerCase().contains('secret') ||
                    key.toLowerCase().contains('api_key') ||
                    key.toLowerCase().contains('password') ||
                    key.toLowerCase().contains('webhook_url'),
              )
              .toList(),
          isEmpty,
        );
      },
    );
  });
}
