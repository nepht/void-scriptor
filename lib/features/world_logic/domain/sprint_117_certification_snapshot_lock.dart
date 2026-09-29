import 'dart:convert';
import 'dart:io';

import '../../account/domain/account_center_provider_icon_registry.dart';

/// Canonical step 117.4 — Certification Snapshot Lock.
///
/// Objective (external canonical JSON): freeze connector versions, statuses,
/// limitations, icons, API versions, and recertification dates for the beta.
///
/// The lock is the freeze of what the repository actually records — not a claim
/// about live provider behaviour. Every field is derived from a committed
/// manifest: the 117.1 entry gate supplies each provider's certification
/// visibility, the 116.2 certification policy supplies the review date and the
/// status vocabulary, 116.4 supplies the recorded API version, 115.9 supplies
/// the connector contract version, 115.8 supplies the shipped icon version, and
/// 117.3 supplies the upstream consent verdict this lock does not inherit.
///
/// Because a lock is a promise about recertification, the review window is
/// evaluated at the instant the entry gate recorded, not at wall-clock time,
/// so the verdict is reproducible on every run.
enum Sprint117SnapshotState { pass, fail, blocked }

class Sprint117SnapshotRecord {
  const Sprint117SnapshotRecord({
    required this.providerId,
    required this.connectorVersion,
    required this.status,
    required this.limitations,
    required this.iconVersion,
    required this.apiVersion,
    required this.reviewDate,
  });

  final String providerId;
  final String connectorVersion;
  final String status;
  final List<String> limitations;
  final String iconVersion;
  final String apiVersion;
  final String reviewDate;

  Map<String, Object?> toJson() => <String, Object?>{
    'provider_id': providerId,
    'connector_version': connectorVersion,
    'status': status,
    'limitations': List<String>.from(limitations),
    'icon_version': iconVersion,
    'api_version': apiVersion,
    'review_date': reviewDate,
  };
}

class Sprint117SnapshotAnchor {
  const Sprint117SnapshotAnchor({
    required this.entryVerdict,
    required this.cohortVerdict,
    required this.asOfEpochMs,
    required this.entryVisibility,
    required this.recordedApiVersions,
    required this.recordedConnectorVersions,
    required this.iconVersions,
    required this.policyReviewDate,
    required this.certificationStatuses,
    required this.carriedOpenItems,
  });

  /// The 117.1 verdict the lock stands on.
  final String entryVerdict;

  /// The 117.3 verdict. The lock records it and never treats it as passed.
  final String cohortVerdict;

  /// The instant the certification chain was re-derived. The review window is
  /// measured here so a rerun never drifts with the clock.
  final int asOfEpochMs;

  /// Per-provider certification visibility recorded by 117.1.
  final Map<String, String> entryVisibility;

  /// API versions 116.4 actually recorded. Anything else is unsourced.
  final List<String> recordedApiVersions;

  /// Connector contract versions 115.9 actually records.
  final List<String> recordedConnectorVersions;

  /// Icon asset versions the shipped registry actually publishes.
  final Map<String, String> iconVersions;

  /// The recertification date 116.2 records.
  final String policyReviewDate;

  /// The status vocabulary 116.2 permits. A status outside it is a defect.
  final List<String> certificationStatuses;

  final List<String> carriedOpenItems;
}

class Sprint117SnapshotInput {
  const Sprint117SnapshotInput({this.records, this.anchor});

  final List<Sprint117SnapshotRecord>? records;
  final Sprint117SnapshotAnchor? anchor;
}

