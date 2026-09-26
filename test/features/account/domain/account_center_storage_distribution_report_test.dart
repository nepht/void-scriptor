import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_storage_distribution_report.dart';

const String _productSpecPath =
    'C:/Users/nepht/Documents/Codex/2026-08-22/'
    'referenced-chatgpt-conversation-this-is-an-2/outputs/'
    'account_cloud_center_spec.json';

final DateTime _now = DateTime.utc(2026, 9, 26, 12);

StorageDistributionRecord _local({
  StorageCategoryKind kind = StorageCategoryKind.projects,
  int bytes = 1000,
  DateTime? measuredAt,
  StorageRecordSource source = StorageRecordSource.localScan,
  String? label,
}) => StorageDistributionRecord(
  scope: StorageDistributionScope.local,
  category: label == null
      ? StorageCategoryRef.canonical(kind)
      : StorageCategoryRef.unrecognized(label),
  bytes: bytes,
  measuredAt: measuredAt ?? DateTime.utc(2026, 9, 26, 6),
  source: source,
);

StorageDistributionRecord _remote({
  StorageCategoryKind kind = StorageCategoryKind.assets,
  int bytes = 2000,
  DateTime? measuredAt,
  String accountId = 'acc_dropbox',
  String providerId = 'dropbox',
  int? quotaBytes = 10000,
  String? providerReportedUnit,
  StorageRecordSource source = StorageRecordSource.providerApi,
  String? label,
}) => StorageDistributionRecord(
  scope: StorageDistributionScope.remote,
  category: label == null
      ? StorageCategoryRef.canonical(kind)
      : StorageCategoryRef.unrecognized(label),
  bytes: bytes,
  measuredAt: measuredAt ?? DateTime.utc(2026, 9, 26, 6),
  source: source,
  accountId: accountId,
  providerId: providerId,
  quotaBytes: quotaBytes,
  providerReportedUnit: providerReportedUnit,
);

AccountCenterStorageDistributionReport _report(
  Iterable<StorageDistributionRecord> records, {
  StorageScopeFilter? filter,
  DateTime? now,
  StorageDistributionFreshnessPolicy? freshness,
  int? localFreeBytes,
}) => AccountCenterStorageDistributionReport.build(
  records: records,
  filter: filter,
  now: now ?? _now,
  freshness: freshness,
  localFreeBytes: localFreeBytes,
);

