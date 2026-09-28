import 'dart:convert';
import 'dart:io';

enum Sprint116OfflineCacheStatus { pass, fail, blocked }

/// One cached piece of provider metadata, plus the behaviour that was actually
/// available around it when the cache was written.
///
/// [cachedAtEpochMs] is when the cache bytes were written and [asOfEpochMs] is
/// the newest instant those bytes could describe. Freshness is a function of
/// the gap between the two, never of a hand-picked label, so a label that
/// disagrees with the timestamps is a defect rather than a preference.
class Sprint116CacheEntry {
  const Sprint116CacheEntry({
    required this.entryId,
    required this.providerId,
    required this.resourceId,
    required this.cachedAtEpochMs,
    required this.asOfEpochMs,
    required this.freshTtlSeconds,
    required this.freshnessLabel,
    required this.valueAvailable,
    required this.offline,
    required this.remoteActionEnabled,
    required this.localActionEnabled,
    required this.localActions,
    required this.reconnectAttempted,
    required this.source,
    this.reconnectDetectedEpochMs,
    this.reconnectRefreshed,
    this.reconnectRefreshEpochMs,
    this.pendingLocalEdits = 0,
    this.pendingLocalEditsPreserved = false,
    this.evidenceRef,
  });

  final String entryId;
  final String providerId;
  final String resourceId;

  /// When the cache entry was written.
  final int cachedAtEpochMs;

  /// The newest instant the cached bytes can describe.
  final int asOfEpochMs;

  /// How long a cached value stays `fresh`, in seconds.
  final int freshTtlSeconds;

  final String freshnessLabel;

  /// Whether a real value exists. A failed fetch has no value to age, so it is
  /// `unavailable` rather than fresh and never a zero-valued substitute.
  final bool valueAvailable;

  final bool offline;
  final bool remoteActionEnabled;
  final bool localActionEnabled;
  final List<String> localActions;

  final bool reconnectAttempted;
  final int? reconnectDetectedEpochMs;
  final bool? reconnectRefreshed;
  final int? reconnectRefreshEpochMs;

  final int pendingLocalEdits;
  final bool pendingLocalEditsPreserved;

  final String source;
  final String? evidenceRef;
}

/// One cache eviction, so "clear cache" is a claim with a subject and a
/// timestamp rather than an unevidenced button state.
class Sprint116CacheClearRecord {
  const Sprint116CacheClearRecord({
    required this.clearId,
    required this.entryId,
    required this.clearedAtEpochMs,
    required this.entriesRemainingAfterClear,
    required this.source,
  });

  final String clearId;

  /// The entry this clear was supposed to remove.
  final String entryId;

  final int clearedAtEpochMs;

  /// How many entries of the target survived the clear. A partial clear leaves
  /// the same stale bytes readable.
  final int entriesRemainingAfterClear;

  final String source;
}

class Sprint116OfflineCacheReport {
  Sprint116OfflineCacheReport({
    required this.state,
    required this.invalidRecords,
    required this.coveredAreas,
    required this.staleEntryIds,
    required this.unavailableEntryIds,
    required this.offlineEntryIds,
    required this.reconnectedEntryIds,
  });

  final Sprint116OfflineCacheStatus state;
  final List<String> invalidRecords;
  final List<String> coveredAreas;

  /// Entries honestly carrying the `stale` label.
  final List<String> staleEntryIds;

  /// Entries whose value is genuinely missing.
  final List<String> unavailableEntryIds;

  /// Entries served while offline.
  final List<String> offlineEntryIds;

  /// Entries that completed a reconnect refresh.
  final List<String> reconnectedEntryIds;

  String get externalGates => Sprint116OfflineCacheContract.externalGates;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'canonical_step': Sprint116OfflineCacheContract.canonicalStep,
      'state': state.name,
      'invalid_records': invalidRecords,
      'covered_areas': coveredAreas,
      'stale_entry_ids': staleEntryIds,
      'unavailable_entry_ids': unavailableEntryIds,
      'offline_entry_ids': offlineEntryIds,
      'reconnected_entry_ids': reconnectedEntryIds,
      'live_provider_verification': false,
      'external_gates': externalGates,
    };
  }
}

abstract final class Sprint116OfflineCacheContract {
  static const String canonicalStep = '116.44';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_offline_cached_metadata_certification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The six acceptance areas of step 116.44.
  static const List<String> requiredAreas = <String>[
    'freshness_label',
    'stale_state',
    'remote_disable',
    'local_actions',
    'reconnect',
    'cache_clear',
  ];

  static const List<String> freshnessLabels = <String>[
    'fresh',
    'stale',
    'unavailable',
  ];