class Sprint117SnapshotReport {
  Sprint117SnapshotReport({
    required this.state,
    required this.verdict,
    required List<String> missingFields,
    required List<String> violations,
    required this.anchor,
    required List<Sprint117SnapshotRecord> records,
    required List<String> exposedSubset,
    required List<String> blockedSubset,
    required List<String> expiredProviderIds,
    required List<String> openItems,
    required List<String> limitations,
    required Map<String, int> fieldCoverage,
  }) : missingFields = List<String>.unmodifiable(missingFields),
       violations = List<String>.unmodifiable(violations),
       records = List<Sprint117SnapshotRecord>.unmodifiable(records),
       exposedSubset = List<String>.unmodifiable(exposedSubset),
       blockedSubset = List<String>.unmodifiable(blockedSubset),
       expiredProviderIds = List<String>.unmodifiable(expiredProviderIds),
       openItems = List<String>.unmodifiable(openItems),
       limitations = List<String>.unmodifiable(limitations),
       fieldCoverage = Map<String, int>.unmodifiable(fieldCoverage);

  final Sprint117SnapshotState state;
  final String verdict;
  final List<String> missingFields;
  final List<String> violations;
  final Sprint117SnapshotAnchor? anchor;
  final List<Sprint117SnapshotRecord> records;
  final List<String> exposedSubset;
  final List<String> blockedSubset;
  final List<String> expiredProviderIds;
  final List<String> openItems;
  final List<String> limitations;
  final Map<String, int> fieldCoverage;

  String get externalGates => Sprint117SnapshotContract.externalGates;

  int get lockedProviderCount => records.length;

  /// A freeze of local certification state is never a live beta run.
  bool get liveBetaExecuted => false;

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': Sprint117SnapshotContract.canonicalStep,
    'state': state.name,
    'verdict': verdict,
    'missing_fields': List<String>.from(missingFields),
    'violations': List<String>.from(violations),
    'anchor': anchor == null
        ? null
        : <String, Object?>{
            'entry_verdict': anchor!.entryVerdict,
            'cohort_verdict': anchor!.cohortVerdict,
            'as_of_epoch_ms': anchor!.asOfEpochMs,
            'entry_visibility': Map<String, String>.from(
              anchor!.entryVisibility,
            ),
            'recorded_api_versions': List<String>.from(
              anchor!.recordedApiVersions,
            ),
            'recorded_connector_versions': List<String>.from(
              anchor!.recordedConnectorVersions,
            ),
            'policy_review_date': anchor!.policyReviewDate,
            'certification_statuses': List<String>.from(
              anchor!.certificationStatuses,
            ),
          },
    'locked_provider_count': lockedProviderCount,
    'exposed_subset': List<String>.from(exposedSubset),
    'blocked_subset': List<String>.from(blockedSubset),
    'expired_provider_ids': List<String>.from(expiredProviderIds),
    'snapshot': <Map<String, Object?>>[
      for (final record in records) record.toJson(),
    ],
    'field_coverage': Map<String, int>.from(fieldCoverage),
    'required_fields': List<String>.from(
      Sprint117SnapshotContract.requiredFields,
    ),
    'source_manifests': List<String>.from(
      Sprint117SnapshotContract.sourceManifests,
    ),
    'external_gates': externalGates,
    'live_beta_executed': liveBetaExecuted,
    'open_items': List<String>.from(openItems),
    'limitations': List<String>.from(limitations),
  };
}

abstract final class Sprint117SnapshotContract {
  static const String canonicalStep = '117.4';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_117_certification_snapshot_lock.json';
  static const String entryManifestPath =
      'docs/planning/v1.3/sprint_117_beta_entry_gate.json';
  static const String policyManifestPath =
      'docs/planning/v1.2/sprint_116_certification_policy.json';
  static const String apiManifestPath =
      'docs/planning/v1.2/sprint_116_current_api_sdk_verification.json';
  static const String connectorManifestPath =
      'docs/planning/v1.2/sprint_115_provider_connector_manifest.json';
  static const String cohortManifestPath =
      'docs/planning/v1.3/sprint_117_beta_cohort_consent_verification.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The 117.1 verdict this lock stands on.
  static const String entryVerdict = 'BETA_ENTRY_LOCAL_READY';

  /// The 117.3 verdict that would let the lock inherit a verified cohort. The
  /// beta has no live participant, so the lock never reaches this verdict and
  /// always records the upstream failure instead of passing over it.
  static const String cohortVerifiedVerdict = 'COHORT_CONSENT_VERIFIED_LOCAL';

