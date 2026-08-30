// Sprint 110.46 - Security & Privacy Verification.
//
// Domain-only contract for verifying secret faction data, spoiler metadata,
// diagnostic export sanitization, and project isolation. No persistence,
// UI, locale, network, wall clock, or random input.
//
// Acceptance canonical 110.46 (required_outputs):
//   threat_review, isolation_tests, secret_data_tests,
//   diagnostic_export_tests, fix_status.
library;

enum SecretClassification {
  public,
  factionSecret,
  characterSecret,
  plotTwist,
  worldSecret,
}

enum SecretVisibility { global, factionScoped, characterScoped, writerOnly }

class SecretDataRecord {
  const SecretDataRecord._({
    required this.id,
    required this.label,
    required this.classification,
    required this.visibility,
    required this.concealedTick,
    required this.releasedTick,
    required this.allowedFactionIds,
    required this.allowedCharacterIds,
    required this.reason,
  });

  factory SecretDataRecord.validated({
    required String id,
    required String label,
    required SecretClassification classification,
    required SecretVisibility visibility,
    required int concealedTick,
    int? releasedTick,
    List<String> allowedFactionIds = const [],
    List<String> allowedCharacterIds = const [],
    required String reason,
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'id must be non-empty');
    }
    if (label.isEmpty) {
      throw ArgumentError.value(label, 'label', 'label must be non-empty');
    }
    if (reason.isEmpty) {
      throw ArgumentError.value(reason, 'reason', 'reason must be non-empty');
    }
    if (concealedTick < 0) {
      throw ArgumentError.value(
        concealedTick,
        'concealedTick',
        'concealedTick must be >= 0',
      );
    }
    final release = releasedTick;
    if (release != null && release < concealedTick) {
      throw ArgumentError(
        'releasedTick ($release) cannot be less than concealedTick ($concealedTick)',
      );
    }
    if (visibility == SecretVisibility.factionScoped &&
        allowedFactionIds.isEmpty) {
      throw ArgumentError(
        'factionScoped visibility requires at least one allowedFactionId',
      );
    }
    if (visibility == SecretVisibility.characterScoped &&
        allowedCharacterIds.isEmpty) {
      throw ArgumentError(
        'characterScoped visibility requires at least one allowedCharacterId',
      );
    }
    return SecretDataRecord._(
      id: id,
      label: label,
      classification: classification,
      visibility: visibility,
      concealedTick: concealedTick,
      releasedTick: releasedTick,
      allowedFactionIds: List<String>.unmodifiable(allowedFactionIds),
      allowedCharacterIds: List<String>.unmodifiable(allowedCharacterIds),
      reason: reason,
    );
  }

  final String id;
  final String label;
  final SecretClassification classification;
  final SecretVisibility visibility;
  final int concealedTick;
  final int? releasedTick;
  final List<String> allowedFactionIds;
  final List<String> allowedCharacterIds;
  final String reason;

  bool isReleasedAt(int tick) {
    final release = releasedTick;
    if (release == null) return false;
    return tick >= release;
  }

  bool canObserverRead({
    String? observerFactionId,
    String? observerCharacterId,
    bool isWriter = false,
  }) {
    if (isWriter) return true;
    switch (visibility) {
      case SecretVisibility.global:
        return true;
      case SecretVisibility.factionScoped:
        if (observerFactionId == null) return false;
        return allowedFactionIds.contains(observerFactionId);
      case SecretVisibility.characterScoped:
        if (observerCharacterId == null) return false;
        return allowedCharacterIds.contains(observerCharacterId);
      case SecretVisibility.writerOnly:
        return false;
    }
  }
}

class ProjectNamespace {
  const ProjectNamespace._({required this.projectId, required this.knownIds});

  factory ProjectNamespace.validated({
    required String projectId,
    required Set<String> knownIds,
  }) {
    if (projectId.isEmpty) {
      throw ArgumentError.value(projectId, 'projectId', 'must be non-empty');
    }
    return ProjectNamespace._(
      projectId: projectId,
      knownIds: Set<String>.unmodifiable(knownIds),
    );
  }

  final String projectId;
  final Set<String> knownIds;

  List<String> foreignIdsIn(Iterable<String> candidateIds) {
    final result = <String>[];
    for (final id in candidateIds) {
      if (!knownIds.contains(id)) result.add(id);
    }
    return List<String>.unmodifiable(result);
  }

  bool containsAll(Iterable<String> candidateIds) {
    for (final id in candidateIds) {
      if (!knownIds.contains(id)) return false;
    }
    return true;
  }
}

class ProjectIsolationAuditor {
  const ProjectIsolationAuditor._({required this.local, required this.foreign});

  factory ProjectIsolationAuditor({
    required ProjectNamespace local,
    required ProjectNamespace foreign,
  }) {
    if (local.projectId == foreign.projectId) {
      throw ArgumentError(
        'local and foreign projectIds must differ (got ${local.projectId})',
      );
    }
    return ProjectIsolationAuditor._(local: local, foreign: foreign);
  }

  final ProjectNamespace local;
  final ProjectNamespace foreign;

  ProjectIsolationReport audit(Iterable<String> candidateIds) {
    final leaked = <String>[];
    for (final id in candidateIds) {
      if (local.knownIds.contains(id)) continue;
      leaked.add(id);
    }
    leaked.sort();
    return ProjectIsolationReport._(
      localProjectId: local.projectId,
      foreignProjectId: foreign.projectId,
      leakedForeignIds: List<String>.unmodifiable(leaked),
      isClean: leaked.isEmpty,
      isFullyContained: local.containsAll(candidateIds),
    );
  }
}

