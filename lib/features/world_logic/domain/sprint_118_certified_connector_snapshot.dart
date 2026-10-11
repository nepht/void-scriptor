/// Fail-closed certified-connector snapshot for roadmap step 118.3 -- Certified
/// Connector Snapshot.
///
/// Objective (external canonical `sprint_118.json`): freeze the connector subset
/// that was actually released, together with its `connector_version`, `status`,
/// `limitations`, `regions`, `plans`, `icon_version`, and `recheck_date`.
///
/// The canonical contract is blunt about the situation this snapshot is written
/// against. Sprint 118 runs on the delayed corrective path: the 118.2 charter
/// froze an expansion budget of `0` new certified connectors out of `32`
/// registered, and the committed 117.41 connector-registry evidence records
/// `CERTIFIED: 0`, `LIMITED: 0`, `UNVERIFIED: 32`, `EXPOSED: 0`. A snapshot that
/// freezes "the released subset" therefore has exactly one honest answer: an
/// empty released subset, cross-checked against the registry counts that say so.
///
/// The gate is fail-closed on eight families of rules:
///
/// * The 118.2 charter anchor must be a genuine `pass` on
///   `CHARTER_COMPLETE_LOCAL`, and the committed 117.41 registry evidence must be
///   readable. A snapshot built on a charter that did not complete describes a
///   release nobody authorized.
/// * The snapshot's registered provider count must equal both the charter's
///   `registered_providers` and the registry's `provider_count`. A snapshot that
///   silently drops or invents providers is not a freeze.
/// * Every frozen entry must carry every canonical field non-empty, and the
///   contract must declare all eight canonical field names. An entry that
///   forgets its recheck date is not a snapshot entry.
/// * Every entry status must come from the known certification vocabulary, and
///   the released subset may only contain `CERTIFIED` or `LIMITED` connectors.
///   Freezing an `UNVERIFIED` connector as released is the defect this gate
///   exists to refuse.
/// * The released subset may never exceed the certified-and-limited counts the
///   committed evidence records. With `0` certified of `32`, the only honest
///   released subset is empty, and any entry claiming release is refused by name.
/// * Every region must come from the `ProviderRegion` wire vocabulary and every
///   plan from the subscription-plan vocabulary, and both must be non-empty.
///   A connector available nowhere is not a connector.
/// * Every entry must declare at least one limitation, so the freeze states the
///   boundary it was certified under instead of implying live availability.
/// * Provider ids must be unique, and every `recheck_date` must be a real ISO
///   calendar date. A duplicate id or a fabricated date is not a freeze.
///
/// Live certification, provider exposure, release authorization, and external
/// telemetry remain `DEFERRED-EXTERNAL`; this snapshot freezes local
/// certification state and executes none of it.
library;

import 'dart:convert';
import 'dart:io';

import 'github_app_release_authorization.dart';

/// The three states a snapshot evaluation can rest in. `blocked` is the honest
/// resting state for "this snapshot cannot yet be trusted", and it is distinct
/// from `fail`, which means the snapshot contradicts its own evidence.
enum Sprint118SnapshotState { pass, fail, blocked }

/// One frozen connector entry: the subset of the registry that was actually
/// released, with the boundary it was certified under.
class Sprint118ConnectorSnapshotEntry {
  const Sprint118ConnectorSnapshotEntry({
    required this.providerId,
    required this.connectorVersion,
    required this.status,
    required this.limitations,
    required this.regions,
    required this.plans,
    required this.iconVersion,
    required this.recheckDate,
  });

  final String providerId;
  final String connectorVersion;

  /// A certification status drawn from the known vocabulary, e.g. `CERTIFIED`.
  final String status;

  /// The limitations the entry was certified under. At least one is required so
  /// the freeze cannot imply live availability.
  final List<String> limitations;

  /// `ProviderRegion` wire names, e.g. `GLOBAL`.
  final List<String> regions;

  /// Subscription-plan names under which the connector is released.
  final List<String> plans;

  final String iconVersion;

  /// ISO `yyyy-MM-dd` recheck date.
  final String recheckDate;

  /// Whether this entry is part of the released subset. Only certified and
  /// limited connectors may be released.
  bool get isReleased =>
      Sprint118SnapshotContract.releasedStatuses.contains(status);
}

