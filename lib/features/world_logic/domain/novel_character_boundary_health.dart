/// Novel-character boundary health contract for Sprint 114.13.
///
/// Dependency-free model that checks whether the Novel and Character
/// workspaces stay separate after migration, link, unlink, delete,
/// backup, restore, and export across the seven canonical signals:
/// distinct_namespaces, reference_integrity, override_isolation,
/// unlink_safety, delete_safety, permission_boundary, and
/// restore_results. An absent observation set stays BLOCKED without
/// health claims. Live boundary telemetry over production workspaces,
/// destructive fault tests on user data, hardware verification, and
/// public distribution remain external gates and are not claimed here.
enum NovelCharacterBoundarySignal {
  distinctNamespaces,
  referenceIntegrity,
  overrideIsolation,
  unlinkSafety,
  deleteSafety,
  permissionBoundary,
  restoreResults,
}

enum NovelCharacterBoundaryOutcome { ok, failed, recovered }

enum NovelCharacterBoundaryState { pass, fail, blocked }

class NovelCharacterBoundaryObservation {
  const NovelCharacterBoundaryObservation({
    required this.signal,
    required this.outcome,
    required this.note,
  });

  final NovelCharacterBoundarySignal signal;
  final NovelCharacterBoundaryOutcome outcome;
  final String note;
}

class NovelCharacterBoundaryReport {
  const NovelCharacterBoundaryReport({
    required this.state,
    required this.observations,
    required this.coveredSignals,
    required this.invalidFields,
    required this.violations,
    required this.notes,
  });

  final NovelCharacterBoundaryState state;
  final List<NovelCharacterBoundaryObservation> observations;
  final List<NovelCharacterBoundarySignal> coveredSignals;
  final List<String> invalidFields;
  final List<String> violations;
  final List<String> notes;
}

class NovelCharacterBoundaryHealth {
  static const List<NovelCharacterBoundarySignal> canonicalSignals =
      <NovelCharacterBoundarySignal>[
        NovelCharacterBoundarySignal.distinctNamespaces,
        NovelCharacterBoundarySignal.referenceIntegrity,
        NovelCharacterBoundarySignal.overrideIsolation,
        NovelCharacterBoundarySignal.unlinkSafety,
        NovelCharacterBoundarySignal.deleteSafety,
        NovelCharacterBoundarySignal.permissionBoundary,
        NovelCharacterBoundarySignal.restoreResults,
      ];

  NovelCharacterBoundaryReport evaluate(
    List<NovelCharacterBoundaryObservation>? observations,
  ) {
    if (observations == null || observations.isEmpty) {
      return const NovelCharacterBoundaryReport(
        state: NovelCharacterBoundaryState.blocked,
        observations: <NovelCharacterBoundaryObservation>[],
        coveredSignals: <NovelCharacterBoundarySignal>[],
        invalidFields: <String>[],
        violations: <String>[],
        notes: <String>[
          'Belum ada observasi batas Novel/Character; tidak ada klaim '
              'kesehatan; live boundary telemetry DEFERRED-EXTERNAL.',
        ],
      );
    }

    final covered = <NovelCharacterBoundarySignal>{
      for (final observation in observations) observation.signal,
    };
    final invalid = <String>[];
    if (covered.length != canonicalSignals.length ||
        !canonicalSignals.every(covered.contains)) {
      invalid.add('signals');
    }
    if (observations.any((o) => o.note.trim().isEmpty)) {
      invalid.add('notes');
    }

    bool hasOutcome(
      NovelCharacterBoundarySignal signal,
      NovelCharacterBoundaryOutcome outcome,
    ) => observations.any((o) => o.signal == signal && o.outcome == outcome);

    bool failed(NovelCharacterBoundarySignal signal) =>
        hasOutcome(signal, NovelCharacterBoundaryOutcome.failed);

    final restoreFailed = failed(NovelCharacterBoundarySignal.restoreResults);
    final violations = <String>[];
    if (failed(NovelCharacterBoundarySignal.distinctNamespaces) &&
        restoreFailed) {
      violations.add('namespaces_unrecovered');
    }
    if (failed(NovelCharacterBoundarySignal.unlinkSafety) &&
        failed(NovelCharacterBoundarySignal.referenceIntegrity)) {
      violations.add('unlink_broke_references');
    }
    if (failed(NovelCharacterBoundarySignal.referenceIntegrity) &&
        restoreFailed) {
      violations.add('references_unrepaired');
    }
    if (failed(NovelCharacterBoundarySignal.deleteSafety) && restoreFailed) {
      violations.add('delete_unrecovered');
    }
    if (failed(NovelCharacterBoundarySignal.overrideIsolation) &&
        failed(NovelCharacterBoundarySignal.permissionBoundary)) {
      violations.add('override_leak_uncontained');
    }
    if (failed(NovelCharacterBoundarySignal.permissionBoundary) &&
        restoreFailed) {
      violations.add('permission_breach_unrepaired');
    }

    return NovelCharacterBoundaryReport(
      state: invalid.isEmpty && violations.isEmpty
          ? NovelCharacterBoundaryState.pass
          : NovelCharacterBoundaryState.fail,
      observations: List<NovelCharacterBoundaryObservation>.unmodifiable(
        observations,
      ),
      coveredSignals: List<NovelCharacterBoundarySignal>.unmodifiable(
        canonicalSignals.where(covered.contains),
      ),
      invalidFields: List<String>.unmodifiable(invalid.toSet()),
      violations: List<String>.unmodifiable(violations),
      notes: const <String>[
        'Verifikasi kontrak lokal atas tujuh sinyal batas '
            'Novel/Character; live boundary telemetry, fault test '
            'destruktif atas data pengguna, verifikasi perangkat keras, '
            'dan publikasi distribusi DEFERRED-EXTERNAL.',
      ],
    );
  }
}