class ProjectIsolationReport {
  const ProjectIsolationReport._({
    required this.localProjectId,
    required this.foreignProjectId,
    required this.leakedForeignIds,
    required this.isClean,
    required this.isFullyContained,
  });

  final String localProjectId;
  final String foreignProjectId;
  final List<String> leakedForeignIds;
  final bool isClean;
  final bool isFullyContained;

  String explain() {
    final buffer = StringBuffer('isolation ');
    buffer.write(localProjectId);
    buffer.write(' vs ');
    buffer.write(foreignProjectId);
    if (isClean) {
      buffer.write(': clean (no foreign ids leaked)');
    } else {
      buffer.write(': leaked=');
      buffer.write(leakedForeignIds.join(','));
    }
    if (!isFullyContained) {
      buffer.write('; partial_local');
    }
    return buffer.toString();
  }
}

class DiagnosticExportFilter {
  const DiagnosticExportFilter._({
    required this.redactionToken,
    required this.includePublicClassification,
  });

  factory DiagnosticExportFilter.standard() {
    return const DiagnosticExportFilter._(
      redactionToken: '[REDACTED]',
      includePublicClassification: true,
    );
  }

  final String redactionToken;
  final bool includePublicClassification;

  DiagnosticSecretView project({
    required SecretDataRecord record,
    String? observerFactionId,
    String? observerCharacterId,
    bool isWriter = false,
  }) {
    final canRead = record.canObserverRead(
      observerFactionId: observerFactionId,
      observerCharacterId: observerCharacterId,
      isWriter: isWriter,
    );
    final showClassification = includePublicClassification
        ? true
        : record.classification != SecretClassification.public;
    if (!canRead) {
      return DiagnosticSecretView._(
        id: record.id,
        label: redactionToken,
        classification: showClassification ? record.classification : null,
        concealedTick: record.concealedTick,
        releasedTick: record.releasedTick,
        visible: false,
      );
    }
    return DiagnosticSecretView._(
      id: record.id,
      label: record.label,
      classification: showClassification ? record.classification : null,
      concealedTick: record.concealedTick,
      releasedTick: record.releasedTick,
      visible: true,
    );
  }

  List<DiagnosticSecretView> projectBatch(
    Iterable<SecretDataRecord> records, {
    String? observerFactionId,
    String? observerCharacterId,
    bool isWriter = false,
  }) {
    final out = <DiagnosticSecretView>[];
    for (final record in records) {
      out.add(
        project(
          record: record,
          observerFactionId: observerFactionId,
          observerCharacterId: observerCharacterId,
          isWriter: isWriter,
        ),
      );
    }
    return List<DiagnosticSecretView>.unmodifiable(out);
  }
}

class DiagnosticSecretView {
  const DiagnosticSecretView._({
    required this.id,
    required this.label,
    required this.classification,
    required this.concealedTick,
    required this.releasedTick,
    required this.visible,
  });

  final String id;
  final String label;
  final SecretClassification? classification;
  final int concealedTick;
  final int? releasedTick;
  final bool visible;
}

class ThreatFinding {
  const ThreatFinding._({
    required this.code,
    required this.severity,
    required this.summary,
    required this.affectedIds,
    required this.recommendation,
  });

  factory ThreatFinding.validated({
    required ThreatCode code,
    required int severity,
    required String summary,
    required List<String> affectedIds,
    required String recommendation,
  }) {
    if (severity < 0 || severity > 10) {
      throw ArgumentError.value(severity, 'severity', 'must be in [0,10]');
    }
    if (summary.isEmpty) {
      throw ArgumentError.value(summary, 'summary', 'must be non-empty');
    }
    if (recommendation.isEmpty) {
      throw ArgumentError.value(
        recommendation,
        'recommendation',
        'must be non-empty',
      );
    }
    return ThreatFinding._(
      code: code,
      severity: severity,
      summary: summary,
      affectedIds: List<String>.unmodifiable(affectedIds),
      recommendation: recommendation,
    );
  }

  final ThreatCode code;
  final int severity;
  final String summary;
  final List<String> affectedIds;
  final String recommendation;
}

enum ThreatCode {
  crossProjectLeak,
  unredactedSecret,
  factionSecretExposure,
  writerOnlyLeak,
  unknownOrigin,
}

class ThreatReviewReport {
  const ThreatReviewReport._({required this.findings, required this.fixStatus});

  factory ThreatReviewReport.from(Iterable<ThreatFinding> findings) {
    final list = findings.toList()
      ..sort((a, b) {
        final bySeverity = b.severity.compareTo(a.severity);
        if (bySeverity != 0) return bySeverity;
        return a.code.index.compareTo(b.code.index);
      });
    final hasCritical = list.any((f) => f.severity >= 8);
    return ThreatReviewReport._(
      findings: List<ThreatFinding>.unmodifiable(list),
      fixStatus: hasCritical ? FixStatus.actionRequired : FixStatus.acceptable,
    );
  }

  final List<ThreatFinding> findings;
  final FixStatus fixStatus;

  bool get isClean => findings.isEmpty;
  bool get requiresAction => fixStatus == FixStatus.actionRequired;

  String explain() {
    final buffer = StringBuffer('threat_review: ');
    buffer.write(findings.length);
    buffer.write(' findings; status=');
    buffer.write(fixStatus.name);
    return buffer.toString();
  }
}

enum FixStatus { clean, acceptable, actionRequired }