  /// The actions that genuinely work with no network. Anything that reaches a
  /// provider is not a local action, however convenient it looks.
  static const List<String> localActions = <String>[
    'open_project_tree',
    'edit_chapter',
    'save_draft',
    'view_history',
    'view_cached_avatar',
    'export_local',
    'rename_local',
  ];

  static const List<String> supportedSources = <String>[
    'synthetic_local',
    'live',
  ];

  /// Freshness at exactly the TTL boundary is still fresh; past it is stale.
  static String expectedLabel({
    required bool valueAvailable,
    required int ageSeconds,
    required int freshTtlSeconds,
  }) {
    if (!valueAvailable) return 'unavailable';
    if (freshTtlSeconds <= 0) return 'stale';
    return ageSeconds <= freshTtlSeconds ? 'fresh' : 'stale';
  }
}

class Sprint116OfflineCacheCertification {
  /// Certifies cached-metadata behaviour against the six-area offline
  /// contract.
  ///
  /// Manifest fixtures are consulted only when [entries] is omitted, so an
  /// explicit entry set can never borrow fixture data to pass.
  Sprint116OfflineCacheReport certify({
    List<Sprint116CacheEntry>? entries,
    List<Sprint116CacheClearRecord>? clears,
    int? asOfEpochMs,
    bool requireCoverage = false,
  }) {
    // Manifest data is borrowed only when the caller supplies nothing, so an
    // explicit record set can never pass on fixture values it did not send.
    final usedManifestEntries = entries == null;
    final manifest = _readManifest();
    final effectiveEntries = entries ?? _readManifestEntries(manifest);
    final effectiveClears = clears ?? _readManifestClears(manifest);
    final effectiveAsOf =
        asOfEpochMs ?? (usedManifestEntries ? _manifestAsOf(manifest) : null);

    if (effectiveEntries.isEmpty) {
      return _blocked('entries');
    }
    if (effectiveClears.isEmpty) {
      return _blocked('clears');
    }
    // Age is measured against a reference instant; without one every record
    // would pass on an unmeasured assumption.
    if (effectiveAsOf == null || effectiveAsOf <= 0) {
      return _blocked('as_of_epoch_ms');
    }

    final invalid = <String>[];
    final covered = <String>[];
    final staleIds = <String>[];
    final unavailableIds = <String>[];
    final offlineIds = <String>[];
    final reconnectedIds = <String>[];

    for (var index = 0; index < effectiveEntries.length; index++) {
      final entry = effectiveEntries[index];
      final id = entry.entryId.trim();

      if (id.isEmpty) {
        // Without an identity the record cannot be attributed, so it is
        // rejected on identity alone rather than by guessing a key.
        invalid.add('record_id:$index');
        continue;
      }

      // Areas this entry fails, so one defect yields one marker per area
      // instead of one marker per broken field.
      final failed = <String>{};
      final evidence = <String>{};

      // Identity is attribution, not freshness, so each missing half gets its
      // own marker instead of collapsing into one ambiguous one.
      if (entry.providerId.trim().isEmpty) {
        failed.add('provider_id');
      }
      if (entry.resourceId.trim().isEmpty) {
        failed.add('resource_id');
      }

      _certifyFreshness(entry, effectiveAsOf, failed, evidence);

      // Only honestly-labelled records are reported, so a UI bound to these
      // lists can never surface a stale value as fresh.
      if (entry.freshnessLabel.trim() == 'stale') staleIds.add(id);
      if (!entry.valueAvailable) unavailableIds.add(id);

      if (entry.offline) {
        offlineIds.add(id);
        _certifyOffline(entry, failed, evidence);
      }

      // A cache whose network has not returned yet is not a defect. What is a
      // defect is claiming a refresh that never reached the cache.
      if (entry.reconnectAttempted &&
          _certifyReconnect(entry, failed, evidence)) {
        reconnectedIds.add(id);
      }

      final source = entry.source.trim();
      final evidenceRef = entry.evidenceRef?.trim();
      if (!Sprint116OfflineCacheContract.supportedSources.contains(source) ||
          (source == 'live' && (evidenceRef == null || evidenceRef.isEmpty))) {
        failed.add('no_mock_values');
      }

      for (final area in failed) {
        invalid.add('$area:$id');
      }
      for (final area in evidence) {
        if (!covered.contains(area)) covered.add(area);
      }
    }

    for (final clear in effectiveClears) {
      final clearId = clear.clearId.trim();
      if (clearId.isEmpty ||
          clear.entryId.trim().isEmpty ||
          clear.clearedAtEpochMs <= 0 ||
          clear.clearedAtEpochMs > effectiveAsOf ||
          clear.entriesRemainingAfterClear != 0 ||
          !Sprint116OfflineCacheContract.supportedSources.contains(
            clear.source.trim(),
          )) {
        invalid.add('cache_clear:$clearId');
        continue;
      }

      // Bytes that are still being served from a write older than the clear
      // prove the eviction never took effect.
      for (final entry in effectiveEntries) {
        if (entry.entryId.trim() != clear.entryId.trim()) continue;
        if (entry.cachedAtEpochMs < clear.clearedAtEpochMs) {
          invalid.add('cache_clear:$clearId');
          break;
        }
      }
      if (invalid.contains('cache_clear:$clearId')) continue;
      covered.add('cache_clear');
    }

    if (requireCoverage) {
      for (final area in Sprint116OfflineCacheContract.requiredAreas) {
        if (!covered.contains(area)) {
          invalid.add('area_coverage:$area');
        }
      }
    }

    return Sprint116OfflineCacheReport(
      state: invalid.isEmpty
          ? Sprint116OfflineCacheStatus.pass
          : Sprint116OfflineCacheStatus.fail,
      invalidRecords: invalid,
      coveredAreas: covered,
      staleEntryIds: staleIds,
      unavailableEntryIds: unavailableIds,
      offlineEntryIds: offlineIds,
      reconnectedEntryIds: reconnectedIds,
    );
  }