void main() {
  group('AccountCenterStorageDistributionReport', () {
    group('contract', () {
      test('manifest preserves every canonical 115.41 acceptance item', () {
        final manifest =
            jsonDecode(
                  File(
                    'docs/planning/v1.2/'
                    'sprint_115_storage_distribution_chart_table.json',
                  ).readAsStringSync(),
                )
                as Map<String, Object?>;

        expect(manifest['canonical_step'], '115.41');
        expect(manifest['acceptance'], <String>[
          'category_chart',
          'data_table',
          'remote_local_filter',
          'unknown_category',
          'freshness',
          'drill_down',
        ]);
        expect(
          manifest['implementation'],
          'lib/features/account/domain/'
          'account_center_storage_distribution_report.dart',
        );
        expect(
          manifest['evidence'],
          'test/features/account/domain/'
          'account_center_storage_distribution_report_test.dart',
        );
      });

      test('acceptance list is pinned to canonical sprint 115.41', () {
        final file = File(
          AccountCenterStorageDistributionReport.canonicalSprintPath,
        );
        expect(file.existsSync(), isTrue);
        final json =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final step = (json['steps'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .firstWhere((entry) => entry['id'] == '115.41');

        expect(step['title'], 'Storage Distribution Chart & Table');
        expect(
          step['acceptance'],
          AccountCenterStorageDistributionReport.canonicalAcceptance,
        );
        expect(
          AccountCenterStorageDistributionReport.canonicalSprintSha256,
          'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba',
        );
      });

      test('product spec keeps local/remote separation and mock ban', () {
        final spec =
            jsonDecode(File(_productSpecPath).readAsStringSync())
                as Map<String, Object?>;
        final contract = spec['storage_usage_contract'] as Map<String, Object?>;
        final rules = (contract['display_rules'] as List<dynamic>)
            .cast<String>();

        expect(
          rules,
          contains('Separate remote cloud total from local storage total.'),
        );
        expect(
          rules,
          contains(
            'Do not sum accounts with stale or unavailable data into a '
            'precise total without warning.',
          ),
        );
        expect(
          rules,
          contains(
            'Do not invent quota when provider API omits it; show Used value '
            'and Quota unavailable.',
          ),
        );

        final mockValues =
            contract['reference_mock_values'] as Map<String, Object?>;
        expect(mockValues['production_use_allowed'], isFalse);
        expect(
          AccountCenterStorageDistributionReport.referenceMockValuesAllowed,
          isFalse,
        );
        expect(
          (spec['acceptance_invariants'] as List<dynamic>).cast<String>(),
          // The spec ships this invariant with a space in "without labeling";
          // pinned verbatim so a future spec fix shows up as a test failure
          // rather than silently loosening the assertion.
          contains('local_and_remote_storage_are_not_merged_without labeling'),
        );
        expect(
          (spec['acceptance_invariants'] as List<dynamic>).cast<String>(),
          contains('reference_mock_values_never_reach_production_state'),
        );
      });
    });

    group('category_chart', () {
      test('groups bytes per category and every slice reads as text', () {
        final report = _report([
          _local(kind: StorageCategoryKind.projects, bytes: 400),
          _local(kind: StorageCategoryKind.projects, bytes: 600),
          _local(kind: StorageCategoryKind.assets, bytes: 1000),
        ]);

        expect(report.chart.slices.length, 2);
        for (final slice in report.chart.slices) {
          expect(slice.textAlternative.trim(), isNotEmpty);
        }
        // Largest first: assets (1000) leads, projects (1000) is the tie-break
        // loser, so assert on the sum and the set rather than a position.
        final byKind = <StorageCategoryKind, StorageDistributionSlice>{
          for (final slice in report.chart.slices) slice.category.kind: slice,
        };
        expect(byKind[StorageCategoryKind.projects]!.bytes, 1000);
        expect(byKind[StorageCategoryKind.assets]!.bytes, 1000);
        expect(report.chart.totalBytes, 2000);
        expect(report.chart.textAlternative, contains('Projects'));
        // 1000 bytes formats as `1 KB`; the formatter trims the trailing zero
        // rather than printing the invented precision `1.00 KB`.
        expect(report.chart.textAlternative, contains('1 KB'));
        expect(report.chart.textAlternative, contains('2 KB total'));
      });

      test('slices are deterministic and unrecognized sorts last', () {
        final report = _report([
          _local(label: 'fonts', bytes: 10),
          _local(kind: StorageCategoryKind.temp, bytes: 20),
          _local(kind: StorageCategoryKind.assets, bytes: 30),
        ]);

        // Largest first so the chart leads with the biggest consumer; the
        // unrecognised bucket is last even though it is not the smallest.
        final order = report.chart.slices
            .map((slice) => slice.category.kind)
            .toList(growable: false);
        expect(order, <StorageCategoryKind>[
          StorageCategoryKind.assets,
          StorageCategoryKind.temp,
          StorageCategoryKind.unrecognized,
        ]);
      });

      test('a zero total is unrenderable and never divided by zero', () {
        final report = _report([
          _local(kind: StorageCategoryKind.cache, bytes: 0),
        ]);

        expect(report.chart.totalBytes, 0);
        expect(report.chart.isRenderable, isFalse);
        expect(report.chart.slices.first.shareOfTotal, isNull);
        expect(report.chart.slices.first.textAlternative, contains('0 B'));
        expect(report.chart.textAlternative, contains('nothing to plot'));
      });

      test('shares are proportional and add up to the whole', () {
        final report = _report([
          _local(kind: StorageCategoryKind.projects, bytes: 250),
          _local(kind: StorageCategoryKind.assets, bytes: 750),
        ]);

        final byKind = <StorageCategoryKind, StorageDistributionSlice>{
          for (final slice in report.chart.slices) slice.category.kind: slice,
        };
        expect(
          byKind[StorageCategoryKind.projects]!.shareOfTotal,
          closeTo(0.25, 1e-9),
        );
        expect(
          byKind[StorageCategoryKind.assets]!.shareOfTotal,
          closeTo(0.75, 1e-9),
        );
        final shares = report.chart.slices
            .map((slice) => slice.shareOfTotal!)
            .toList(growable: false);
        expect(shares.fold<double>(0, (a, b) => a + b), closeTo(1.0, 1e-9));
        expect(byKind[StorageCategoryKind.projects]!.percentOfTotal, 25);
      });

      test('the same category on local and remote stays two slices', () {
        final report = _report([
          _local(kind: StorageCategoryKind.assets, bytes: 1000),
          _remote(kind: StorageCategoryKind.assets, bytes: 3000),
        ]);

        expect(report.chart.slices.length, 2);
        expect(
          report.chart.slices.map((slice) => slice.scope).toSet(),
          <StorageDistributionScope>{
            StorageDistributionScope.local,
            StorageDistributionScope.remote,
          },
        );
        expect(report.mergedBytes, 4000);
        expect(report.mergedLabel, 'Local + remote combined');
        expect(
          report.warnings,
          contains(
            'Local and remote storage are combined in one total; they are '
            'not the same pool of bytes.',
          ),
        );
      });
    });

    group('data_table', () {
      test('one row per record with a closed public field set', () {
        final report = _report([_local(), _remote()]);

        expect(report.rows.length, 2);
        for (final row in report.rows) {
          expect(
            row.toPublicJson().keys.toSet(),
            StorageDistributionRow.publicFields,
          );
        }
        expect(
          StorageDistributionRow.publicFields,
          isNot(contains(contains('prompt'))),
        );
        expect(StorageDistributionRow.publicFields, isNot(contains('content')));
        expect(StorageDistributionRow.publicFields, isNot(contains('note')));
      });

      test('rows are ordered by scope then category then account', () {
        final report = _report([
          _remote(accountId: 'acc_onedrive', kind: StorageCategoryKind.assets),
          _remote(accountId: 'acc_dropbox', kind: StorageCategoryKind.assets),
          _local(kind: StorageCategoryKind.backups),
        ]);

        final keys = report.rows
            .map(
              (row) =>
                  '${row.scope.wireName}/${row.category.key}'
                  '${row.accountId == null ? '' : '/${row.accountId}'}',
            )
            .toList(growable: false);
        expect(keys, <String>[
          'local/backups',
          'remote/assets/acc_dropbox',
          'remote/assets/acc_onedrive',
        ]);
      });

      test('size labels use decimal GB/TB, not binary units', () {
        final report = _report([
          _local(kind: StorageCategoryKind.models, bytes: 1500000000),
          _local(kind: StorageCategoryKind.archive, bytes: 2500000000000),
        ]);

        final byKey = <String, StorageDistributionRow>{
          for (final row in report.rows) row.category.key: row,
        };
        expect(byKey['models']!.sizeLabel, '1.5 GB');
        expect(byKey['models']!.displayUnit, 'GB');
        expect(byKey['archive']!.sizeLabel, '2.5 TB');
        expect(byKey['archive']!.displayUnit, 'TB');
      });

      test('the provider unit note appears only when it differs', () {
        final report = _report([
          // 2e9 bytes displays as 2 GB; GiB differs, so the note is warranted.
          _remote(providerReportedUnit: 'GiB', bytes: 2000000000),
          // 1e9 bytes also displays as 1 GB, matching the reported GB.
          _remote(
            accountId: 'acc_google',
            providerId: 'google_drive',
            providerReportedUnit: 'GB',
            kind: StorageCategoryKind.models,
            bytes: 1000000000,
          ),
        ]);

        final byUnit = <String, StorageDistributionRow>{
          for (final row in report.rows)
            '${row.category.key}/${row.accountId}': row,
        };
        expect(
          byUnit['assets/acc_dropbox']!.providerUnitNote,
          'Provider reports GiB; displayed in decimal GB.',
        );
        expect(byUnit['models/acc_google']!.providerUnitNote, isNull);
      });

      test('an omitted quota reads unavailable and is never invented', () {
        final report = _report([_remote(quotaBytes: null)]);
        final row = report.rows.single;

        expect(row.quotaBytes, isNull);
        expect(row.quotaLabel, 'Quota unavailable');
        expect(row.usedLabel, '2 KB used; Quota unavailable');
        expect(row.percentOfQuota, isNull);
        expect(row.toPublicJson()['quota_bytes'], isNull);
      });

      test(
        'a user-declared remote record is marked, not passed off as API',
        () {
          final report = _report([
            _remote(source: StorageRecordSource.userDeclared),
          ]);

          expect(report.rows.single.source, StorageRecordSource.userDeclared);
          expect(report.rows.single.sourceLabel, 'User declared');
          expect(report.totalIsExact, isFalse);
          expect(report.warnings.join(' '), contains('user-declared'));
        },
      );
    });

    group('remote_local_filter', () {
      test('local only, remote only, and both are distinct', () {
        final records = [
          _local(kind: StorageCategoryKind.projects, bytes: 1000),
          _remote(kind: StorageCategoryKind.assets, bytes: 2000),
        ];

        final localOnly = _report(
          records,
          filter: StorageScopeFilter.localOnly(),
        );
        final remoteOnly = _report(
          records,
          filter: StorageScopeFilter.remoteOnly(),
        );
        final both = _report(records, filter: StorageScopeFilter.all());

        expect(localOnly.rows.length, 1);
        expect(localOnly.rows.single.scope, StorageDistributionScope.local);
        expect(remoteOnly.rows.length, 1);
        expect(remoteOnly.rows.single.scope, StorageDistributionScope.remote);
        expect(both.rows.length, 2);
        expect(both.mergedBytes, 3000);
      });

      test('a hidden record is counted, not silently dropped', () {
        final report = _report([
          _local(kind: StorageCategoryKind.projects, bytes: 1000),
          _remote(kind: StorageCategoryKind.assets, bytes: 2000),
        ], filter: StorageScopeFilter.localOnly());

        expect(report.hiddenRecordCount, 1);
        expect(report.totalRecordCount, 2);
        expect(report.filtersAreNarrowing, isTrue);
        expect(report.textSummary, contains('Filter hid 1 of 2 record(s)'));
      });

      test('an unknown scope value fails closed and is named', () {
        final report = _report([
          _local(kind: StorageCategoryKind.projects, bytes: 1000),
        ], filter: StorageScopeFilter(scopeNames: {'hybrid'}));

        expect(report.rows, isEmpty);
        expect(report.unknownFilterValues, <String>['hybrid']);
        expect(report.emptyReason, StorageDistributionEmptyReason.filteredOut);
        expect(report.textSummary, contains('Unknown filter value(s): hybrid'));
      });

      test('a combined total is never published for a single scope', () {
        final localOnly = _report([
          _local(kind: StorageCategoryKind.projects, bytes: 1000),
        ], filter: StorageScopeFilter.localOnly());

        expect(localOnly.mergedBytes, isNull);
        expect(localOnly.mergedLabel, isNull);
        expect(
          localOnly.warnings.any(
            (warning) => warning.contains('Local and remote storage'),
          ),
          isFalse,
        );
      });

      test('local free space is reported beside the used total, not in it', () {
        final report = _report([
          _local(kind: StorageCategoryKind.projects, bytes: 1000),
        ], localFreeBytes: 555);

        expect(report.localFreeBytes, 555);
        expect(report.localFreeLabel, '555 B free on this device');
        expect(report.chart.totalBytes, 1000);
        expect(report.mergedBytes, isNull);
        expect(
          report.warnings,
          contains(
            'Free device space is shown next to the used total and is never '
            'added to it.',
          ),
        );
      });
    });

    group('unknown_category', () {
      test('an unknown label is preserved, never folded into other', () {
        final report = _report([_local(label: 'vendor binaries')]);

        final slice = report.chart.slices.single;
        expect(slice.category.kind, StorageCategoryKind.unrecognized);
        expect(slice.category.label, 'vendor binaries');
        expect(slice.category.isCanonical, isFalse);
        expect(
          report.rows.single.category.kind,
          StorageCategoryKind.unrecognized,
        );
        expect(
          report.rows.single.category,
          isNot(StorageCategoryRef.canonical(StorageCategoryKind.other)),
        );
      });

      test('one label folds once, two labels keep both names', () {
        final report = _report([
          _local(label: 'fonts', bytes: 100),
          _local(label: 'fonts', bytes: 200),
          _local(label: 'vendor bins', bytes: 700),
        ]);

        final slice = report.chart.slices.single;
        expect(slice.bytes, 1000);
        expect(slice.recordCount, 3);
        expect(slice.unrecognizedLabels, <String>['fonts', 'vendor bins']);
        expect(slice.textAlternative, contains('vendor bins'));
        expect(report.unrecognizedCategoryCount, 2);
        expect(report.textSummary, contains('2 unrecognised categor'));
      });

      test('a blank or duplicate label is refused at the boundary', () {
        expect(
          () => StorageCategoryRef.unrecognized('   '),
          throwsArgumentError,
        );
        expect(
          () => StorageCategoryRef.canonical(StorageCategoryKind.unrecognized),
          throwsArgumentError,
        );
      });
    });

    group('freshness', () {
      test('the policy refuses impossible windows in every build mode', () {
        expect(
          () => StorageDistributionFreshnessPolicy(staleAfter: Duration.zero),
          throwsArgumentError,
        );
        expect(
          () => StorageDistributionFreshnessPolicy(
            staleAfter: const Duration(days: 7),
            expiresAfter: const Duration(days: 1),
          ),
          throwsArgumentError,
        );
      });

      test('classifies live, stale, expired, and future timestamps', () {
        final policy = StorageDistributionFreshnessPolicy();
        DateTime at(Duration age) => _now.subtract(age);

        expect(
          policy.classify(measuredAt: at(const Duration(hours: 1)), now: _now),
          StorageDistributionFreshness.live,
        );
        expect(
          policy.classify(measuredAt: at(const Duration(hours: 30)), now: _now),
          StorageDistributionFreshness.stale,
        );
        expect(
          policy.classify(measuredAt: at(const Duration(days: 9)), now: _now),
          StorageDistributionFreshness.expired,
        );
        expect(
          policy.classify(
            measuredAt: _now.add(const Duration(minutes: 5)),
            now: _now,
          ),
          StorageDistributionFreshness.futureTimestamped,
        );
      });

      test('a not-current record makes the total approximate, not exact', () {
        // 2026-09-01 is 25 days before the injected clock, past the 7-day
        // expiry window, so the record is expired rather than merely stale.
        final report = _report([
          _local(kind: StorageCategoryKind.projects, bytes: 1000),
          _local(
            kind: StorageCategoryKind.assets,
            bytes: 1000,
            measuredAt: DateTime.utc(2026, 9, 1),
          ),
        ]);

        expect(report.totalIsExact, isFalse);
        expect(report.totalLabel, 'Approximate');
        expect(report.totalReason, isNotNull);
        expect(report.warnings.join(' '), contains('not current'));
        expect(report.freshnessLabel, contains('1 expired'));
        expect(report.isCurrent, isFalse);

        // The same record inside the 24h stale window is stale, not expired.
        final staleReport = _report([
          _local(kind: StorageCategoryKind.projects, bytes: 1000),
          _local(
            kind: StorageCategoryKind.assets,
            bytes: 1000,
            measuredAt: DateTime.utc(2026, 9, 25, 6),
          ),
        ]);
        expect(staleReport.freshnessLabel, contains('1 stale'));
        expect(staleReport.totalLabel, 'Approximate');
      });

      test('an all-live single-scope total is exact and reported', () {
        final report = _report([
          _local(kind: StorageCategoryKind.projects, bytes: 1000),
        ]);

        expect(report.totalIsExact, isTrue);
        expect(report.totalLabel, 'Reported');
        expect(report.totalReason, isNull);
        expect(report.isCurrent, isTrue);
        expect(report.uiState, 'CONNECTED');
      });

      test('an unavailable reading says so instead of claiming zero', () {
        // No quota either: a reading that could not be obtained supplies
        // neither a size nor a limit, and inventing either would be a lie.
        final report = _report([
          _remote(
            source: StorageRecordSource.unavailable,
            bytes: 0,
            quotaBytes: null,
          ),
        ]);

        final row = report.rows.single;
        expect(row.isMeasured, isFalse);
        expect(row.sizeLabel, 'Size unavailable');
        expect(row.sourceLabel, 'Unavailable');
        expect(row.usedLabel, 'Size unavailable; Quota unavailable');
        expect(row.quotaLabel, 'Quota unavailable');
        expect(row.toPublicJson()['bytes'], isNull);
        expect(report.totalIsExact, isFalse);
        expect(report.warnings.join(' '), contains('Size unavailable'));
      });

      test('lastUpdatedAt is the newest measurement, null when empty', () {
        final report = _report([
          _local(measuredAt: DateTime.utc(2026, 9, 10)),
          _remote(measuredAt: DateTime.utc(2026, 9, 24)),
        ]);
        expect(report.lastUpdatedAt, DateTime.utc(2026, 9, 24));

        expect(_report([]).lastUpdatedAt, isNull);
      });
    });

    group('drill_down', () {
      test('every in-scope scope/category pair drills into its rows', () {
        final report = _report([
          _local(kind: StorageCategoryKind.projects, bytes: 400),
          _local(kind: StorageCategoryKind.projects, bytes: 600),
          _remote(kind: StorageCategoryKind.assets, bytes: 2000),
        ]);

        final ids = report.drillDowns
            .map((entry) => entry.targetId)
            .toList(growable: false);
        expect(ids, <String>['local/projects', 'remote/assets']);

        final local = report.drillDownFor('local/projects')!;
        expect(local.isAvailable, isTrue);
        expect(local.rows.length, 2);
        expect(local.recordCount, 2);
        expect(local.textAlternative.trim(), isNotEmpty);
        expect(local.textAlternative, contains('Projects'));
      });

      test('an unrecognized drill-down names every raw label', () {
        final report = _report([
          _local(label: 'fonts', bytes: 100),
          _local(label: 'vendor bins', bytes: 700),
        ]);

        final drillDown = report.drillDowns.single;
        expect(drillDown.targetId, 'local/unrecognized');
        expect(drillDown.unrecognizedLabels, <String>['fonts', 'vendor bins']);
        // Headed as the unrecognised bucket, not as one of its raw labels.
        expect(drillDown.label, 'Unrecognised categories on local storage');
        expect(drillDown.textAlternative, contains('fonts'));
        expect(drillDown.textAlternative, contains('vendor bins'));
      });

      test('a filtered-out drill-down is unavailable with a reason', () {
        final full = _report([
          _local(kind: StorageCategoryKind.projects, bytes: 400),
          _remote(kind: StorageCategoryKind.assets, bytes: 2000),
        ]);
        final narrowed = _report([
          _local(kind: StorageCategoryKind.projects, bytes: 400),
          _remote(kind: StorageCategoryKind.assets, bytes: 2000),
        ], filter: StorageScopeFilter.localOnly());

        final remoteOnly = narrowed.drillDownFor('remote/assets');
        expect(remoteOnly, isNull);
        expect(
          narrowed.unavailableDrillDowns.map((entry) => entry.targetId),
          contains('remote/assets'),
        );
        final entry = narrowed.unavailableDrillDowns.firstWhere(
          (candidate) => candidate.targetId == 'remote/assets',
        );
        expect(entry.isAvailable, isFalse);
        expect(entry.reason, isNotNull);
        expect(entry.reason!.trim(), isNotEmpty);
        expect(full.drillDownFor('remote/assets'), isNotNull);
      });

      test('drill-down rows never cross the local/remote boundary', () {
        final report = _report([
          _local(kind: StorageCategoryKind.assets, bytes: 1000),
          _remote(kind: StorageCategoryKind.assets, bytes: 2000),
        ]);

        for (final entry in report.drillDowns) {
          final scope = entry.targetId.split('/').first;
          for (final row in entry.rows) {
            expect(row.scope.wireName, scope);
          }
        }
      });
    });

    group('report state', () {
      test('empty reasons distinguish no data from a filter that hid it', () {
        expect(_report([]).emptyReason, StorageDistributionEmptyReason.noData);
        expect(
          _report([
            _local(),
          ], filter: StorageScopeFilter.remoteOnly()).emptyReason,
          StorageDistributionEmptyReason.filteredOut,
        );
        expect(_report([]).uiState, 'EMPTY');
        expect(_report([]).textSummary.trim(), isNotEmpty);
        expect(_report([]).isRenderable, isFalse);
      });

      test('a partial picture reports PARTIAL_DATA, not success', () {
        final report = _report([
          _local(kind: StorageCategoryKind.projects, bytes: 1000),
          _remote(source: StorageRecordSource.unavailable, bytes: 0),
        ]);

        expect(report.uiState, 'PARTIAL_DATA');
        expect(report.isRenderable, isTrue);
      });

      test('collections are immutable and the clock is injected', () {
        final report = _report([
          _local(kind: StorageCategoryKind.assets),
          _local(kind: StorageCategoryKind.backups),
        ]);

        expect(() => report.rows.removeLast(), throwsUnsupportedError);
        expect(() => report.chart.slices.clear(), throwsUnsupportedError);
        expect(() => report.drillDowns.clear(), throwsUnsupportedError);
        expect(report.lastUpdatedAt, DateTime.utc(2026, 9, 26, 6));
      });

      test('external gates stay deferred and no live read is claimed', () {
        expect(
          AccountCenterStorageDistributionReport.externalGateStatus,
          'DEFERRED-EXTERNAL',
        );
        expect(
          AccountCenterStorageDistributionReport.storageContractStatus,
          'METADATA_ONLY_NO_PROVIDER_READ',
        );
        expect(
          AccountCenterStorageDistributionReport.performsProviderRead,
          isFalse,
        );
      });
    });
  });
}