  /// The 117.3 verdict as it stands today.
  static const String cohortBlockedVerdict =
      'COHORT_CONSENT_VERIFICATION_FAILED';

  static const String passVerdict = 'CERTIFICATION_SNAPSHOT_LOCKED_LOCAL';
  static const String blockedVerdict =
      'CERTIFICATION_SNAPSHOT_BLOCKED_NO_LOCAL_EVIDENCE';
  static const String failVerdict = 'CERTIFICATION_SNAPSHOT_INCONSISTENT';

  /// The seven fields canonical step 117.4 names, in canonical order.
  static const List<String> requiredFields = <String>[
    'provider_id',
    'connector_version',
    'status',
    'limitations',
    'icon_version',
    'api_version',
    'review_date',
  ];

  static const List<String> sourceManifests = <String>[
    entryManifestPath,
    policyManifestPath,
    apiManifestPath,
    connectorManifestPath,
    cohortManifestPath,
  ];

  /// The status 116.2 requires an eligible provider to carry.
  static const String certifiedStatus = 'CERTIFIED';

  /// The status 116.2 allows an eligible provider to carry with restrictions.
  static const String limitedStatus = 'LIMITED';

  /// A provider in this status is hidden from the beta and may not be locked
  /// as certified or limited.
  static const String blockedStatus = 'BLOCKED';

  /// A recertification window that has elapsed must be declared, not hidden.
  static const String expiredStatus = 'EXPIRED';

  /// A placeholder the source itself records in place of a verified version.
  static const String unclaimedApiVersion = 'not-claimed';

  /// The asset version the icon registry publishes for an entry that ships the
  /// generic category fallback instead of a bundled provider mark.
  static const String genericIconVersion = 'generic-v1';

  /// Every locked row carries the same limitations, because the lock proves
  /// local certification state only and claims nothing about live behaviour.
  static const List<String> lockLimitations = <String>[
    'local_certification_chain_only',
    'not_live_provider_availability',
    'no_quota_cost_or_credential_claim',
  ];
}

class Sprint117SnapshotLoader {
  const Sprint117SnapshotLoader();

  Sprint117SnapshotInput load() =>
      Sprint117SnapshotInput(anchor: _loadAnchor(), records: _loadRecords());

  Sprint117SnapshotAnchor? _loadAnchor() {
    final entry = _readJsonObject(Sprint117SnapshotContract.entryManifestPath);
    final policy = _readJsonObject(
      Sprint117SnapshotContract.policyManifestPath,
    );
    final connector = _readJsonObject(
      Sprint117SnapshotContract.connectorManifestPath,
    );
    final cohort = _readJsonObject(
      Sprint117SnapshotContract.cohortManifestPath,
    );
    if (entry == null ||
        policy == null ||
        connector == null ||
        cohort == null) {
      return null;
    }

    final visibility = <String, String>{};
    final recorded = entry['visibility'];
    if (recorded is Map<String, dynamic>) {
      for (final entryKey in recorded.keys) {
        final value = recorded[entryKey];
        final providerId = _text(entryKey);
        if (providerId.isNotEmpty &&
            value is String &&
            value.trim().isNotEmpty) {
          visibility[providerId] = value.trim();
        }
      }
    }

    return Sprint117SnapshotAnchor(
      entryVerdict: _text(entry['verdict']),
      cohortVerdict: _text(cohort['verdict']),
      asOfEpochMs: entry['as_of_epoch_ms'] is int
          ? entry['as_of_epoch_ms']! as int
          : 0,
      entryVisibility: visibility,
      recordedApiVersions: _recordedApiVersions(),
      recordedConnectorVersions: _recordedConnectorVersions(connector),
      iconVersions: _recordedIconVersions(visibility.keys),
      policyReviewDate: _recordedReviewDate(policy),
      certificationStatuses: _stringList(policy['certification_statuses']),
      carriedOpenItems: _stringList(entry['open_items']),
    );
  }

