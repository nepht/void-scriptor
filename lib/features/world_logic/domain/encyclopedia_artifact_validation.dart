// Sprint 111.23 - Artifact Usage & Authenticity Validation.
//
//
//
// Domain-only validator that detects a usage event going wrong: an actor who
//
// is not a recorded holder or custodian (owner check), activation that
//
// violates the 111.22 rule set (ability, cooldown, limitation cap), a
//
// location that contradicts the lineage's residence history or an explicit
//
// allow-list (location check), and forged or disputed artifacts (authenticity
//
// check). Produces an explanation report and supports explicit manual
//
// exceptions.
//
//
//
// No persistence, UI, locale, network, wall clock, or random input.
library;

import 'encyclopedia_activation_rules.dart';
import 'encyclopedia_artifact.dart';
import 'encyclopedia_ownership_lineage.dart';

String _requireTrimmed(String value, String fieldName) {
  if (value.trim().isEmpty) {
    throw ArgumentError('$fieldName must be non-empty');
  }

  return value.trim();
}

String? _optionalTrimmed(String? value, String fieldName) {
  final trimmed = value?.trim();

  if (trimmed != null && trimmed.isEmpty) {
    throw ArgumentError('$fieldName must be non-empty when provided');
  }

  return trimmed;
}

/// The kind of usage problem a validator can report.
enum ArtifactValidationKind {
  ownerMismatch('Owner mismatch'),

  unknownOwner('Unknown owner'),

  unauthorizedActivation('Unauthorized activation'),

  impossibleLocation('Impossible location'),

  inauthentic('Inauthentic'),

  questionableAuthenticity('Questionable authenticity');

  const ArtifactValidationKind(this.label);

  final String label;
}

/// One recorded use of an artifact by some actor, optionally naming the
/// ability, place, and world tick so activation and location checks can run.
class ArtifactUsageEvent {
  const ArtifactUsageEvent._({
    required this.usageId,

    required this.artifactId,

    required this.actorId,

    this.locationId,

    this.abilityId,

    this.atTick,

    this.useCount = 1,
  });

  factory ArtifactUsageEvent.validated({
    required String usageId,

    required String artifactId,

    required String actorId,

    String? locationId,

    String? abilityId,

    int? atTick,

    int useCount = 1,
  }) {
    if (useCount < 0) {
      throw ArgumentError('useCount must not be negative');
    }

    if (atTick != null && atTick < 0) {
      throw ArgumentError('atTick must not be negative');
    }

    return ArtifactUsageEvent._(
      usageId: _requireTrimmed(usageId, 'usageId'),

      artifactId: _requireTrimmed(artifactId, 'artifactId'),

      actorId: _requireTrimmed(actorId, 'actorId'),

      locationId: _optionalTrimmed(locationId, 'locationId'),

      abilityId: _optionalTrimmed(abilityId, 'abilityId'),

      atTick: atTick,

      useCount: useCount,
    );
  }

  final String usageId;

  final String artifactId;

  final String actorId;

  final String? locationId;

  final String? abilityId;

  final int? atTick;

  final int useCount;
}

/// An explicit, user-recorded exception that suppresses one issue kind for
/// one artifact.
class ArtifactManualException {
  const ArtifactManualException._({
    required this.exceptionId,

    required this.artifactId,

    required this.kind,

    required this.reason,
  });

  factory ArtifactManualException.validated({
    required String exceptionId,

    required String artifactId,

    required ArtifactValidationKind kind,

    required String reason,
  }) {
    return ArtifactManualException._(
      exceptionId: _requireTrimmed(exceptionId, 'exceptionId'),

      artifactId: _requireTrimmed(artifactId, 'artifactId'),

      kind: kind,

      reason: _requireTrimmed(reason, 'reason'),
    );
  }

  final String exceptionId;

  final String artifactId;

  final ArtifactValidationKind kind;

  final String reason;

  bool matches(String artifactId, ArtifactValidationKind kind) =>
      this.artifactId == artifactId && this.kind == kind;
}

/// A single reported usage problem.
class ArtifactValidationIssue {
  const ArtifactValidationIssue._({
    required this.issueId,

    required this.artifactId,

    required this.kind,

    required this.message,

    this.actorId,

    this.locationId,
  });

  factory ArtifactValidationIssue.validated({
    required String issueId,

    required String artifactId,

    required ArtifactValidationKind kind,

    required String message,

    String? actorId,

    String? locationId,
  }) {
    return ArtifactValidationIssue._(
      issueId: _requireTrimmed(issueId, 'issueId'),

      artifactId: _requireTrimmed(artifactId, 'artifactId'),

      kind: kind,

      message: _requireTrimmed(message, 'message'),

      actorId: _optionalTrimmed(actorId, 'actorId'),

      locationId: _optionalTrimmed(locationId, 'locationId'),
    );
  }

  final String issueId;

  final String artifactId;

  final ArtifactValidationKind kind;

  final String message;

