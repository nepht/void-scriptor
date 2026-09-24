/// Fail-closed evidence report contract for Sprint 114.41.
library;

enum PostReleaseEvidenceReportState { pass, fail, blocked }

enum PostReleaseEvidenceStatus { verifiedLocal, deferredExternal }

class PostReleaseEvidenceSection {
  const PostReleaseEvidenceSection({
    required this.status,
    required this.evidence,
    required this.summary,
  });

  final PostReleaseEvidenceStatus status;
  final List<String> evidence;
  final String summary;

  PostReleaseEvidenceSection copyWith({
    PostReleaseEvidenceStatus? status,
    List<String>? evidence,
    String? summary,
  }) {
    return PostReleaseEvidenceSection(
      status: status ?? this.status,
      evidence: evidence ?? this.evidence,
      summary: summary ?? this.summary,
    );
  }
}

class PostReleaseEvidenceReportDraft {
  PostReleaseEvidenceReportDraft({
    required this.releaseState,
    required Map<String, PostReleaseEvidenceSection> sections,
    List<String> sectionNames = const <String>[],
  }) : sections = Map<String, PostReleaseEvidenceSection>.unmodifiable(
         Map<String, PostReleaseEvidenceSection>.from(sections),
       ),
       sectionNames = List<String>.unmodifiable(sectionNames);

  final String releaseState;
  final List<String> sectionNames;
  final Map<String, PostReleaseEvidenceSection> sections;
}

class PostReleaseEvidenceReport {
  const PostReleaseEvidenceReport({
    required this.state,
    required this.releaseState,
    required this.missingSections,
    required this.violations,
  });

  final PostReleaseEvidenceReportState state;
  final String? releaseState;
  final List<String> missingSections;
  final List<String> violations;
  final String externalGates = 'DEFERRED-EXTERNAL';

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'state': state.name,
      'release_state': releaseState,
      'required_sections': List<String>.from(
        PostReleaseEvidenceReportContract.requiredSections,
      ),
      'missing_sections': List<String>.from(missingSections),
      'violations': List<String>.from(violations),
      'external_gates': externalGates,
    };
  }
}

abstract final class PostReleaseEvidenceReportContract {
  static const String canonicalStep = '114.41';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_114_post_release_evidence_report.json';

  static const List<String> requiredSections = <String>[
    'release_state',
    'health',
    'incidents',
    'adoption_evidence',
    'limitations',
    'fixes',
    'rollout',
    'patch_decision',
  ];

  static const Set<String> releaseStates = <String>{
    'RELEASED',
    'DELAYED',
    'ROLLED_BACK',
  };

  static const Set<String> delayedRestrictedSections = <String>{
    'health',
    'incidents',
    'adoption_evidence',
    'rollout',
  };
}

class PostReleaseEvidenceReportGate {
  PostReleaseEvidenceReport evaluate(PostReleaseEvidenceReportDraft? draft) {
    if (draft == null) {
      return const PostReleaseEvidenceReport(
        state: PostReleaseEvidenceReportState.blocked,
        releaseState: null,
        missingSections: PostReleaseEvidenceReportContract.requiredSections,
        violations: <String>[],
      );
    }

    final missing = <String>[];
    final violations = <String>[];
    final seenSections = <String>{};
    for (var index = 0; index < draft.sectionNames.length; index += 1) {
      final name = draft.sectionNames[index];
      if (!PostReleaseEvidenceReportContract.requiredSections.contains(name)) {
        violations.add('unknown_$name');
      } else if (!seenSections.add(name)) {
        violations.add('duplicate_$name');
      }
    }
    final releaseState = draft.releaseState.trim();
    if (!PostReleaseEvidenceReportContract.releaseStates.contains(
      releaseState,
    )) {
      violations.add('unsupported_release_state_$releaseState');
    }

    for (final name in PostReleaseEvidenceReportContract.requiredSections) {
      final section = draft.sections[name];
      if (section == null) {
        missing.add(name);
        continue;
      }

      final hasEvidence =
          section.evidence.isNotEmpty &&
          section.evidence.every((item) => item.trim().isNotEmpty);
      if (!hasEvidence) {
        violations.add('${name}_evidence_missing');
      }
      if (section.summary.trim().isEmpty) {
        violations.add('${name}_summary_missing');
      }
      if (section.status == PostReleaseEvidenceStatus.deferredExternal &&
          !hasEvidence) {
        violations.add('${name}_deferred_external_requires_evidence');
      }
    }

    for (final name in draft.sections.keys) {
      if (!PostReleaseEvidenceReportContract.requiredSections.contains(name)) {
        violations.add('unknown_$name');
      }
    }

    if (releaseState == 'DELAYED') {
      for (final name
          in PostReleaseEvidenceReportContract.delayedRestrictedSections) {
        final section = draft.sections[name];
        if (section?.status == PostReleaseEvidenceStatus.verifiedLocal) {
          violations.add('delayed_release_cannot_verify_$name');
        }
      }
    }

    final state = missing.isNotEmpty
        ? PostReleaseEvidenceReportState.blocked
        : violations.isNotEmpty
        ? PostReleaseEvidenceReportState.fail
        : PostReleaseEvidenceReportState.pass;

    return PostReleaseEvidenceReport(
      state: state,
      releaseState: releaseState.isEmpty ? null : releaseState,
      missingSections: List<String>.unmodifiable(missing),
      violations: List<String>.unmodifiable(violations),
    );
  }
}