  void _certifyFreshness(
    Sprint116CacheEntry entry,
    int asOfEpochMs,
    Set<String> failed,
    Set<String> evidence,
  ) {
    final label = entry.freshnessLabel.trim();
    if (!Sprint116OfflineCacheContract.freshnessLabels.contains(label)) {
      failed.add('freshness_label');
      return;
    }

    if (entry.cachedAtEpochMs <= 0 ||
        entry.asOfEpochMs <= 0 ||
        entry.freshTtlSeconds <= 0 ||
        // Cache data cannot be newer than the source it was fetched from.
        entry.asOfEpochMs > entry.cachedAtEpochMs ||
        // ...nor future dated relative to the reference instant.
        entry.cachedAtEpochMs > asOfEpochMs) {
      failed.add('freshness_label');
      return;
    }

    // A missing value is unavailable; presenting it as fresh is the one
    // failure mode that turns a failed fetch into a confident wrong answer.
    if (!entry.valueAvailable) {
      if (label != 'unavailable') {
        failed.add('freshness_label');
        return;
      }
      evidence.add('freshness_label');
      return;
    }

    final ageSeconds = (asOfEpochMs - entry.cachedAtEpochMs) ~/ 1000;
    final expected = Sprint116OfflineCacheContract.expectedLabel(
      valueAvailable: true,
      ageSeconds: ageSeconds,
      freshTtlSeconds: entry.freshTtlSeconds,
    );

    if (label != expected) {
      failed.add('freshness_label');
      return;
    }

    evidence.add('freshness_label');
    if (label == 'stale') {
      evidence.add('stale_state');
    }
  }

  void _certifyOffline(
    Sprint116CacheEntry entry,
    Set<String> failed,
    Set<String> evidence,
  ) {
    // Queueing a remote write that cannot complete is how a local-first app
    // silently loses the user's edit.
    if (entry.remoteActionEnabled) {
      failed.add('remote_disable');
    } else {
      evidence.add('remote_disable');
    }

    if (!entry.localActionEnabled || entry.localActions.isEmpty) {
      failed.add('local_actions');
      return;
    }
    for (final action in entry.localActions) {
      final trimmed = action.trim();
      if (!Sprint116OfflineCacheContract.localActions.contains(trimmed)) {
        // A remote call listed as a local action is the same defect wearing a
        // different name.
        failed.add('local_actions');
        return;
      }
    }
    evidence.add('local_actions');
  }

  /// Returns true when the reconnect genuinely refreshed the cache and kept
  /// pending local work; the caller uses that to build the reconnected list.
  bool _certifyReconnect(
    Sprint116CacheEntry entry,
    Set<String> failed,
    Set<String> evidence,
  ) {
    final detected = entry.reconnectDetectedEpochMs;
    final refreshed = entry.reconnectRefreshed;
    final refreshAt = entry.reconnectRefreshEpochMs;

    if (detected == null ||
        detected <= 0 ||
        refreshed != true ||
        refreshAt == null ||
        refreshAt <= 0) {
      // Detecting the outage and then serving the same bytes is not a refresh.
      failed.add('reconnect');
      return false;
    }

    // A refresh timestamped before detection is a pre-outage read wearing a
    // refresh label.
    if (refreshAt < detected) {
      failed.add('reconnect');
      return false;
    }

    // The cache write may not predate the refresh it claims to come from.
    if (entry.cachedAtEpochMs < refreshAt) {
      failed.add('reconnect');
      return false;
    }

    if (entry.pendingLocalEdits > 0 && !entry.pendingLocalEditsPreserved) {
      // The unsafe reconnect: remote returns and overwrites the edit made
      // while the network was down.
      failed.add('reconnect');
      return false;
    }

    // Claiming an edit was preserved without having any is equally false.
    if (entry.pendingLocalEdits == 0 && entry.pendingLocalEditsPreserved) {
      failed.add('reconnect');
      return false;
    }

    evidence.add('reconnect');
    return true;
  }

