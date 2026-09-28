import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_offline_cached_metadata_certification.dart';

void main() {
  group('116.44 Offline & Cached Metadata Certification', () {
    test('locks the six offline and cached metadata acceptance areas', () {
      expect(Sprint116OfflineCacheContract.requiredAreas, <String>[
        'freshness_label',
        'stale_state',
        'remote_disable',
        'local_actions',
        'reconnect',
        'cache_clear',
      ]);
      expect(Sprint116OfflineCacheContract.canonicalStep, '116.44');
      expect(Sprint116OfflineCacheContract.externalGates, 'DEFERRED-EXTERNAL');
      expect(Sprint116OfflineCacheContract.freshnessLabels, <String>[
        'fresh',
        'stale',
        'unavailable',
      ]);
      expect(Sprint116OfflineCacheContract.localActions, <String>[
        'open_project_tree',
        'edit_chapter',
        'save_draft',
        'view_history',
        'view_cached_avatar',
        'export_local',
        'rename_local',
      ]);
    });

    test('age is classified into the declared label the contract demands', () {
      String classify({
        required bool valueAvailable,
        required int ageSeconds,
        required int freshTtlSeconds,
      }) => Sprint116OfflineCacheContract.expectedLabel(
        valueAvailable: valueAvailable,
        ageSeconds: ageSeconds,
        freshTtlSeconds: freshTtlSeconds,
      );

      expect(
        classify(valueAvailable: true, ageSeconds: 100, freshTtlSeconds: 3600),
        'fresh',
      );
      expect(
        classify(valueAvailable: true, ageSeconds: 3600, freshTtlSeconds: 3600),
        'fresh',
      );
      expect(
        classify(valueAvailable: true, ageSeconds: 3601, freshTtlSeconds: 3600),
        'stale',
      );
      // A failed fetch has no value to age; it is unavailable, not fresh and
      // never zero-valued.
      expect(
        classify(valueAvailable: false, ageSeconds: 0, freshTtlSeconds: 3600),
        'unavailable',
      );
    });

    test('a complete healthy record set certifies and covers every area', () {
      final report = Sprint116OfflineCacheCertification().certify(
        entries: _healthyEntries(),
        clears: _healthyClears(),
        asOfEpochMs: _now,
        requireCoverage: true,
      );

      expect(report.state, Sprint116OfflineCacheStatus.pass);
      expect(report.invalidRecords, isEmpty);
      for (final area in Sprint116OfflineCacheContract.requiredAreas) {
        expect(report.coveredAreas, contains(area));
      }
    });

    test('an empty record set is blocked rather than certified', () {
      final noEntries = Sprint116OfflineCacheCertification().certify(
        entries: const <Sprint116CacheEntry>[],
        clears: _healthyClears(),
        asOfEpochMs: _now,
      );
      expect(noEntries.state, Sprint116OfflineCacheStatus.blocked);
      expect(noEntries.invalidRecords, contains('entries'));

      final noClears = Sprint116OfflineCacheCertification().certify(
        entries: _healthyEntries(),
        clears: const <Sprint116CacheClearRecord>[],
        asOfEpochMs: _now,
      );
      expect(noClears.state, Sprint116OfflineCacheStatus.blocked);
      expect(noClears.invalidRecords, contains('clears'));
    });

    test('freshness cannot be certified without a clock', () {
      // Age is measured against a reference instant; without one every record
      // would pass on an unmeasured assumption.
      final noClock = Sprint116OfflineCacheCertification().certify(
        entries: _healthyEntries(),
        clears: _healthyClears(),
      );
      expect(noClock.state, Sprint116OfflineCacheStatus.blocked);
      expect(noClock.invalidRecords, contains('as_of_epoch_ms'));
    });

    test('record identity and cache timestamps are required', () {
      final report = Sprint116OfflineCacheCertification().certify(
        entries: <Sprint116CacheEntry>[
          _entry(
            entryId: '',
            providerId: 'provider_a',
            resourceId: 'chapter_1',
            cachedAtEpochMs: 1700000000000,
            asOfEpochMs: 1699999990000,
            freshnessLabel: 'fresh',
          ),
          _entry(
            entryId: 'ent_no_provider',
            providerId: '  ',
            resourceId: 'chapter_2',
            cachedAtEpochMs: 1700000000000,
            asOfEpochMs: 1699999990000,
            freshnessLabel: 'fresh',
          ),
          _entry(
            entryId: 'ent_no_cache_time',
            providerId: 'provider_a',
            resourceId: 'chapter_3',
            cachedAtEpochMs: 0,
            asOfEpochMs: 1699999990000,
            freshnessLabel: 'fresh',
          ),
          _entry(
            entryId: 'ent_no_ttl',
            providerId: 'provider_a',
            resourceId: 'chapter_4',
            cachedAtEpochMs: 1700000000000,
            asOfEpochMs: 1699999990000,
            freshnessLabel: 'fresh',
            freshTtlSeconds: 0,
          ),
        ],
        clears: _healthyClears(),
        asOfEpochMs: _now,
      );

      expect(report.state, Sprint116OfflineCacheStatus.fail);
      expect(report.invalidRecords, contains('record_id:0'));
      expect(report.invalidRecords, contains('provider_id:ent_no_provider'));
      expect(
        report.invalidRecords,
        contains('freshness_label:ent_no_cache_time'),
      );
      expect(report.invalidRecords, contains('freshness_label:ent_no_ttl'));
    });

    test(
      'cache data cannot be newer than the write, the clock, or the source',
      () {
        // as_of after the cache write means the cache knows something the write
        // did not contain; after the reference instant means it is future dated.
        final writtenBeforeSource = Sprint116OfflineCacheCertification()
            .certify(
              entries: <Sprint116CacheEntry>[
                _entry(
                  entryId: 'ent_ahead_of_write',
                  providerId: 'provider_a',
                  resourceId: 'chapter_1',
                  cachedAtEpochMs: 1700000000000,
                  asOfEpochMs: 1700000005000,
                  freshnessLabel: 'fresh',
                ),
              ],
              clears: _healthyClears(),
              asOfEpochMs: _now,
            );
        expect(
          writtenBeforeSource.invalidRecords,
          contains('freshness_label:ent_ahead_of_write'),
        );

        final futureDated = Sprint116OfflineCacheCertification().certify(
          entries: <Sprint116CacheEntry>[
            _entry(
              entryId: 'ent_future',
              providerId: 'provider_a',
              resourceId: 'chapter_1',
              cachedAtEpochMs: 1700000000000,
              asOfEpochMs: 1699999990000,
              freshnessLabel: 'fresh',
              // One second past the reference instant used by the suite.
              cachedAtEpochMsOverride: 1700000999000,
            ),
          ],
          clears: _healthyClears(),
          asOfEpochMs: _now,
        );
        expect(
          futureDated.invalidRecords,
          contains('freshness_label:ent_future'),
        );
      },
    );

    test('stale data labelled fresh is rejected', () {
      // The single most dangerous defect: a connector that keeps presenting a
      // 19 minute old billing snapshot as fresh. The write is 10 100 s old
      // against a 3 600 s TTL, so the label it must carry is provably `stale`.
      final lying = Sprint116OfflineCacheCertification().certify(
        entries: <Sprint116CacheEntry>[
          _entry(
            entryId: 'ent_stale_labelled_fresh',
            providerId: 'provider_a',
            resourceId: 'billing_snapshot',
            cachedAtEpochMs: 1699990000000,
            asOfEpochMs: 1699989990000,
            freshnessLabel: 'fresh',
          ),
        ],
        clears: _healthyClears(),
        asOfEpochMs: _now,
      );
      expect(lying.state, Sprint116OfflineCacheStatus.fail);
      expect(
        lying.invalidRecords,
        contains('freshness_label:ent_stale_labelled_fresh'),
      );
      expect(lying.staleEntryIds, isNot(contains('ent_stale_labelled_fresh')));

      final honest = Sprint116OfflineCacheCertification().certify(
        entries: <Sprint116CacheEntry>[
          _entry(
            entryId: 'ent_stale_labelled_stale',
            providerId: 'provider_a',
            resourceId: 'billing_snapshot',
            cachedAtEpochMs: 1699990000000,
            asOfEpochMs: 1699989990000,
            freshnessLabel: 'stale',
          ),
        ],
        clears: _healthyClears(),
        asOfEpochMs: _now,
      );
      expect(honest.invalidRecords, isEmpty);
      expect(honest.staleEntryIds, contains('ent_stale_labelled_stale'));
    });

    test('an unknown freshness label is not accepted as a label', () {
      final report = Sprint116OfflineCacheCertification().certify(
        entries: <Sprint116CacheEntry>[
          _entry(
            entryId: 'ent_vague_label',
            providerId: 'provider_a',
            resourceId: 'chapter_1',
            cachedAtEpochMs: 1700000000000,
            asOfEpochMs: 1699999990000,
            freshnessLabel: 'probably_fine',
          ),
        ],
        clears: _healthyClears(),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116OfflineCacheStatus.fail);
      expect(
        report.invalidRecords,
        contains('freshness_label:ent_vague_label'),
      );
    });

    test('a missing value is unavailable, never fresh and never zero', () {
      final masquerading = Sprint116OfflineCacheCertification().certify(
        entries: <Sprint116CacheEntry>[
          _entry(
            entryId: 'ent_missing_fresh',
            providerId: 'provider_a',
            resourceId: 'avatar_metadata',
            cachedAtEpochMs: 1700000000000,
            asOfEpochMs: 1699999990000,
            freshnessLabel: 'fresh',
            valueAvailable: false,
          ),
        ],
        clears: _healthyClears(),
        asOfEpochMs: _now,
      );
      expect(
        masquerading.invalidRecords,
        contains('freshness_label:ent_missing_fresh'),
      );

      final honest = Sprint116OfflineCacheCertification().certify(
        entries: <Sprint116CacheEntry>[
          _entry(
            entryId: 'ent_missing_unavailable',
            providerId: 'provider_a',
            resourceId: 'avatar_metadata',
            cachedAtEpochMs: 1700000000000,
            asOfEpochMs: 1699999990000,
            freshnessLabel: 'unavailable',
            valueAvailable: false,
          ),
        ],
        clears: _healthyClears(),
        asOfEpochMs: _now,
      );
      expect(honest.invalidRecords, isEmpty);
      expect(honest.unavailableEntryIds, contains('ent_missing_unavailable'));
    });

    test('remote actions must be disabled while offline', () {
      // Queueing a remote write that cannot complete is how a local first app
      // silently loses the user's edit.
      final report = Sprint116OfflineCacheCertification().certify(
        entries: <Sprint116CacheEntry>[
          _entry(
            entryId: 'ent_offline_pushable',
            providerId: 'provider_a',
            resourceId: 'revision_1',
            cachedAtEpochMs: 1700000000000,
            asOfEpochMs: 1699999990000,
            freshnessLabel: 'fresh',
            offline: true,
            remoteActionEnabled: true,
            localActions: <String>['save_draft'],
          ),
        ],
        clears: _healthyClears(),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116OfflineCacheStatus.fail);
      expect(
        report.invalidRecords,
        contains('remote_disable:ent_offline_pushable'),
      );
    });

    test('offline records must still allow local work', () {
      final deadEnd = Sprint116OfflineCacheCertification().certify(
        entries: <Sprint116CacheEntry>[
          _entry(
            entryId: 'ent_offline_dead_end',
            providerId: 'provider_a',
            resourceId: 'chapter_1',
            cachedAtEpochMs: 1700000000000,
            asOfEpochMs: 1699999990000,
            freshnessLabel: 'fresh',
            offline: true,
            remoteActionEnabled: false,
            localActionEnabled: false,
            localActions: const <String>[],
          ),
        ],
        clears: _healthyClears(),
        asOfEpochMs: _now,
      );
      expect(
        deadEnd.invalidRecords,
        contains('local_actions:ent_offline_dead_end'),
      );

      // A remote operation is not a local action.
      final remoteAsLocal = Sprint116OfflineCacheCertification().certify(
        entries: <Sprint116CacheEntry>[
          _entry(
            entryId: 'ent_remote_as_local',
            providerId: 'provider_a',
            resourceId: 'chapter_1',
            cachedAtEpochMs: 1700000000000,
            asOfEpochMs: 1699999990000,
            freshnessLabel: 'fresh',
            offline: true,
            remoteActionEnabled: false,
            localActions: <String>['push_revision_to_remote'],
          ),
        ],
        clears: _healthyClears(),
        asOfEpochMs: _now,
      );
      expect(
        remoteAsLocal.invalidRecords,
        contains('local_actions:ent_remote_as_local'),
      );
    });

    test('a reconnect must refresh the cache after the outage is detected', () {
      // Detecting the outage and then serving the same bytes is not a refresh.
      final noRefresh = Sprint116OfflineCacheCertification().certify(
        entries: <Sprint116CacheEntry>[
          _reconnectEntry(
            entryId: 'ent_reconnect_no_refresh',
            reconnectRefreshed: false,
          ),
        ],
        clears: _healthyClears(),
        asOfEpochMs: _now,
      );
      expect(noRefresh.state, Sprint116OfflineCacheStatus.fail);
      expect(
        noRefresh.invalidRecords,
        contains('reconnect:ent_reconnect_no_refresh'),
      );

      // A refresh timestamped before detection cannot be the reconnect
      // refresh; it is a pre outage read wearing a refresh label.
      final preOutageRefresh = Sprint116OfflineCacheCertification().certify(
        entries: <Sprint116CacheEntry>[
          _reconnectEntry(
            entryId: 'ent_reconnect_pre_outage_refresh',
            reconnectDetectedEpochMs: 1699999500000,
            reconnectRefreshEpochMs: 1699999000000,
            cachedAtEpochMs: 1700000050000,
            asOfEpochMs: 1700000045000,
          ),
        ],
        clears: _healthyClears(),
        asOfEpochMs: _now,
      );
      expect(
        preOutageRefresh.invalidRecords,
        contains('reconnect:ent_reconnect_pre_outage_refresh'),
      );

      // The cache write may not predate the refresh it claims to come from.
      // The write is 10 100 s old, so the `stale` label on it is honest; the
      // reconnect contract is what must reject it.
      final staleWrite = Sprint116OfflineCacheCertification().certify(
        entries: <Sprint116CacheEntry>[
          _reconnectEntry(
            entryId: 'ent_reconnect_stale_write',
            cachedAtEpochMs: 1699990000000,
            asOfEpochMs: 1699989990000,
            freshnessLabelOverride: 'stale',
          ),
        ],
        clears: _healthyClears(),
        asOfEpochMs: _now,
      );
      expect(
        staleWrite.invalidRecords,
        contains('reconnect:ent_reconnect_stale_write'),
      );

      final healthy = Sprint116OfflineCacheCertification().certify(
        entries: <Sprint116CacheEntry>[
          _reconnectEntry(entryId: 'ent_reconnect_ok'),
        ],
        clears: _healthyClears(),
        asOfEpochMs: _now,
      );
      expect(healthy.invalidRecords, isEmpty);
    });

    test('a reconnect refresh must not discard pending local edits', () {
      // The unsafe reconnect: the remote comes back and overwrites the edit
      // the user made while the network was down.
      final dropped = Sprint116OfflineCacheCertification().certify(
        entries: <Sprint116CacheEntry>[
          _reconnectEntry(
            entryId: 'ent_reconnect_drops_edit',
            pendingLocalEdits: 1,
            pendingLocalEditsPreserved: false,
          ),
        ],
        clears: _healthyClears(),
        asOfEpochMs: _now,
      );
      expect(dropped.state, Sprint116OfflineCacheStatus.fail);
      expect(
        dropped.invalidRecords,
        contains('reconnect:ent_reconnect_drops_edit'),
      );

      // Claiming the edit was preserved without having any is equally false.
      final unfounded = Sprint116OfflineCacheCertification().certify(
        entries: <Sprint116CacheEntry>[
          _reconnectEntry(
            entryId: 'ent_reconnect_unfounded_preserve',
            pendingLocalEdits: 0,
            pendingLocalEditsPreserved: true,
          ),
        ],
        clears: _healthyClears(),
        asOfEpochMs: _now,
      );
      expect(
        unfounded.invalidRecords,
        contains('reconnect:ent_reconnect_unfounded_preserve'),
      );
    });

    test('a cache clear must actually remove the bytes it claims to clear', () {
      // A partial clear leaves the same stale data readable.
      final partial = Sprint116OfflineCacheCertification().certify(
        entries: _healthyEntries(),
        clears: <Sprint116CacheClearRecord>[
          _clear(
            clearId: 'clr_partial',
            entryId: 'ent_session_blob_old',
            entriesRemainingAfterClear: 2,
          ),
        ],
        asOfEpochMs: _now,
      );
      expect(partial.state, Sprint116OfflineCacheStatus.fail);
      expect(partial.invalidRecords, contains('cache_clear:clr_partial'));

      // Cleared bytes that are still being served from an older write prove
      // the clear never took effect.
      final resurrected = Sprint116OfflineCacheCertification().certify(
        entries: _healthyEntries(),
        clears: <Sprint116CacheClearRecord>[
          _clear(
            clearId: 'clr_resurrected',
            entryId: 'ent_billing_snapshot',
            clearedAtEpochMs: 1700000099000,
          ),
        ],
        asOfEpochMs: _now,
      );
      expect(
        resurrected.invalidRecords,
        contains('cache_clear:clr_resurrected'),
      );

      final noTimestamp = Sprint116OfflineCacheCertification().certify(
        entries: _healthyEntries(),
        clears: <Sprint116CacheClearRecord>[
          _clear(
            clearId: 'clr_undated',
            entryId: 'ent_session_blob_old',
            clearedAtEpochMs: 0,
          ),
        ],
        asOfEpochMs: _now,
      );
      expect(noTimestamp.invalidRecords, contains('cache_clear:clr_undated'));

      final noTarget = Sprint116OfflineCacheCertification().certify(
        entries: _healthyEntries(),
        clears: <Sprint116CacheClearRecord>[
          _clear(clearId: 'clr_untargeted', entryId: '  '),
        ],
        asOfEpochMs: _now,
      );
      expect(noTarget.invalidRecords, contains('cache_clear:clr_untargeted'));
    });

    test('synthetic sources cannot be promoted to live evidence', () {
      final masquerading = Sprint116OfflineCacheCertification().certify(
        entries: <Sprint116CacheEntry>[
          _entry(
            entryId: 'ent_unsourced',
            providerId: 'provider_a',
            resourceId: 'chapter_1',
            cachedAtEpochMs: 1700000000000,
            asOfEpochMs: 1699999990000,
            freshnessLabel: 'fresh',
            source: 'live',
          ),
        ],
        clears: _healthyClears(),
        asOfEpochMs: _now,
      );
      expect(
        masquerading.invalidRecords,
        contains('no_mock_values:ent_unsourced'),
      );

      final invented = Sprint116OfflineCacheCertification().certify(
        entries: <Sprint116CacheEntry>[
          _entry(
            entryId: 'ent_invented_source',
            providerId: 'provider_a',
            resourceId: 'chapter_1',
            cachedAtEpochMs: 1700000000000,
            asOfEpochMs: 1699999990000,
            freshnessLabel: 'fresh',
            source: 'best_effort',
          ),
        ],
        clears: _healthyClears(),
        asOfEpochMs: _now,
      );
      expect(
        invented.invalidRecords,
        contains('no_mock_values:ent_invented_source'),
      );

      final attested = Sprint116OfflineCacheCertification().certify(
        entries: <Sprint116CacheEntry>[
          _entry(
            entryId: 'ent_attested',
            providerId: 'provider_a',
            resourceId: 'chapter_1',
            cachedAtEpochMs: 1700000000000,
            asOfEpochMs: 1699999990000,
            freshnessLabel: 'fresh',
            source: 'live',
            evidenceRef: 'docs/evidence/sprint-116-44-live-offline-trace.log',
          ),
        ],
        clears: _healthyClears(),
        asOfEpochMs: _now,
      );
      expect(attested.invalidRecords, isEmpty);
    });

    test('coverage gaps are reported per area when coverage is required', () {
      final noReconnect = Sprint116OfflineCacheCertification().certify(
        entries: <Sprint116CacheEntry>[_entry(entryId: 'ent_solo_fresh')],
        clears: _healthyClears(),
        asOfEpochMs: _now,
        requireCoverage: true,
      );
      expect(noReconnect.state, Sprint116OfflineCacheStatus.fail);
      for (final area in <String>[
        'stale_state',
        'remote_disable',
        'local_actions',
        'reconnect',
      ]) {
        expect(noReconnect.invalidRecords, contains('area_coverage:$area'));
      }
      expect(noReconnect.coveredAreas, contains('freshness_label'));
    });

    test(
      'the shipped manifest certifies and the report is JSON serialisable',
      () {
        final certification = Sprint116OfflineCacheCertification();
        final fromManifest = certification.certify(requireCoverage: true);
        expect(fromManifest.state, Sprint116OfflineCacheStatus.pass);
        expect(fromManifest.invalidRecords, isEmpty);

        final report = certification.certify(
          entries: _healthyEntries(),
          clears: _healthyClears(),
          asOfEpochMs: _now,
          requireCoverage: true,
        );
        final encoded = jsonEncode(report.toJson());
        final decoded = jsonDecode(encoded) as Map<String, dynamic>;
        expect(decoded['state'], 'pass');
        expect(
          (decoded['covered_areas'] as List<dynamic>).toList(),
          containsAll(Sprint116OfflineCacheContract.requiredAreas),
        );
        expect(decoded['live_provider_verification'], isFalse);
        expect(decoded['external_gates'], 'DEFERRED-EXTERNAL');
      },
    );
  });
}