  final String? actorId;

  final String? locationId;
}

/// Immutable validation report over a single usage event.
class ArtifactValidationReport {
  const ArtifactValidationReport._(this._issues);

  factory ArtifactValidationReport.of(List<ArtifactValidationIssue> issues) {
    final ids = <String, String>{};

    for (final i in issues) {
      if (ids.containsKey(i.issueId)) {
        throw ArgumentError('duplicate issueId: ${i.issueId}');
      }

      ids[i.issueId] = i.issueId;
    }

    final sorted = List<ArtifactValidationIssue>.of(issues)
      ..sort((a, b) => a.issueId.compareTo(b.issueId));

    return ArtifactValidationReport._(List.unmodifiable(sorted));
  }

  final List<ArtifactValidationIssue> _issues;

  bool get hasIssues => _issues.isNotEmpty;

  int get issueCount => _issues.length;

  List<ArtifactValidationIssue> get issues => _issues;

  List<ArtifactValidationKind> get kinds {
    return List.unmodifiable(_issues.map((i) => i.kind));
  }

  List<ArtifactValidationIssue> issuesOf(ArtifactValidationKind kind) {
    return _issues.where((i) => i.kind == kind).toList();
  }

  /// A human-readable explanation of every active issue.
  String describe() {
    if (_issues.isEmpty) return 'No usage warnings.';

    final buffer = StringBuffer('Artifact usage warnings:');

    for (final i in _issues) {
      buffer.write(' [${i.kind.label}] ${i.message}');
    }

    return buffer.toString();
  }
}

/// Deterministic validator of one artifact usage event against canon.
///
/// - [artifact]: the 111.20 record; its authenticity status drives the
///   authenticity check.
/// - [lineage]: the 111.21 ownership record; when absent the actor cannot be
///   verified and an unknownOwner issue is reported instead of a silent pass.
/// - [usage]: the usage event under inspection.
/// - [rules]: optional 111.22 rule set; activation and cooldown checks run
///   only when rules are provided.
/// - [lastUseTickByCooldown]: recorded last-use ticks keyed by cooldown id.
/// - [allowedLocationIds]: explicit allow-list; a usage place outside it is
///   impossible. Without an allow-list, a usage place that contradicts the
///   lineage's current residence is impossible.
/// - [exceptions]: manual exceptions suppressing (artifact, kind) pairs.
class ArtifactUsageValidator {
  const ArtifactUsageValidator();

  ArtifactValidationReport validate({
    required ArtifactRecord artifact,

    OwnershipLineageRecord? lineage,

    required ArtifactUsageEvent usage,

    ArtifactRules? rules,

    Map<String, int> lastUseTickByCooldown = const {},

    Set<String> allowedLocationIds = const {},

    List<ArtifactManualException> exceptions = const [],
  }) {
    if (usage.artifactId != artifact.artifactId) {
      throw ArgumentError(
        'usage references ${usage.artifactId} but record is '
        '${artifact.artifactId}',
      );
    }

    if (lineage != null && lineage.artifactId != artifact.artifactId) {
      throw ArgumentError(
        'lineage references ${lineage.artifactId} but record is '
        '${artifact.artifactId}',
      );
    }

    final issues = <ArtifactValidationIssue>[];

    final id = artifact.artifactId;

    _checkOwner(issues, artifactId: id, usage: usage, lineage: lineage);

    if (rules != null) {
      _checkActivation(
        issues,
        artifactId: id,
        usage: usage,
        rules: rules,
        lastUseTickByCooldown: lastUseTickByCooldown,
      );
    }

    _checkLocation(
      issues,
      artifactId: id,
      usage: usage,
      lineage: lineage,
      allowedLocationIds: allowedLocationIds,
    );

    _checkAuthenticity(issues, artifact: artifact);

    final suppressed = issues.where((issue) {
      for (final e in exceptions) {
        if (e.matches(issue.artifactId, issue.kind)) return true;
      }

      return false;
    }).toSet();

    final active = issues.where((i) => !suppressed.contains(i)).toList();

    return ArtifactValidationReport.of(active);
  }

  void _checkOwner(
    List<ArtifactValidationIssue> issues, {
    required String artifactId,

    required ArtifactUsageEvent usage,

    OwnershipLineageRecord? lineage,
  }) {
    final line = lineage;

    if (line == null) {
      issues.add(
        ArtifactValidationIssue.validated(
          issueId: 'uu_$artifactId',
          artifactId: artifactId,
          kind: ArtifactValidationKind.unknownOwner,
          message:
              'No ownership lineage recorded for "$artifactId"; actor '
              '"${usage.actorId}" cannot be verified',
          actorId: usage.actorId,
        ),
      );

      return;
    }

    final isHolder = line.hasHolder(usage.actorId);

    final isCustodian = line.custodies.any(
      (c) => c.custodianId == usage.actorId,
    );

    if (!isHolder && !isCustodian) {
      issues.add(
        ArtifactValidationIssue.validated(
          issueId: 'om_${usage.actorId}_$artifactId',
          artifactId: artifactId,
          kind: ArtifactValidationKind.ownerMismatch,
          message:
              'Actor "${usage.actorId}" is not a recorded holder or '
              'custodian of "$artifactId"',
          actorId: usage.actorId,
        ),
      );
    }
  }