  Sprint116OfflineCacheReport _blocked(String reason) {
    return Sprint116OfflineCacheReport(
      state: Sprint116OfflineCacheStatus.blocked,
      invalidRecords: <String>[reason],
      coveredAreas: const <String>[],
      staleEntryIds: const <String>[],
      unavailableEntryIds: const <String>[],
      offlineEntryIds: const <String>[],
      reconnectedEntryIds: const <String>[],
    );
  }

  Map<String, dynamic>? _readManifest() {
    final file = File(Sprint116OfflineCacheContract.manifestPath);
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  int? _manifestAsOf(Map<String, dynamic>? manifest) {
    final raw = manifest?['as_of_epoch_ms'];
    return raw is num ? raw.toInt() : null;
  }

  List<Sprint116CacheEntry> _readManifestEntries(
    Map<String, dynamic>? manifest,
  ) {
    if (manifest == null) return <Sprint116CacheEntry>[];
    final raw = manifest['entries'];
    if (raw is! List) return <Sprint116CacheEntry>[];
    return raw
        .whereType<Map>()
        .map((item) => _entryFromManifest(item))
        .toList(growable: false);
  }

  List<Sprint116CacheClearRecord> _readManifestClears(
    Map<String, dynamic>? manifest,
  ) {
    if (manifest == null) return <Sprint116CacheClearRecord>[];
    final raw = manifest['cache_clears'];
    if (raw is! List) return <Sprint116CacheClearRecord>[];
    return raw
        .whereType<Map>()
        .map(
          (item) => Sprint116CacheClearRecord(
            clearId: item['clear_id']?.toString() ?? '',
            entryId: item['entry_id']?.toString() ?? '',
            clearedAtEpochMs:
                (item['cleared_at_epoch_ms'] as num?)?.toInt() ?? 0,
            entriesRemainingAfterClear:
                (item['entries_remaining_after_clear'] as num?)?.toInt() ?? -1,
            source: item['source']?.toString() ?? '',
          ),
        )
        .toList(growable: false);
  }

  Sprint116CacheEntry _entryFromManifest(Map<Object?, Object?> item) {
    return Sprint116CacheEntry(
      entryId: item['entry_id']?.toString() ?? '',
      providerId: item['provider_id']?.toString() ?? '',
      resourceId: item['resource_id']?.toString() ?? '',
      cachedAtEpochMs: (item['cached_at_epoch_ms'] as num?)?.toInt() ?? 0,
      asOfEpochMs: (item['as_of_epoch_ms'] as num?)?.toInt() ?? 0,
      freshTtlSeconds: (item['fresh_ttl_seconds'] as num?)?.toInt() ?? 0,
      freshnessLabel: item['freshness_label']?.toString() ?? '',
      valueAvailable: item['value_available'] == true,
      offline: item['offline'] == true,
      remoteActionEnabled: item['remote_action_enabled'] == true,
      localActionEnabled: item['local_action_enabled'] == true,
      localActions: _stringList(item['local_actions']),
      reconnectAttempted: item['reconnect_attempted'] == true,
      reconnectDetectedEpochMs: (item['reconnect_detected_epoch_ms'] as num?)
          ?.toInt(),
      reconnectRefreshed: item['reconnect_refreshed'] == null
          ? null
          : item['reconnect_refreshed'] == true,
      reconnectRefreshEpochMs: (item['reconnect_refresh_epoch_ms'] as num?)
          ?.toInt(),
      pendingLocalEdits: (item['pending_local_edits'] as num?)?.toInt() ?? 0,
      pendingLocalEditsPreserved: item['pending_local_edits_preserved'] == true,
      source: item['source']?.toString() ?? '',
      evidenceRef: item['evidence_ref']?.toString(),
    );
  }

  List<String> _stringList(Object? raw) {
    if (raw is! List) return const <String>[];
    return raw.map((item) => item?.toString() ?? '').toList(growable: false);
  }
}