  /// 116.4 records a single schema row whose API version is the explicit
  /// placeholder `not-claimed`. That placeholder is the only version the
  /// repository can honestly attest, so it is the whole vocabulary.
  List<String> _recordedApiVersions() {
    final result = <String>{};
    for (final row
        in _readList(Sprint117SnapshotContract.apiManifestPath, 'records') ??
            const <dynamic>[]) {
      if (row is! Map<String, dynamic>) continue;
      final version = _text(row['api_version']);
      if (version.isNotEmpty) result.add(version);
    }
    return result.toList(growable: false);
  }

  /// 115.9 records one shipped connector contract version for the whole
  /// standard manifest. It is a metadata contract, not a deployed release.
  List<String> _recordedConnectorVersions(Map<String, dynamic> connector) {
    final result = <String>{};
    final standard = connector['standard_manifest'];
    if (standard is Map<String, dynamic>) {
      final version = _text(standard['connector_version']);
      if (version.isNotEmpty) result.add(version);
    }
    final required = connector['required_fields'];
    if (required is List<dynamic> && required.contains('connector_version')) {
      // The field is part of the contract; the shipped value stays the only
      // version the manifest asserts.
    }
    return result.toList(growable: false);
  }

  /// The icon version the registry actually publishes for each provider. A
  /// provider with a bundled mark ships `bundled-v1`; one without ships the
  /// generic category fallback version. Reading the registry instead of
  /// assuming a single version is what keeps a locked icon version honest.
  Map<String, String> _recordedIconVersions(Iterable<String> providerIds) {
    final registry = ProviderIconRegistry.standard;
    final result = <String, String>{};
    for (final providerId in providerIds) {
      final entry = registry.get(providerId);
      if (entry == null) continue;
      result[providerId] = entry.usesGenericFallback
          ? Sprint117SnapshotContract.genericIconVersion
          : entry.assetVersion;
    }
    return result;
  }

  /// 116.2 records the recertification instant on its single evidence row. The
  /// lock pins that date for every provider rather than inventing per-provider
  /// review windows it has no evidence for.
  String _recordedReviewDate(Map<String, dynamic> policy) {
    final records = policy['evidence_records'];
    if (records is List<dynamic>) {
      for (final row in records) {
        if (row is! Map<String, dynamic>) continue;
        final date = _text(row['expires_or_recheck_at']);
        if (date.isNotEmpty) return date;
      }
    }
    return '';
  }

  /// One locked row per provider the entry gate recorded. The connector and
  /// API versions come from the manifests, the status and icon version from
  /// the sources above, and the review date from the certification policy.
  List<Sprint117SnapshotRecord>? _loadRecords() {
    final anchor = _loadAnchor();
    if (anchor == null) return null;

    final apiVersion = anchor.recordedApiVersions.isEmpty
        ? ''
        : anchor.recordedApiVersions.first;
    final connectorVersion = anchor.recordedConnectorVersions.isEmpty
        ? ''
        : anchor.recordedConnectorVersions.first;

    final records = <Sprint117SnapshotRecord>[];
    for (final providerId in anchor.entryVisibility.keys) {
      final visibility = anchor.entryVisibility[providerId]!.trim();
      records.add(
        Sprint117SnapshotRecord(
          providerId: providerId,
          connectorVersion: connectorVersion,
          status: _lockStatus(visibility),
          limitations: Sprint117SnapshotContract.lockLimitations,
          iconVersion: anchor.iconVersions[providerId] ?? '',
          apiVersion: apiVersion,
          reviewDate: anchor.policyReviewDate,
        ),
      );
    }
    return records;
  }

  /// The entry gate records lowercase visibility; the certification policy
  /// records uppercase statuses. A blocked provider keeps its blocked status so
  /// the lock can never present it as beta-eligible.
  static String _lockStatus(String visibility) =>
      switch (visibility.trim().toLowerCase()) {
        'certified' => Sprint117SnapshotContract.certifiedStatus,
        'limited' => Sprint117SnapshotContract.limitedStatus,
        'blocked' => Sprint117SnapshotContract.blockedStatus,
        'expired' => Sprint117SnapshotContract.expiredStatus,
        _ => '',
      };