  void _checkActivation(
    List<ArtifactValidationIssue> issues, {
    required String artifactId,

    required ArtifactUsageEvent usage,

    required ArtifactRules rules,

    required Map<String, int> lastUseTickByCooldown,
  }) {
    final ability = usage.abilityId;

    if (ability != null && !rules.hasAbility(ability)) {
      issues.add(
        ArtifactValidationIssue.validated(
          issueId: 'ua_ability_${ability}_$artifactId',
          artifactId: artifactId,
          kind: ArtifactValidationKind.unauthorizedActivation,
          message: 'Ability "$ability" is not declared for "$artifactId"',
          actorId: usage.actorId,
        ),
      );
    }

    final tick = usage.atTick;

    if (tick != null) {
      for (final cooldown in rules.cooldowns) {
        final last = lastUseTickByCooldown[cooldown.cooldownId];

        if (last == null) continue;

        final ready =
            last <= tick &&
            cooldown.isReadyAt(lastUseTick: last, currentTick: tick);

        if (!ready) {
          issues.add(
            ArtifactValidationIssue.validated(
              issueId: 'ua_cd_${cooldown.cooldownId}_$artifactId',
              artifactId: artifactId,
              kind: ArtifactValidationKind.unauthorizedActivation,
              message:
                  'Ability activation at tick $tick is still inside the '
                  'cooldown window of "${cooldown.cooldownId}"',
              actorId: usage.actorId,
            ),
          );
        }
      }
    }

    for (final limitation in rules.limitations) {
      if (limitation.isExhausted(usedCount: usage.useCount)) {
        issues.add(
          ArtifactValidationIssue.validated(
            issueId: 'ua_lim_${limitation.limitationId}_$artifactId',
            artifactId: artifactId,
            kind: ArtifactValidationKind.unauthorizedActivation,
            message:
                'Limitation "${limitation.limitationId}" exhausted: use '
                'count ${usage.useCount} exceeds cap ${limitation.maxUses}',
            actorId: usage.actorId,
          ),
        );
      }
    }
  }

  void _checkLocation(
    List<ArtifactValidationIssue> issues, {
    required String artifactId,

    required ArtifactUsageEvent usage,

    OwnershipLineageRecord? lineage,

    required Set<String> allowedLocationIds,
  }) {
    final place = usage.locationId;

    if (place == null) return;

    if (allowedLocationIds.isNotEmpty && !allowedLocationIds.contains(place)) {
      issues.add(
        ArtifactValidationIssue.validated(
          issueId:
              'il_$place'
              '_$artifactId',
          artifactId: artifactId,
          kind: ArtifactValidationKind.impossibleLocation,
          message:
              'Location "$place" is outside the allowed locations for '
              '"$artifactId"',
          locationId: place,
        ),
      );

      return;
    }

    final line = lineage;

    if (line == null || allowedLocationIds.isNotEmpty) return;

    final current = line.currentLocation;

    if (current == null) return;

    final matchesCurrent = line.locations.any(
      (loc) => loc.isCurrent && loc.placeId == place,
    );

    if (!matchesCurrent) {
      issues.add(
        ArtifactValidationIssue.validated(
          issueId:
              'il_$place'
              '_$artifactId',
          artifactId: artifactId,
          kind: ArtifactValidationKind.impossibleLocation,
          message:
              'Usage at "$place" contradicts the current residence '
              '"$current" of "$artifactId"',
          locationId: place,
        ),
      );
    }
  }

  void _checkAuthenticity(
    List<ArtifactValidationIssue> issues, {
    required ArtifactRecord artifact,
  }) {
    final status = artifact.authenticity;

    if (status == null) return;

    if (status == ArtifactAuthenticity.forged) {
      issues.add(
        ArtifactValidationIssue.validated(
          issueId: 'au_${status.name}_${artifact.artifactId}',
          artifactId: artifact.artifactId,
          kind: ArtifactValidationKind.inauthentic,
          message:
              'Artifact "${artifact.artifactId}" is recorded as '
              '${status.label}',
        ),
      );
    } else if (status == ArtifactAuthenticity.disputed ||
        status == ArtifactAuthenticity.suspected ||
        status == ArtifactAuthenticity.unknown) {
      issues.add(
        ArtifactValidationIssue.validated(
          issueId: 'au_${status.name}_${artifact.artifactId}',
          artifactId: artifact.artifactId,
          kind: ArtifactValidationKind.questionableAuthenticity,
          message:
              'Artifact "${artifact.artifactId}" authenticity is only '
              '${status.label}',
        ),
      );
    }
  }
}
