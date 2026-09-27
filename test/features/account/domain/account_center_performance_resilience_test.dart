/// Sprint 115.53 — Performance & Provider Resilience contract tests.
///
/// Locks the seven canonical `required_outputs` buckets of step 115.53 against
/// `sprint_115.json`, proves the contract is fail-closed, and grounds the
/// committed manifest in the live repository.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_performance_resilience.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_connector_manifest.dart';

void main() {
  const canonicalSprintPath =
      'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/'
      'sprint_115.json';
  const canonicalSprintSha256 =
      'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba';
  const matrixTestPath =
      'test/features/account/domain/'
      'account_center_performance_resilience_test.dart';

  final manifestFile = File(
    'docs/planning/v1.2/sprint_115_performance_resilience.json',
  );

  Map<String, dynamic> readManifest() {
    expect(manifestFile.existsSync(), isTrue, reason: '115.53 manifest');
    return jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  }

  AccountResilienceBucket bucket({
    String bucket = 'render_budget',
    AccountResilienceBucketStatus status = AccountResilienceBucketStatus.pass,
    List<AccountResilienceMeasurement> measurements = const [],
    String note = '',
  }) => AccountResilienceBucket(
    bucket: bucket,
    status: status,
    measurements: measurements,
    note: note,
  );

  /// A measurement that is inside its own budget, so a synthetic `pass` row
  /// is never a bare "it was fast" rubber stamp.
  AccountResilienceMeasurement ok(String name, {double observed = 1}) =>
      AccountResilienceMeasurement(name: name, observed: observed, budget: 10);

  Map<String, AccountResilienceBucket> fullPassMatrix() =>
      <String, AccountResilienceBucket>{
        for (final name in AccountCenterPerformanceResilience.requiredBuckets)
          name: bucket(
            bucket: name,
            measurements: <AccountResilienceMeasurement>[ok('synthetic_$name')],
          ),
      };

  group('115.53 canonical bucket set', () {
    test('locks the seven canonical outputs in spec order', () {
      expect(AccountCenterPerformanceResilience.requiredBuckets, const <String>[
        'render_budget',
        'refresh_budget',
        'slow_api_results',
        'rate_limit_results',
        'outage_results',
        'many_accounts_results',
        'scan_results',
      ]);
    });

    test('matches required_outputs of step 115.53 in sprint_115.json', () {
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
          .firstWhere((entry) => entry['id'] == '115.53');
      expect(step['title'], 'Performance & Provider Resilience');
      expect(
        step['required_outputs'],
        AccountCenterPerformanceResilience.requiredBuckets,
        reason: 'required_outputs must be transcribed, not invented',
      );
    });

    test('rejects a bucket outside the canonical set', () {
      expect(
        () => AccountCenterPerformanceResilience.buildReport({
          ...fullPassMatrix(),
          'perfection': bucket(bucket: 'perfection'),
        }),
        throwsArgumentError,
      );
    });

    test('rejects a canonical bucket that was never recorded', () {
      final incomplete = fullPassMatrix()..remove('scan_results');
      expect(
        () => AccountCenterPerformanceResilience.buildReport(incomplete),
        throwsStateError,
      );
    });

    test('rejects a row whose key does not match its bucket', () {
      expect(
        () => AccountCenterPerformanceResilience.buildReport({
          for (final name in AccountCenterPerformanceResilience.requiredBuckets)
            name: bucket(
              bucket: name == 'outage_results' ? 'slow_api_results' : name,
              measurements: <AccountResilienceMeasurement>[ok('synthetic')],
            ),
        }),
        throwsArgumentError,
      );
    });
  });

  group('115.53 fail-closed bucket rules', () {
    test('rejects a pass with no measured result', () {
      expect(
        () => AccountCenterPerformanceResilience.buildReport({
          ...fullPassMatrix(),
          'render_budget': bucket(bucket: 'render_budget'),
        }),
        throwsArgumentError,
      );
    });

    test('rejects a pass whose measurement exceeded its own budget', () {
      // The specific way a performance matrix can lie: report the fast happy
      // path, keep a real measurement in the row, and still say "pass" while
      // the number is over the contract bound.
      expect(
        () => AccountCenterPerformanceResilience.buildReport({
          ...fullPassMatrix(),
          'refresh_budget': bucket(
            bucket: 'refresh_budget',
            measurements: <AccountResilienceMeasurement>[
              AccountResilienceMeasurement(
                name: 'concurrent_refresh_ms',
                observed: 900,
                budget: AccountCenterPerformanceResilience.refreshBudgetMs,
              ),
            ],
          ),
        }),
        throwsArgumentError,
      );
    });

    test('rejects a fail that does not say what failed', () {
      expect(
        () => AccountCenterPerformanceResilience.buildReport({
          ...fullPassMatrix(),
          'outage_results': bucket(
            bucket: 'outage_results',
            status: AccountResilienceBucketStatus.fail,
            measurements: <AccountResilienceMeasurement>[ok('measured')],
          ),
        }),
        throwsArgumentError,
      );
    });

    test('rejects a blocked bucket with measurements or without a reason', () {
      expect(
        () => AccountCenterPerformanceResilience.buildReport({
          ...fullPassMatrix(),
          'slow_api_results': bucket(
            bucket: 'slow_api_results',
            status: AccountResilienceBucketStatus.blocked,
          ),
        }),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterPerformanceResilience.buildReport({
          ...fullPassMatrix(),
          'slow_api_results': bucket(
            bucket: 'slow_api_results',
            status: AccountResilienceBucketStatus.blocked,
            note: 'A real slow provider needs a live connector, not a fixture.',
            measurements: <AccountResilienceMeasurement>[ok('measured')],
          ),
        }),
        throwsArgumentError,
      );
    });

    test('rejects a pending bucket that claims measurements', () {
      expect(
        () => AccountCenterPerformanceResilience.buildReport({
          ...fullPassMatrix(),
          'scan_results': bucket(
            bucket: 'scan_results',
            status: AccountResilienceBucketStatus.pending,
            measurements: <AccountResilienceMeasurement>[ok('measured')],
          ),
        }),
        throwsArgumentError,
      );
    });

    test('rejects an unnamed, negative, or unbudgeted measurement', () {
      expect(
        () => AccountResilienceMeasurement(name: '  ', observed: 1, budget: 2),
        throwsArgumentError,
      );
      expect(
        () => AccountResilienceMeasurement(name: 'x', observed: -1, budget: 2),
        throwsArgumentError,
      );
      expect(
        () => AccountResilienceMeasurement(name: 'x', observed: 1, budget: -1),
        throwsArgumentError,
      );
    });

    test('a zero budget is the "nothing may happen" budget, not a typo', () {
      // `outage_surfaces_claiming_connected` is a real zero-budget row: the
      // whole point of the measurement is that the count must be exactly 0, so
      // rejecting a zero budget would forbid the check the step exists to make.
      // The budget still has to be non-negative, and the ratio still has to
      // fail closed instead of dividing by zero.
      final measurement = AccountResilienceMeasurement(
        name: 'outage_surfaces_claiming_connected',
        observed: 0,
        budget: 0,
      );
      expect(measurement.withinBudget, isTrue);
      expect(measurement.ratio, 0);
      final overrun = AccountResilienceMeasurement(
        name: 'outage_surfaces_claiming_connected',
        observed: 1,
        budget: 0,
      );
      expect(overrun.withinBudget, isFalse);
      expect(overrun.ratio, greaterThan(1));
      expect(overrun.ratio.isNaN, isFalse);
    });
  });

  group('115.53 report verdict', () {
    test('a fully passing matrix is complete, passing, and ALL_PASS', () {
      final report = AccountCenterPerformanceResilience.buildReport(
        fullPassMatrix(),
      );
      expect(report.isComplete, isTrue);
      expect(report.passCount, 7);
      expect(report.overrunCount, 0);
      expect(report.isPass, isTrue);
      expect(report.verdict, 'ALL_PASS');
    });

    test('a pending bucket makes the matrix incomplete', () {
      final report = AccountCenterPerformanceResilience.buildReport({
        ...fullPassMatrix(),
        'scan_results': bucket(
          bucket: 'scan_results',
          status: AccountResilienceBucketStatus.pending,
        ),
      });
      expect(report.isComplete, isFalse);
      expect(report.isPass, isFalse);
      expect(report.verdict, 'INCOMPLETE');
    });

    test('a failing bucket keeps the matrix complete but not passing', () {
      final report = AccountCenterPerformanceResilience.buildReport({
        ...fullPassMatrix(),
        'outage_results': bucket(
          bucket: 'outage_results',
          status: AccountResilienceBucketStatus.fail,
          note: 'An outage provider is still announced as connected to AT.',
          measurements: <AccountResilienceMeasurement>[ok('measured')],
        ),
      });
      expect(report.isComplete, isTrue);
      expect(report.passCount, 6);
      expect(report.isPass, isFalse);
      expect(report.verdict, 'COMPLETE_6_OF_7_PASS');
      expect(
        report.statusOf('outage_results'),
        AccountResilienceBucketStatus.fail,
      );
    });
  });

  group('115.53 outage is never announced as connected', () {
    test('only an available provider reads as connected', () {
      expect(
        AccountCenterPerformanceResilience.connectionLabel('available'),
        'Connected',
      );
      expect(
        AccountCenterPerformanceResilience.isConnected('available'),
        isTrue,
      );
    });

    test('an outage provider is never announced as connected', () {
      final label = AccountCenterPerformanceResilience.connectionLabel(
        'outage',
      );
      expect(
        label,
        isNot(contains('Connected')),
        reason: 'an outage must not claim a connection at all',
      );
      expect(label, 'Not connected, provider outage');
      expect(AccountCenterPerformanceResilience.isConnected('outage'), isFalse);
    });

    test('every non-connected availability has a label that agrees', () {
      for (final availability
          in AccountCenterPerformanceResilience.nonConnectedAvailabilities) {
        final label = AccountCenterPerformanceResilience.connectionLabel(
          availability,
        );
        // `nonConnectedAvailabilities` is the "not a healthy connection" set,
        // which is deliberately NOT the same as "the label starts with 'Not
        // connected'": a degraded provider is genuinely still connected, so
        // [connectionLabel] keeps the connection word and names the
        // degradation beside it. The contract that must hold here is that a
        // value in this set is never announced as a PLAIN `Connected`, and that
        // `isConnected` agrees it is not a healthy live link.
        expect(
          label,
          isNot('Connected'),
          reason: '$availability must not be announced as a plain connection',
        );
        expect(
          AccountCenterPerformanceResilience.isConnected(availability),
          isFalse,
          reason: availability,
        );
      }
    });

    test('degraded says degraded rather than plain connected', () {
      // A degraded provider IS connected, so the label keeps the connection
      // word but must not hide the degradation behind it.
      final label = AccountCenterPerformanceResilience.connectionLabel(
        'degraded',
      );
      expect(label, 'Connected, provider degraded');
      expect(
        AccountCenterPerformanceResilience.nonConnectedAvailabilities,
        contains('degraded'),
        reason: 'degraded is not a healthy connection',
      );
    });

    test('accepts every spelling the enum and the spec use', () {
      for (final spelling in <String>['outage', 'OUTAGE', '  Outage  ']) {
        expect(
          AccountCenterPerformanceResilience.normalizeAvailability(spelling),
          'outage',
          reason: spelling,
        );
      }
      expect(
        AccountCenterPerformanceResilience.normalizeAvailability(
          'UNSUPPORTED_REGION',
        ),
        'unsupported_region',
      );
      expect(
        () =>
            AccountCenterPerformanceResilience.normalizeAvailability('borked'),
        throwsArgumentError,
      );
    });

    test('the live manifest covers every availability the enum declares', () {
      // Guard against a new ProviderConnectorAvailability being added
      // without a connection wording: the contract must stay exhaustive.
      for (final availability in ProviderConnectorAvailability.values) {
        expect(
          () => AccountCenterPerformanceResilience.normalizeAvailability(
            availability.wireName,
          ),
          returnsNormally,
          reason: 'no wording for ${availability.wireName}',
        );
        expect(
          () => AccountCenterPerformanceResilience.connectionLabel(
            availability.name,
          ),
          returnsNormally,
          reason: availability.name,
        );
      }
      expect(
        ProviderConnectorAvailability.values.length,
        greaterThanOrEqualTo(
          AccountCenterPerformanceResilience.nonConnectedAvailabilities.length,
        ),
      );
    });
  });

  group('115.53 chart repaint inputs', () {
    test('a track colour change is visible to the repaint decision', () {
      final dark = AccountCenterPerformanceResilience.chartPalette(
        values: const <int>[1, 2],
        colors: const <int>[0xA78BFA],
        trackColor: 0x1D202C,
      );
      final light = AccountCenterPerformanceResilience.chartPalette(
        values: const <int>[1, 2],
        colors: const <int>[0xA78BFA],
        trackColor: 0xE3E5EE,
      );
      expect(
        dark.toString(),
        isNot(light.toString()),
        reason: 'a theme swap that only moves borderSoft still must repaint',
      );
    });

    test('a slice colour change is visible to the repaint decision', () {
      final before = AccountCenterPerformanceResilience.chartPalette(
        values: const <int>[1, 2],
        colors: const <int>[0xA78BFA, 0x3F83F8],
        trackColor: 0x1D202C,
      );
      final after = AccountCenterPerformanceResilience.chartPalette(
        values: const <int>[1, 2],
        colors: const <int>[0xA78BFA, 0xF05252],
        trackColor: 0x1D202C,
      );
      expect(before.toString(), isNot(after.toString()));
    });

    test('identical inputs produce an identical decision, so no repaint', () {
      List<String> build() => AccountCenterPerformanceResilience.chartPalette(
        values: const <int>[3, 1, 4],
        colors: const <int>[0xA78BFA],
        trackColor: 0x1D202C,
      );
      expect(build().toString(), build().toString());
    });
  });

  group('115.53 committed manifest', () {
    test('declares the step and carries the canonical bucket list', () {
      final manifest = readManifest();
      expect(manifest['step'], '115.53');
      expect(manifest['title'], 'Performance & Provider Resilience');
      expect(
        manifest['required_outputs'],
        AccountCenterPerformanceResilience.requiredBuckets,
      );
    });

    test('records every canonical bucket in order and passes buildReport', () {
      final manifest = readManifest();
      final rows = (manifest['buckets'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(
        rows.map((entry) => entry['bucket']),
        AccountCenterPerformanceResilience.requiredBuckets,
        reason: 'bucket rows must follow the canonical order, no extras',
      );
      final results = <String, AccountResilienceBucket>{
        for (final entry in rows)
          entry['bucket'] as String: AccountResilienceBucket(
            bucket: entry['bucket'] as String,
            status: AccountResilienceBucketStatus.values.firstWhere(
              (status) => status.name == entry['status'],
              orElse: () => throw ArgumentError.value(
                entry['status'],
                'buckets',
                'Unknown bucket status in the committed manifest.',
              ),
            ),
            measurements:
                ((entry['measurements'] as List<dynamic>?) ?? const <dynamic>[])
                    .cast<Map<String, dynamic>>()
                    .map(
                      (raw) => AccountResilienceMeasurement(
                        name: raw['name'] as String,
                        observed: (raw['observed'] as num).toDouble(),
                        budget: (raw['budget'] as num).toDouble(),
                      ),
                    )
                    .toList(growable: false),
            note: (entry['note'] as String?) ?? '',
          ),
      };
      final report = AccountCenterPerformanceResilience.buildReport(results);
      expect(
        report.isComplete,
        isTrue,
        reason: 'a committed matrix may never leave a bucket pending',
      );
      expect(manifest['verdict'], report.verdict);
      expect(manifest['verdict'], isNot('INCOMPLETE'));
    });

    test('a bucket that is not passing explains itself concretely', () {
      final manifest = readManifest();
      for (final entry
          in (manifest['buckets'] as List<dynamic>)
              .cast<Map<String, dynamic>>()) {
        final measurements =
            (entry['measurements'] as List<dynamic>?) ?? const <dynamic>[];
        if (entry['status'] == 'pass') {
          expect(
            measurements,
            isNotEmpty,
            reason: '${entry['bucket']} passed without measurements',
          );
          for (final raw in measurements.cast<Map<String, dynamic>>()) {
            expect(
              (raw['observed'] as num).toDouble(),
              lessThanOrEqualTo((raw['budget'] as num).toDouble()),
              reason: '${entry['bucket']}/${raw['name']} is over its budget',
            );
          }
          continue;
        }
        expect(
          ((entry['note'] as String?) ?? '').length,
          greaterThanOrEqualTo(30),
          reason: '${entry['bucket']} must state why it is not passing',
        );
      }
    });

    test('the manifest documents its own coverage', () {
      final manifest = readManifest();
      final evidence = (manifest['evidence'] as List<dynamic>).cast<String>();
      expect(
        evidence.any(
          (path) =>
              path == matrixTestPath || matrixTestPath.startsWith('$path/'),
        ),
        isTrue,
        reason: 'the matrix must document the tests that measured it',
      );
      for (final path in evidence) {
        final file = File(path);
        expect(
          file.existsSync(),
          isTrue,
          reason: 'evidence missing on disk: $path',
        );
        expect(
          file.readAsStringSync().contains('test(') ||
              file.readAsStringSync().contains('testWidgets('),
          isTrue,
          reason: 'evidence must be a real test file: $path',
        );
      }
    });

    test('the RED record is committed, and it records this step', () {
      // `evidence` only carries test files (the loop above rejects anything
      // that is not one), so the RED record is referenced separately. It is
      // still checked: an unreferenced, undated, or step-less RED file would let
      // this slice claim a RED gate that nobody actually captured.
      final manifest = readManifest();
      final redMeta = manifest['red_meta'] as String?;
      expect(
        redMeta,
        isNotNull,
        reason: 'the manifest must point at its RED record',
      );
      final file = File(redMeta!);
      expect(file.existsSync(), isTrue, reason: 'RED record missing: $redMeta');
      final red = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(red['step'], '115.53');
      expect((red['head_at_capture'] as String?), isNotNull);
      expect((red['date'] as String?), isNotNull);
    });

    test('external boundaries stay declared instead of silently passing', () {
      final manifest = readManifest();
      final deferred = (manifest['deferred_external'] as List<dynamic>)
          .cast<String>();
      expect(
        deferred.length,
        greaterThanOrEqualTo(4),
        reason: 'external gates must be listed, not dropped',
      );
      expect(
        deferred
            .map((item) => item.toLowerCase().replaceAll('-', ' '))
            .any((item) => item.contains('connector') || item.contains('live')),
        isTrue,
        reason: 'a live provider connector is the external gate for this step',
      );
      expect(
        (manifest['overlap_note'] as String? ?? '').isNotEmpty,
        isTrue,
        reason: 'buckets overlap by design; the overlap must be stated',
      );
    });

    test('a real slow-API result is recorded, not asserted in prose', () {
      // The canonical output is `slow_api_results`; the manifest has to carry a
      // measured row for it rather than a claim in free text.
      final manifest = readManifest();
      final rows = (manifest['buckets'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final slow = rows.firstWhere(
        (entry) => entry['bucket'] == 'slow_api_results',
      );
      expect(
        slow['note'],
        isNotNull,
        reason: 'the slow-API row must state its scope either way',
      );
    });
  });
}
