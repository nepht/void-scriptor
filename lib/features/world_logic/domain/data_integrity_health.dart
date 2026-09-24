/// Data integrity health contract for Sprint 114.12.
///
/// Dependency-free model that checks stable IDs, links, indexes,
/// aliases, timelines, checksums, and no-silent-loss reports across
/// the six canonical signals: broken_links, orphan_records,
/// index_mismatch, checksum_failure, silent_loss_report, and
/// repair_success. An absent observation set stays BLOCKED without
/// health claims. Live production integrity scans, end-to-end repair
/// over real user data, hardware verification, and public
/// distribution remain external gates and are not claimed here.
enum DataIntegritySignal {
  brokenLinks,
  orphanRecords,
  indexMismatch,
  checksumFailure,
  silentLossReport,
  repairSuccess,
}

enum DataIntegrityOutcome { ok, failed, recovered }

enum DataIntegrityHealthState { pass, fail, blocked }

class DataIntegrityObservation {
  const DataIntegrityObservation({
    required this.signal,
    required this.outcome,
    required this.note,
  });

  final DataIntegritySignal signal;
  final DataIntegrityOutcome outcome;
  final String note;
}

class DataIntegrityHealthReport {
  const DataIntegrityHealthReport({
    required this.state,
    required this.observations,
    required this.coveredSignals,
    required this.invalidFields,
    required this.violations,
    required this.notes,
  });

  final DataIntegrityHealthState state;
  final List<DataIntegrityObservation> observations;
  final List<DataIntegritySignal> coveredSignals;
  final List<String> invalidFields;
  final List<String> violations;
  final List<String> notes;
}

class DataIntegrityHealth {
  static const List<DataIntegritySignal> canonicalSignals =
      <DataIntegritySignal>[
        DataIntegritySignal.brokenLinks,
        DataIntegritySignal.orphanRecords,
        DataIntegritySignal.indexMismatch,
        DataIntegritySignal.checksumFailure,
        DataIntegritySignal.silentLossReport,
        DataIntegritySignal.repairSuccess,
      ];

  DataIntegrityHealthReport evaluate(
    List<DataIntegrityObservation>? observations,
  ) {
    if (observations == null || observations.isEmpty) {
      return const DataIntegrityHealthReport(
        state: DataIntegrityHealthState.blocked,
        observations: <DataIntegrityObservation>[],
        coveredSignals: <DataIntegritySignal>[],
        invalidFields: <String>[],
        violations: <String>[],
        notes: <String>[
          'Belum ada observasi integritas data; tidak ada klaim kesehatan; '
              'live integrity telemetry DEFERRED-EXTERNAL.',
        ],
      );
    }

    final covered = <DataIntegritySignal>{
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

    bool hasOutcome(DataIntegritySignal signal, DataIntegrityOutcome outcome) =>
        observations.any((o) => o.signal == signal && o.outcome == outcome);

    final repairFailed = hasOutcome(
      DataIntegritySignal.repairSuccess,
      DataIntegrityOutcome.failed,
    );
    final violations = <String>[];
    if (hasOutcome(
          DataIntegritySignal.brokenLinks,
          DataIntegrityOutcome.failed,
        ) &&
        repairFailed) {
      violations.add('broken_links_unrepaired');
    }
    if (hasOutcome(
          DataIntegritySignal.orphanRecords,
          DataIntegrityOutcome.failed,
        ) &&
        repairFailed) {
      violations.add('orphan_records_unrepaired');
    }
    if (hasOutcome(
          DataIntegritySignal.indexMismatch,
          DataIntegrityOutcome.failed,
        ) &&
        repairFailed) {
      violations.add('index_mismatch_unrepaired');
    }
    if (hasOutcome(
          DataIntegritySignal.checksumFailure,
          DataIntegrityOutcome.failed,
        ) &&
        repairFailed) {
      violations.add('checksum_unrepaired');
    }
    if (hasOutcome(
          DataIntegritySignal.silentLossReport,
          DataIntegrityOutcome.failed,
        ) &&
        repairFailed) {
      violations.add('silent_loss_unrepaired');
    }

    return DataIntegrityHealthReport(
      state: invalid.isEmpty && violations.isEmpty
          ? DataIntegrityHealthState.pass
          : DataIntegrityHealthState.fail,
      observations: List<DataIntegrityObservation>.unmodifiable(observations),
      coveredSignals: List<DataIntegritySignal>.unmodifiable(
        canonicalSignals.where(covered.contains),
      ),
      invalidFields: List<String>.unmodifiable(invalid.toSet()),
      violations: List<String>.unmodifiable(violations),
      notes: const <String>[
        'Verifikasi kontrak lokal atas enam sinyal integritas data; '
            'scan integritas produksi live, repair data pengguna '
            'end-to-end, verifikasi perangkat keras, dan publikasi '
            'distribusi DEFERRED-EXTERNAL.',
      ],
    );
  }
}
