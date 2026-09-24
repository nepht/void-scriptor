/// Fail-closed maintenance artifact and release evidence contract for Sprint
/// 114.40.
library;

enum MaintenanceArtifactReleaseState { pass, fail, blocked }

enum MaintenanceArtifactReleaseDisposition { build121, noPatch }

enum MaintenanceArtifactEvidenceStatus { verifiedLocal, notApplicable, failed }

class MaintenanceArtifactEvidenceItem {
  const MaintenanceArtifactEvidenceItem({
    required this.key,
    required this.status,
    required this.source,
  });

  final String key;
  final MaintenanceArtifactEvidenceStatus status;
  final String source;
}

class MaintenanceArtifactReleaseEvidence {
  const MaintenanceArtifactReleaseEvidence({
    required this.disposition,
    required this.evidence,
  });

  final MaintenanceArtifactReleaseDisposition disposition;
  final List<MaintenanceArtifactEvidenceItem> evidence;
}

class MaintenanceArtifactReleaseReport {
  const MaintenanceArtifactReleaseReport({
    required this.state,
    required this.disposition,
    required this.missingEvidence,
    required this.violations,
    required this.artifactRequired,
    required this.externalGates,
    required this.deferredChecks,
  });

  final MaintenanceArtifactReleaseState state;
  final MaintenanceArtifactReleaseDisposition? disposition;
  final List<String> missingEvidence;
  final List<String> violations;
  final bool artifactRequired;
  final String externalGates;
  final List<String> deferredChecks;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'state': state.name,
      'disposition': disposition?.name,
      'required_evidence': List<String>.from(
        MaintenanceArtifactReleaseContract.requiredEvidence,
      ),
      'missing_evidence': List<String>.from(missingEvidence),
      'violations': List<String>.from(violations),
      'artifact_required': artifactRequired,
      'external_gates': externalGates,
      'deferred_checks': List<String>.from(deferredChecks),
    };
  }
}

abstract final class MaintenanceArtifactReleaseContract {
  static const String canonicalStep = '114.40';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_114_maintenance_artifact_release_gate.json';
  static const String noPatchDecisionSource =
      'docs/planning/v1.2/sprint_114_maintenance_release_scope.json';

  static const List<String> requiredEvidence = <String>[
    'approved_scope_or_no_patch',
    'signed_artifact_if_needed',
    'test_results',
    'upgrade_results',
    'rollback_results',
    'checksums',
    'release_notes',
  ];

  static const Set<String> noPatchArtifactOnlyEvidence = <String>{
    'signed_artifact_if_needed',
    'upgrade_results',
    'rollback_results',
    'checksums',
    'release_notes',
  };

  static const List<String> deferredExternalChecks = <String>[
    'public_release_signing',
    'hosted_ci_validation',
    'published_artifact_validation',
    'release_notes_publication',
    'publication',
  ];
}

class MaintenanceArtifactReleaseGate {
  MaintenanceArtifactReleaseReport evaluate(
    MaintenanceArtifactReleaseEvidence? evidence,
  ) {
    if (evidence == null) {
      return _report(
        state: MaintenanceArtifactReleaseState.blocked,
        disposition: null,
        missingEvidence: MaintenanceArtifactReleaseContract.requiredEvidence,
        violations: const <String>[],
        artifactRequired: false,
      );
    }

    final violations = <String>[];
    final missing = <String>[];
    final indexedEvidence = <String, MaintenanceArtifactEvidenceItem>{};
    final itemIndexes = <String, int>{};

    for (var index = 0; index < evidence.evidence.length; index += 1) {
      final item = evidence.evidence[index];
      final prefix = 'evidence_${index}_';
      if (!MaintenanceArtifactReleaseContract.requiredEvidence.contains(
        item.key,
      )) {
        violations.add('${prefix}unknown_${item.key}');
      } else if (indexedEvidence.containsKey(item.key)) {
        violations.add('${prefix}duplicate_${item.key}');
      } else {
        indexedEvidence[item.key] = item;
        itemIndexes[item.key] = index;
      }
      if (item.source.trim().isEmpty) {
        violations.add('$prefix${item.key}_missing_source');
      }
    }

    for (final key in MaintenanceArtifactReleaseContract.requiredEvidence) {
      if (!indexedEvidence.containsKey(key)) {
        missing.add(key);
      }
    }

    MaintenanceArtifactEvidenceItem? itemFor(String key) =>
        indexedEvidence[key];

    void requireVerified(String key, {required String source}) {
      final item = itemFor(key);
      if (item == null ||
          item.status != MaintenanceArtifactEvidenceStatus.verifiedLocal ||
          item.source.trim() != source) {
        violations.add('${key}_requires_verified_local_source');
      }
    }

    switch (evidence.disposition) {
      case MaintenanceArtifactReleaseDisposition.noPatch:
        requireVerified(
          'approved_scope_or_no_patch',
          source: MaintenanceArtifactReleaseContract.noPatchDecisionSource,
        );
        requireVerified('test_results', source: 'current_slice_local_gates');
        for (final key
            in MaintenanceArtifactReleaseContract.noPatchArtifactOnlyEvidence) {
          final item = itemFor(key);
          if (item == null) {
            continue;
          }
          if (item.status == MaintenanceArtifactEvidenceStatus.verifiedLocal) {
            violations.add('no_patch_with_artifact_evidence');
          } else if (item.status !=
              MaintenanceArtifactEvidenceStatus.notApplicable) {
            violations.add('${itemIndexes[key]}_$key}_${item.status.name}');
          }
        }
      case MaintenanceArtifactReleaseDisposition.build121:
        for (final key in MaintenanceArtifactReleaseContract.requiredEvidence) {
          final item = itemFor(key);
          if (item == null) {
            continue;
          }
          if (item.status != MaintenanceArtifactEvidenceStatus.verifiedLocal) {
            violations.add(
              'evidence_${itemIndexes[key]}_${key}_${item.status.name}',
            );
          }
        }
    }

    final state = missing.isNotEmpty
        ? MaintenanceArtifactReleaseState.blocked
        : violations.isNotEmpty
        ? MaintenanceArtifactReleaseState.fail
        : MaintenanceArtifactReleaseState.pass;

    return _report(
      state: state,
      disposition: evidence.disposition,
      missingEvidence: missing,
      violations: violations,
      artifactRequired:
          evidence.disposition ==
          MaintenanceArtifactReleaseDisposition.build121,
    );
  }

  MaintenanceArtifactReleaseReport _report({
    required MaintenanceArtifactReleaseState state,
    required MaintenanceArtifactReleaseDisposition? disposition,
    required List<String> missingEvidence,
    required List<String> violations,
    required bool artifactRequired,
  }) {
    return MaintenanceArtifactReleaseReport(
      state: state,
      disposition: disposition,
      missingEvidence: List<String>.unmodifiable(missingEvidence),
      violations: List<String>.unmodifiable(violations),
      artifactRequired: artifactRequired,
      externalGates: 'DEFERRED-EXTERNAL',
      deferredChecks: List<String>.unmodifiable(
        MaintenanceArtifactReleaseContract.deferredExternalChecks,
      ),
    );
  }
}