/// The frozen snapshot. `releasedEntries` is the subset that was actually
/// released; on the delayed path with zero certified connectors it must be
/// empty, and the gate proves that emptiness against the committed evidence.
class Sprint118CertifiedConnectorSnapshot {
  const Sprint118CertifiedConnectorSnapshot({
    required this.releaseState,
    required this.registeredProviderCount,
    required this.releasedEntries,
  });

  final String releaseState;
  final int registeredProviderCount;
  final List<Sprint118ConnectorSnapshotEntry> releasedEntries;

  /// Entries grouped by status, so the gate can compare each status count to the
  /// committed registry evidence.
  Map<String, int> get statusCounts {
    final counts = <String, int>{};
    for (final entry in releasedEntries) {
      counts[entry.status] = (counts[entry.status] ?? 0) + 1;
    }
    return counts;
  }

  List<String> get releasedProviderIds => <String>[
    for (final entry in releasedEntries) entry.providerId,
  ];
}

/// What the committed 118.2 charter and 117.41 registry evidence actually say. A
/// snapshot is only as honest as the witnesses it is anchored to.
class Sprint118ConnectorSnapshotAnchor {
  const Sprint118ConnectorSnapshotAnchor({
    required this.charterState,
    required this.charterVerdict,
    required this.releaseState,
    required this.charterCertified,
    required this.charterRegistered,
    required this.evidenceCertified,
    required this.evidenceLimited,
    required this.evidenceUnverified,
    required this.evidenceProviderCount,
    required this.evidenceExposed,
  });

  final String charterState;
  final String charterVerdict;
  final String releaseState;
  final int charterCertified;
  final int charterRegistered;
  final int evidenceCertified;
  final int evidenceLimited;
  final int evidenceUnverified;
  final int evidenceProviderCount;
  final int evidenceExposed;

  /// The number of connectors the committed evidence permits in the released
  /// subset: certified plus limited.
  int get evidenceReleasedCount => evidenceCertified + evidenceLimited;
}

/// The measured result. `pass` means the snapshot is a faithful freeze of what
/// was released; `blocked` means it cannot yet be trusted; `fail` means it
/// contradicts its evidence.
class Sprint118SnapshotReport {
  const Sprint118SnapshotReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.missingFields = const <String>[],
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.frozenProviderCount = 0,
    this.releasedSubset = const <String>[],
  });

  final Sprint118SnapshotState state;
  final String verdict;
  final String releaseState;
  final List<String> missingFields;
  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final int frozenProviderCount;
  final List<String> releasedSubset;

  /// Whether the snapshot may be treated as a frozen release record. Only a
  /// genuine `pass` allows it.
  bool get snapshotFrozen => state == Sprint118SnapshotState.pass;

  String get externalGates => Sprint118SnapshotContract.externalGates;
}

/// The fixed vocabulary of step 118.3, kept in one place so the loader, the gate,
/// and the emitter cannot drift apart about what the step is made of.
abstract final class Sprint118SnapshotContract {
  const Sprint118SnapshotContract._();

  static const String canonicalStep = '118.3';
  static const String title = 'Certified Connector Snapshot';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_certified_connector_snapshot.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.2 charter this snapshot is anchored to.
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';

  /// The committed 117.41 connector-registry evidence this snapshot freezes.
  static const String registryEvidencePath =
      'docs/evidence/sprint-117-41-manifest-20261002.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The verdict and state the 118.2 charter anchor must carry for the snapshot
  /// to be trustworthy.
  static const String requiredCharterVerdict = 'CHARTER_COMPLETE_LOCAL';
  static const String requiredCharterState = 'pass';
  static const String delayedReleaseState = 'GA_DELAYED';
  static const String releasedReleaseState = 'GA_RELEASED';
  static const String authorizedReleaseState =
      GithubAppReleaseAuthorization.authorizedReleaseState;

  /// The eight canonical entry fields from `sprint_118.json` step 118.3.
  static const List<String> requiredFields = <String>[
    'provider_id',
    'connector_version',
    'status',
    'limitations',
    'regions',
    'plans',
    'icon_version',
    'recheck_date',
  ];