/// The reference instant every fixture in this suite is measured against.
const int _now = 1700000100000;

Sprint116CacheEntry _entry({
  required String entryId,
  String providerId = 'provider_a',
  String resourceId = 'chapter_1',
  int cachedAtEpochMs = 1700000000000,
  int asOfEpochMs = 1699999990000,
  String freshnessLabel = 'fresh',
  int? cachedAtEpochMsOverride,
  int freshTtlSeconds = 3600,
  bool valueAvailable = true,
  bool offline = false,
  bool remoteActionEnabled = true,
  bool localActionEnabled = true,
  List<String> localActions = const <String>['open_project_tree'],
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  final cachedAt = cachedAtEpochMsOverride ?? cachedAtEpochMs;
  return Sprint116CacheEntry(
    entryId: entryId,
    providerId: providerId,
    resourceId: resourceId,
    cachedAtEpochMs: cachedAt,
    asOfEpochMs: asOfEpochMs,
    freshTtlSeconds: freshTtlSeconds,
    freshnessLabel: freshnessLabel,
    valueAvailable: valueAvailable,
    offline: offline,
    remoteActionEnabled: remoteActionEnabled,
    localActionEnabled: localActionEnabled,
    localActions: localActions,
    reconnectAttempted: false,
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116CacheEntry _reconnectEntry({
  required String entryId,
  bool reconnectRefreshed = true,
  int reconnectDetectedEpochMs = 1699999500000,
  int reconnectRefreshEpochMs = 1700000050000,
  int cachedAtEpochMs = 1700000050000,
  int asOfEpochMs = 1700000045000,
  String? freshnessLabelOverride,
  int pendingLocalEdits = 0,
  bool pendingLocalEditsPreserved = false,
}) {
  return Sprint116CacheEntry(
    entryId: entryId,
    providerId: 'provider_a',
    resourceId: 'chapter_1',
    cachedAtEpochMs: cachedAtEpochMs,
    asOfEpochMs: asOfEpochMs,
    freshTtlSeconds: 3600,
    freshnessLabel: freshnessLabelOverride ?? 'fresh',
    valueAvailable: true,
    offline: false,
    remoteActionEnabled: true,
    localActionEnabled: true,
    localActions: const <String>['edit_chapter', 'save_draft'],
    reconnectAttempted: true,
    reconnectDetectedEpochMs: reconnectDetectedEpochMs,
    reconnectRefreshed: reconnectRefreshed,
    reconnectRefreshEpochMs: reconnectRefreshEpochMs,
    pendingLocalEdits: pendingLocalEdits,
    pendingLocalEditsPreserved: pendingLocalEditsPreserved,
    source: 'synthetic_local',
  );
}

Sprint116CacheClearRecord _clear({
  required String clearId,
  required String entryId,
  int clearedAtEpochMs = 1700000090000,
  int entriesRemainingAfterClear = 0,
}) {
  return Sprint116CacheClearRecord(
    clearId: clearId,
    entryId: entryId,
    clearedAtEpochMs: clearedAtEpochMs,
    entriesRemainingAfterClear: entriesRemainingAfterClear,
    source: 'synthetic_local',
  );
}

/// A full offline and reconnect story that every area of 116.44 is drawn from.
List<Sprint116CacheEntry> _healthyEntries() => <Sprint116CacheEntry>[
  _entry(
    entryId: 'ent_project_tree',
    providerId: 'provider_a',
    resourceId: 'project_tree',
    cachedAtEpochMs: 1700000000000,
    asOfEpochMs: 1699999990000,
    freshnessLabel: 'fresh',
    localActions: const <String>['open_project_tree'],
  ),
  _reconnectEntry(entryId: 'ent_chapter_draft'),
  _entry(
    entryId: 'ent_billing_snapshot',
    providerId: 'provider_b',
    resourceId: 'billing_snapshot',
    cachedAtEpochMs: 1699990000000,
    asOfEpochMs: 1699989990000,
    freshnessLabel: 'stale',
    offline: true,
    remoteActionEnabled: false,
    localActions: const <String>['view_history'],
  ),
  _entry(
    entryId: 'ent_avatar_metadata',
    providerId: 'provider_a',
    resourceId: 'avatar_metadata',
    cachedAtEpochMs: 1700000000000,
    asOfEpochMs: 1699999990000,
    freshnessLabel: 'unavailable',
    valueAvailable: false,
    offline: true,
    remoteActionEnabled: false,
    localActions: const <String>['view_cached_avatar'],
  ),
];

List<Sprint116CacheClearRecord> _healthyClears() => <Sprint116CacheClearRecord>[
  _clear(clearId: 'clr_orphan_sessions', entryId: 'ent_session_blob_old'),
  _clear(
    clearId: 'clr_stale_index',
    entryId: 'ent_partial_index',
    clearedAtEpochMs: 1700000095000,
  ),
];