  static Map<String, dynamic>? _readJsonObject(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  static List<dynamic>? _readList(String path, String key) {
    final decoded = _readJsonObject(path);
    if (decoded == null) return null;
    final value = decoded[key];
    return value is List<dynamic> ? value : null;
  }

  static String _text(Object? value) => value is String ? value.trim() : '';

  static List<String> _stringList(Object? value) {
    if (value is! List<dynamic>) return const <String>[];
    return <String>[
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }
}

class Sprint117SnapshotGate {
  const Sprint117SnapshotGate();

  Sprint117SnapshotReport evaluate() =>
      evaluateWith(const Sprint117SnapshotLoader().load());

  Sprint117SnapshotReport evaluateWith(Sprint117SnapshotInput input) {
    final missing = <String>{};
    final violations = <String>[];

    // --- anchor ------------------------------------------------------------
    final anchor = input.anchor;
    if (anchor == null) {
      missing.add('entry_anchor');
    } else {
      if (anchor.entryVerdict != Sprint117SnapshotContract.entryVerdict) {
        missing.add('entry_anchor');
      }
      if (anchor.cohortVerdict.trim().isEmpty) {
        missing.add('cohort_anchor');
      }
      if (anchor.asOfEpochMs <= 0) {
        missing.add('entry_as_of');
      }
      if (anchor.policyReviewDate.trim().isEmpty) {
        missing.add('policy_review_date');
      }
      if (anchor.certificationStatuses.isEmpty) {
        missing.add('certification_status_vocabulary');
      }
      if (anchor.entryVisibility.isEmpty) {
        missing.add('entry_visibility');
      }
      if (anchor.recordedApiVersions.isEmpty) {
        missing.add('recorded_api_version');
      }
      if (anchor.recordedConnectorVersions.isEmpty) {
        missing.add('recorded_connector_version');
      }
      if (anchor.iconVersions.isEmpty) {
        missing.add('recorded_icon_version');
      }
    }

    // --- records -----------------------------------------------------------
    final records = input.records;
    final lockedIds = <String>{};
    final expired = <String>[];
    if (records == null || records.isEmpty) {
      missing.add('snapshot_records');
    } else {
      for (final record in records) {
        final providerId = record.providerId.trim();
        if (providerId.isEmpty) {
          violations.add('provider_id_blank');
          continue;
        }
        if (!lockedIds.add(providerId)) {
          violations.add('snapshot_duplicate:$providerId');
          continue;
        }

        // status: must exist in the policy vocabulary and must not contradict
        // the visibility the entry gate recorded.
        final status = record.status.trim();
        if (status.isEmpty) {
          violations.add('status_blank:$providerId');
        } else if (anchor != null &&
            anchor.certificationStatuses.isNotEmpty &&
            !anchor.certificationStatuses.contains(status)) {
          violations.add('status_unknown:$providerId:$status');
        }
        if (status == Sprint117SnapshotContract.expiredStatus) {
          expired.add(providerId);
        }

        // connector version: must be a version a committed manifest records.
        final connectorVersion = record.connectorVersion.trim();
        if (connectorVersion.isEmpty) {
          violations.add('connector_version_blank:$providerId');
        } else if (anchor != null &&
            anchor.recordedConnectorVersions.isNotEmpty &&
            !anchor.recordedConnectorVersions.contains(connectorVersion)) {
          violations.add(
            'connector_version_unsourced:$providerId:$connectorVersion',
          );
        }

        // limitations: the 116.2 rule requires at least one real limitation on
        // every certified or limited record, and a blank string is not one.
        if (record.limitations
            .where((entry) => entry.trim().isNotEmpty)
            .isEmpty) {
          violations.add('limitations_blank:$providerId');
        }

        // icon version: must be the version the shipped registry publishes.
        final iconVersion = record.iconVersion.trim();
        if (iconVersion.isEmpty) {
          violations.add('icon_version_blank:$providerId');
        } else if (anchor != null && anchor.iconVersions.isNotEmpty) {
          final recorded = anchor.iconVersions[providerId];
          if (recorded == null) {
            violations.add('icon_provider_unknown:$providerId');
          } else if (recorded != iconVersion) {
            violations.add(
              'icon_version_drift:$providerId:$iconVersion:$recorded',
            );
          }
        }

        // api version: must be a version 116.4 recorded. A concrete version
        // nobody verified is a fabricated certification, not a lock.
        final apiVersion = record.apiVersion.trim();
        if (apiVersion.isEmpty) {
          violations.add('api_version_blank:$providerId');
        } else if (anchor != null &&
            anchor.recordedApiVersions.isNotEmpty &&
            !anchor.recordedApiVersions.contains(apiVersion)) {
          violations.add('api_version_unsourced:$providerId:$apiVersion');
        }

        // review date: a lock is a promise about recertification, so a date
        // nobody can parse would silently disable that promise.
        final reviewDate = record.reviewDate.trim();
        final parsed = _parseIsoDate(reviewDate);
        if (reviewDate.isEmpty) {
          violations.add('review_date_blank:$providerId');
        } else if (parsed == null) {
          violations.add('review_date_unparsed:$providerId:$reviewDate');
        }
      }

      // visibility coherence: a provider the entry gate recorded must be
      // locked, and a lock may not name a provider the gate never recorded.
      if (anchor != null && anchor.entryVisibility.isNotEmpty) {
        for (final providerId in anchor.entryVisibility.keys) {
          if (!lockedIds.contains(providerId)) {
            violations.add('provider_unlocked:$providerId');
          }
        }
        final unaccounted = anchor.entryVisibility.length - lockedIds.length;
        if (unaccounted > 0) {
          violations.add(
            'snapshot_provider_unaccounted:$unaccounted:'
            '${anchor.entryVisibility.length}',
          );
        }
        for (final record in records) {
          final providerId = record.providerId.trim();
          if (providerId.isEmpty) continue;
          final visibility = anchor.entryVisibility[providerId]?.trim();
          if (visibility == null) {
            violations.add('provider_unlisted:$providerId');
            continue;
          }
          final expected = Sprint117SnapshotLoader._lockStatus(visibility);
          if (expected.isEmpty) {
            violations.add('visibility_unknown:$providerId:$visibility');
            continue;
          }
          if (record.status.trim() != expected) {
            violations.add(
              'status_drift:$providerId:${record.status.trim()}:$visibility',
            );
          }
        }
      }
    }

    // --- review window -----------------------------------------------------
    // Measured at the instant the entry gate recorded, never at wall-clock
    // time, so reruns of this gate are reproducible. Every provider whose
    // window has elapsed is listed, whether or not the lock declared it.
    final asOf = anchor?.asOfEpochMs ?? 0;
    if (asOf > 0 && records != null) {
      for (final record in records) {
        final providerId = record.providerId.trim();
        if (providerId.isEmpty) continue;
        final parsed = _parseIsoDate(record.reviewDate.trim());
        if (parsed == null) continue;
        final elapsed = parsed.millisecondsSinceEpoch <= asOf;
        if (elapsed) expired.add(providerId);
        final declaredExpired =
            record.status.trim() == Sprint117SnapshotContract.expiredStatus;
        if (elapsed && !declaredExpired) {
          violations.add(
            'expired_status_required:$providerId:${record.reviewDate.trim()}',
          );
        }
        if (!elapsed && declaredExpired) {
          violations.add(
            'expired_status_without_elapsed_window:$providerId:'
            '${record.reviewDate.trim()}',
          );
        }
      }
    }

    // --- resolution --------------------------------------------------------
    // The exposed subset is resolved from the entry gate's recorded visibility,
    // not from whatever status a lock row happens to claim. A row that
    // contradicts its recorded visibility is already a violation, and letting
    // that bad row decide beta exposure would hide a blocked provider behind a
    // drifted status.
    final resolved = records ?? const <Sprint117SnapshotRecord>[];
    final visibility = anchor?.entryVisibility ?? const <String, String>{};
    final exposed = <String>[
      for (final providerId in visibility.keys)
        if (Sprint117SnapshotLoader._lockStatus(visibility[providerId]!) !=
                Sprint117SnapshotContract.blockedStatus &&
            lockedIds.contains(providerId))
          providerId,
    ];
    final blocked = <String>[
      for (final providerId in visibility.keys)
        if (Sprint117SnapshotLoader._lockStatus(visibility[providerId]!) ==
            Sprint117SnapshotContract.blockedStatus)
          providerId,
    ];

    final state = violations.isNotEmpty
        ? Sprint117SnapshotState.fail
        : missing.isNotEmpty
        ? Sprint117SnapshotState.blocked
        : Sprint117SnapshotState.pass;
    final verdict = switch (state) {
      Sprint117SnapshotState.pass => Sprint117SnapshotContract.passVerdict,
      Sprint117SnapshotState.fail => Sprint117SnapshotContract.failVerdict,
      Sprint117SnapshotState.blocked =>
        Sprint117SnapshotContract.blockedVerdict,
    };

    final openItems = <String>[...anchor?.carriedOpenItems ?? const <String>[]];
    final cohortVerdict = anchor?.cohortVerdict.trim() ?? '';
    if (cohortVerdict.isNotEmpty &&
        cohortVerdict != Sprint117SnapshotContract.cohortVerifiedVerdict) {
      openItems.add('upstream_cohort_not_verified:$cohortVerdict');
    }

    final limitations = <String>[
      'This lock freezes local certification state only. It is not live provider availability and claims no quota, cost, credential, handshake, or hosted CI evidence.',
      'Every locked API version is the source placeholder '
          '${Sprint117SnapshotContract.unclaimedApiVersion}; 116.4 has recorded no verified provider API version, so the lock pins the placeholder rather than inventing one.',
      'The review date is the single recertification instant 116.2 records; per-provider review windows are not evidenced and are therefore not locked.',
      'Live provider certification, real participant consent, kill-switch drills, billing settlement, hosted CI, and publication remain ${Sprint117SnapshotContract.externalGates}.',
    ];

    final fieldCoverage = <String, int>{
      for (final field in Sprint117SnapshotContract.requiredFields)
        field: resolved
            .where(
              (record) => switch (field) {
                'provider_id' => record.providerId.trim().isNotEmpty,
                'connector_version' =>
                  record.connectorVersion.trim().isNotEmpty,
                'status' => record.status.trim().isNotEmpty,
                'limitations' =>
                  record.limitations
                      .where((entry) => entry.trim().isNotEmpty)
                      .isNotEmpty,
                'icon_version' => record.iconVersion.trim().isNotEmpty,
                'api_version' => record.apiVersion.trim().isNotEmpty,
                'review_date' =>
                  _parseIsoDate(record.reviewDate.trim()) != null,
                _ => false,
              },
            )
            .length,
    };

    return Sprint117SnapshotReport(
      state: state,
      verdict: verdict,
      missingFields: missing.toList(growable: false),
      violations: violations.toList(growable: false),
      anchor: anchor,
      records: resolved,
      exposedSubset: exposed.toList(growable: false),
      blockedSubset: blocked.toList(growable: false),
      expiredProviderIds: expired.toList(growable: false),
      openItems: openItems,
      limitations: limitations,
      fieldCoverage: fieldCoverage,
    );
  }

  /// A review date the lock cannot parse is not a recertification promise. The
  /// round-trip through the formatted value rejects overflow dates such as
  /// 2027-02-30 that `DateTime.parse` would otherwise normalise silently.
  static DateTime? _parseIsoDate(String value) {
    if (value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    final month = int.tryParse(value.substring(5, 7));
    final day = int.tryParse(value.substring(8, 10));
    if (month != parsed.month || day != parsed.day) return null;
    return DateTime.utc(parsed.year, parsed.month, parsed.day);
  }
}