  /// Certification statuses drawn from the committed registry evidence and the
  /// 117.4 snapshot-lock vocabulary. These are the wire names the registry
  /// records, not hand-invented labels.
  static const List<String> knownStatuses = <String>[
    'CERTIFIED',
    'LIMITED',
    'UNVERIFIED',
    'PLANNED',
    'DEGRADED',
    'BLOCKED',
    'EXPIRED',
  ];

  /// The only statuses that may appear in the released subset. An `UNVERIFIED`,
  /// `PLANNED`, `DEGRADED`, `BLOCKED`, or `EXPIRED` connector is never released.
  static const List<String> releasedStatuses = <String>['CERTIFIED', 'LIMITED'];

  /// `ProviderRegion` wire names from the shipped connector manifest.
  static const List<String> knownRegions = <String>[
    'GLOBAL',
    'ID',
    'SEA',
    'EU',
    'NA',
  ];

  /// Subscription-plan names from the shipped entitlement model (`PlanTier`).
  static const List<String> knownPlans = <String>[
    'free',
    'standard',
    'premium',
    'custom',
  ];

  /// The canonical snapshot, declared here as the single source of truth. The
  /// gate evaluates exactly this object, and the emitter writes exactly this
  /// object, so the record cannot be made to agree with itself. With zero
  /// certified connectors the released subset is empty.
  static const Sprint118CertifiedConnectorSnapshot canonicalSnapshot =
      Sprint118CertifiedConnectorSnapshot(
        releaseState: delayedReleaseState,
        registeredProviderCount: 32,
        releasedEntries: <Sprint118ConnectorSnapshotEntry>[],
      );

  static const Sprint118CertifiedConnectorSnapshot authorizedSnapshot =
      Sprint118CertifiedConnectorSnapshot(
        releaseState: authorizedReleaseState,
        registeredProviderCount: 32,
        releasedEntries: <Sprint118ConnectorSnapshotEntry>[
          Sprint118ConnectorSnapshotEntry(
            providerId: GithubAppReleaseAuthorization.authorizedProviderId,
            connectorVersion:
                GithubAppReleaseAuthorization.authorizedConnectorVersion,
            status: GithubAppReleaseAuthorization.authorizedStatus,
            limitations: <String>['live_provider_certification'],
            regions: <String>['GLOBAL'],
            plans: <String>['free', 'standard', 'premium', 'custom'],
            iconVersion: 'bundled-v1',
            recheckDate: '2027-03-27',
          ),
        ],
      );

  /// Parse an ISO `yyyy-MM-dd` date, returning `null` when the text is not a real
  /// calendar date. A fabricated date such as `2027-13-40` is refused.
  static DateTime? parseIsoDate(String text) {
    final trimmed = text.trim();
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(trimmed);
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;
    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  }
}

/// Reads the committed 118.2 charter and 117.41 registry evidence. Never
/// invents: an unreadable witness yields `null`, which the gate reports as
/// blocked rather than as a pass.
class Sprint118ConnectorSnapshotLoader {
  const Sprint118ConnectorSnapshotLoader();

  Sprint118ConnectorSnapshotAnchor? loadAnchor() {
    final charter = _readJsonObject(
      Sprint118SnapshotContract.charterManifestPath,
    );
    if (charter == null) return null;
    final registry = _readJsonObject(
      Sprint118SnapshotContract.registryEvidencePath,
    );
    if (registry == null) return null;

    final budget = charter['expansion_budget'];
    final budgetMap = budget is Map<String, dynamic>
        ? budget
        : const <String, dynamic>{};
    final statusCounts = registry['status_counts'];
    final statusMap = statusCounts is Map<String, dynamic>
        ? statusCounts
        : const <String, dynamic>{};
    final visibility = registry['visibility_counts'];
    final visibilityMap = visibility is Map<String, dynamic>
        ? visibility
        : const <String, dynamic>{};

    return Sprint118ConnectorSnapshotAnchor(
      charterState: _text(charter['state']),
      charterVerdict: _text(charter['verdict']),
      releaseState: _text(charter['release_state']),
      charterCertified: _int(budgetMap['currently_certified']),
      charterRegistered: _int(budgetMap['registered_providers']),
      evidenceCertified: _int(statusMap['CERTIFIED']),
      evidenceLimited: _int(statusMap['LIMITED']),
      evidenceUnverified: _int(statusMap['UNVERIFIED']),
      evidenceProviderCount: _int(registry['provider_count']),
      evidenceExposed: _int(visibilityMap['EXPOSED']),
    );
  }

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

  static String _text(Object? value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    return value.toString().trim();
  }

  static int _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }
}

class Sprint118CertifiedConnectorSnapshotGate {
  const Sprint118CertifiedConnectorSnapshotGate();

  /// Evaluate the canonical snapshot against committed evidence. This is the
  /// entry point that makes the answer trustworthy: the verdict is bound to the
  /// witnesses on disk.
  Sprint118SnapshotReport evaluate() {
    final authorization = GithubAppReleaseAuthorization.load();
    return evaluateWith(
      const Sprint118ConnectorSnapshotLoader().loadAnchor(),
      authorization == null
          ? Sprint118SnapshotContract.canonicalSnapshot
          : Sprint118SnapshotContract.authorizedSnapshot,
      authorization: authorization,
    );
  }

  Sprint118SnapshotReport evaluateWith(
    Sprint118ConnectorSnapshotAnchor? anchor,
    Sprint118CertifiedConnectorSnapshot snapshot, {
    GithubAppReleaseAuthorization? authorization,
  }) {
    if (anchor == null) {
      return Sprint118SnapshotReport(
        state: Sprint118SnapshotState.blocked,
        verdict: 'SPRINT_118_SNAPSHOT_EVIDENCE_UNREADABLE',
        releaseState: snapshot.releaseState,
        missingFields: List<String>.from(
          Sprint118SnapshotContract.requiredFields,
        ),
        blockers: const <String>['committed_snapshot_evidence_unreadable'],
        openItems: const <String>['committed_snapshot_evidence_unreadable'],
      );
    }

    final violations = <String>[];
    final blockers = <String>[];
    final authorized =
        authorization?.isValid == true &&
        snapshot.releaseState ==
            Sprint118SnapshotContract.authorizedReleaseState;

    // (1) The 118.2 charter anchor must be a genuine pass. A snapshot written
    // against an incomplete charter describes a release nobody authorized.
    if (anchor.charterState != Sprint118SnapshotContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118SnapshotContract.requiredCharterVerdict) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (2) The release state must agree with the charter anchor.
    if (!authorized && anchor.releaseState != snapshot.releaseState) {
      violations.add(
        'release_state_mismatch:anchor=${anchor.releaseState}:'
        'snapshot=${snapshot.releaseState}',
      );
    }

    // (3) The registered provider count must agree with both the charter budget
    // and the committed registry evidence. A freeze that drops or invents
    // providers is not a freeze.
    if (snapshot.registeredProviderCount != anchor.charterRegistered) {
      violations.add(
        'snapshot_registered_count_mismatch:'
        'snapshot=${snapshot.registeredProviderCount}:'
        'charter=${anchor.charterRegistered}',
      );
    }
    if (snapshot.registeredProviderCount != anchor.evidenceProviderCount) {
      violations.add(
        'snapshot_registry_count_mismatch:'
        'snapshot=${snapshot.registeredProviderCount}:'
        'registry=${anchor.evidenceProviderCount}',
      );
    }

    // (4) Every frozen entry must carry every canonical field, and the contract
    // must declare all eight canonical field names.
    if (Sprint118SnapshotContract.requiredFields.length != 8) {
      violations.add('contract_field_count_not_eight');
    }
    final seenProviderIds = <String>{};
    for (final entry in snapshot.releasedEntries) {
      if (entry.providerId.trim().isEmpty) {
        violations.add('entry_blank_provider_id');
      } else if (!seenProviderIds.add(entry.providerId)) {
        violations.add('entry_duplicate_provider_id:${entry.providerId}');
      }
      if (entry.connectorVersion.trim().isEmpty) {
        violations.add('entry_blank_connector_version:${entry.providerId}');
      }
      if (entry.iconVersion.trim().isEmpty) {
        violations.add('entry_blank_icon_version:${entry.providerId}');
      }
      if (!Sprint118SnapshotContract.knownStatuses.contains(entry.status)) {
        violations.add(
          'entry_unknown_status:${entry.providerId}:${entry.status}',
        );
      }
      if (!entry.isReleased) {
        violations.add(
          'entry_status_not_releasable:${entry.providerId}:${entry.status}',
        );
      }
      if (entry.limitations.isEmpty) {
        violations.add('entry_no_limitations:${entry.providerId}');
      }
      if (entry.regions.isEmpty) {
        violations.add('entry_no_regions:${entry.providerId}');
      }
      for (final region in entry.regions) {
        if (!Sprint118SnapshotContract.knownRegions.contains(region)) {
          violations.add('entry_unknown_region:${entry.providerId}:$region');
        }
      }
      if (entry.plans.isEmpty) {
        violations.add('entry_no_plans:${entry.providerId}');
      }
      for (final plan in entry.plans) {
        if (!Sprint118SnapshotContract.knownPlans.contains(plan)) {
          violations.add('entry_unknown_plan:${entry.providerId}:$plan');
        }
      }
      if (Sprint118SnapshotContract.parseIsoDate(entry.recheckDate) == null) {
        violations.add(
          'entry_invalid_recheck_date:${entry.providerId}:${entry.recheckDate}',
        );
      }
    }

    // (5) The released subset may never exceed the certified-and-limited counts
    // the committed evidence records. With zero certified of thirty-two, the
    // only honest released subset is empty.
    final releasedCount = snapshot.releasedEntries.length;
    if (releasedCount != anchor.evidenceReleasedCount) {
      violations.add(
        'released_subset_count_mismatch:'
        'snapshot=$releasedCount:evidence=${anchor.evidenceReleasedCount}',
      );
    }
    final statusCounts = snapshot.statusCounts;
    final certifiedInSnapshot = statusCounts['CERTIFIED'] ?? 0;
    final limitedInSnapshot = statusCounts['LIMITED'] ?? 0;
    if (certifiedInSnapshot != anchor.evidenceCertified) {
      violations.add(
        'released_certified_count_mismatch:'
        'snapshot=$certifiedInSnapshot:evidence=${anchor.evidenceCertified}',
      );
    }
    if (limitedInSnapshot != anchor.evidenceLimited) {
      violations.add(
        'released_limited_count_mismatch:'
        'snapshot=$limitedInSnapshot:evidence=${anchor.evidenceLimited}',
      );
    }

    // (6) An exposed connector that is not in the released subset contradicts
    // the registry: exposure without a frozen release record is not allowed.
    if (anchor.evidenceExposed > releasedCount) {
      violations.add(
        'exposed_beyond_released_subset:'
        'exposed=${anchor.evidenceExposed}:released=$releasedCount',
      );
    }

    if (authorized &&
        (snapshot.releasedProviderIds.length != 1 ||
            !snapshot.releasedProviderIds.contains(
              GithubAppReleaseAuthorization.authorizedProviderId,
            ))) {
      violations.add('github_app_authorized_snapshot_missing');
    }

    final openItems = <String>[...violations, ...blockers];

    if (violations.isNotEmpty) {
      return Sprint118SnapshotReport(
        state: Sprint118SnapshotState.fail,
        verdict: 'SPRINT_118_SNAPSHOT_EVIDENCE_VIOLATION',
        releaseState: snapshot.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: openItems,
        frozenProviderCount: releasedCount,
        releasedSubset: snapshot.releasedProviderIds,
      );
    }
    if (blockers.isNotEmpty) {
      return Sprint118SnapshotReport(
        state: Sprint118SnapshotState.blocked,
        verdict: 'SPRINT_118_SNAPSHOT_BLOCKED_UPSTREAM',
        releaseState: snapshot.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: openItems,
        frozenProviderCount: releasedCount,
        releasedSubset: snapshot.releasedProviderIds,
      );
    }
    return Sprint118SnapshotReport(
      state: Sprint118SnapshotState.pass,
      verdict: authorized
          ? 'CERTIFIED_CONNECTOR_SNAPSHOT_AUTHORIZED_LOCAL'
          : 'CERTIFIED_CONNECTOR_SNAPSHOT_FROZEN_LOCAL',
      releaseState: snapshot.releaseState,
      frozenProviderCount: releasedCount,
      releasedSubset: snapshot.releasedProviderIds,
    );
  }
}
