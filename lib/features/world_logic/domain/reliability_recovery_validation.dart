/// Reliability & Recovery Validation (Step 113.24).
///
/// Domain contract for the seven canonical failure cases — autosave, crash
/// recovery, disk full, permission loss, power loss, missing media, and
/// corrupt index — plus data-loss, recovery, repair, and user-guidance
/// evidence and the resulting pass/fail/blocked decision.
///
/// The domain stays dependency-free: the test drives the real subsystems
/// (durable draft journal, autosave coordinator, restore crash recovery,
/// corruption detection/recovery, file reference resolution) and records
/// their observed behavior here. Real power-loss, full-volume, and ACL
/// fault injection are out of scope (see manifest limits).
library;

/// Canonical failure cases covered by step 113.24.
enum ReliabilityFailureCase {
  autosave,
  crashRecovery,
  diskFull,
  permissionLoss,
  powerLoss,
  missingMedia,
  corruptIndex;

  static const List<ReliabilityFailureCase> all = [
    ReliabilityFailureCase.autosave,
    ReliabilityFailureCase.crashRecovery,
    ReliabilityFailureCase.diskFull,
    ReliabilityFailureCase.permissionLoss,
    ReliabilityFailureCase.powerLoss,
    ReliabilityFailureCase.missingMedia,
    ReliabilityFailureCase.corruptIndex,
  ];
}

/// Outcome of exercising one failure case.
class FailureCaseResult {
  const FailureCaseResult({
    required this.failureCase,
    required this.expectedBehavior,
    required this.observedBehavior,
    required this.passed,
  });

  final ReliabilityFailureCase failureCase;
  final String expectedBehavior;
  final String observedBehavior;
  final bool passed;
}

/// No-silent-loss evidence for one case.
class DataLossResult {
  const DataLossResult({
    required this.failureCase,
    required this.contentPreserved,
    required this.detail,
  });

  final ReliabilityFailureCase failureCase;

  /// True when the durable copy of the user's content survived the failure.
  final bool contentPreserved;
  final String detail;
}

/// Recovery evidence for one case.
class RecoveryResult {
  const RecoveryResult({
    required this.failureCase,
    required this.recovered,
    required this.detail,
  });

  final ReliabilityFailureCase failureCase;
  final bool recovered;
  final String detail;
}

/// Repair evidence for one case.
class RepairResult {
  const RepairResult({
    required this.failureCase,
    required this.repaired,
    required this.backupCreated,
    required this.detail,
  });

  final ReliabilityFailureCase failureCase;
  final bool repaired;

  /// A pre-repair backup exists so the repair is reversible.
  final bool backupCreated;
  final String detail;
}

/// Actionable guidance shown to the user for one failure case.
class FailureGuidance {
  const FailureGuidance({
    required this.failureCase,
    required this.action,
    required this.detail,
  });

  final ReliabilityFailureCase failureCase;

  /// Short imperative action (non-empty).
  final String action;
  final String detail;
}

/// Validation decision.
enum ReliabilityDecision { pass, fail, blocked }

/// Aggregated report for the validation window.
class ReliabilityRecoveryReport {
  const ReliabilityRecoveryReport({
    required this.failureCases,
    required this.dataLossResults,
    required this.recoveryResults,
    required this.repairResults,
    required this.guidance,
  });

  final List<FailureCaseResult> failureCases;
  final List<DataLossResult> dataLossResults;
  final List<RecoveryResult> recoveryResults;
  final List<RepairResult> repairResults;
  final List<FailureGuidance> guidance;

  ReliabilityDecision get decision {
    if (failureCases.isEmpty) return ReliabilityDecision.blocked;
    final allCasesCovered =
        failureCases.length == ReliabilityFailureCase.all.length;
    final anyCaseFailed = failureCases.any((result) => !result.passed);
    final anyDataLoss = dataLossResults.any(
      (result) => !result.contentPreserved,
    );
    final anyRecoveryFailed = recoveryResults.any(
      (result) => !result.recovered,
    );
    final anyRepairFailed = repairResults.any(
      (result) => !result.repaired || !result.backupCreated,
    );
    if (!allCasesCovered ||
        anyCaseFailed ||
        anyDataLoss ||
        anyRecoveryFailed ||
        anyRepairFailed) {
      return ReliabilityDecision.fail;
    }
    return ReliabilityDecision.pass;
  }
}

/// Builder that records evidence per failure case and produces the report.
class ReliabilityRecoveryValidator {
  final Map<ReliabilityFailureCase, FailureCaseResult> _cases = {};
  final Map<ReliabilityFailureCase, DataLossResult> _dataLoss = {};
  final Map<ReliabilityFailureCase, RecoveryResult> _recovery = {};
  final Map<ReliabilityFailureCase, RepairResult> _repair = {};

  void recordFailureCase(FailureCaseResult result) =>
      _cases[result.failureCase] = result;

  void recordDataLoss(DataLossResult result) =>
      _dataLoss[result.failureCase] = result;

  void recordRecovery(RecoveryResult result) =>
      _recovery[result.failureCase] = result;

  void recordRepair(RepairResult result) =>
      _repair[result.failureCase] = result;

  List<FailureCaseResult> get failureCases => [
    for (final failureCase in ReliabilityFailureCase.all)
      if (_cases.containsKey(failureCase)) _cases[failureCase]!,
  ];

  /// Canonical user guidance for every failure case. Guidance is owned by
  /// the domain so wording stays consistent across surfaces.
  List<FailureGuidance> get guidance => [
    const FailureGuidance(
      failureCase: ReliabilityFailureCase.autosave,
      action: 'Gunakan panel DRAFT RECOVERY untuk memulihkan draf tertunda',
      detail:
          'Kegagalan persist tidak menghapus entri journal; retry terjadi '
          'pada suntingan atau save berikutnya.',
    ),
    const FailureGuidance(
      failureCase: ReliabilityFailureCase.crashRecovery,
      action: 'Biarkan aplikasi menyelesaikan pemulihan saat dibuka kembali',
      detail:
          'Artefak staging jendela crash dibersihkan atau di-roll-forward '
          'otomatis sebelum payload disentuh.',
    ),
    const FailureGuidance(
      failureCase: ReliabilityFailureCase.diskFull,
      action: 'osongkan ruang disk lalu tekan Save kembali',
      detail:
          'Draf tetap pending di journal sampai persist berhasil; tidak '
          'ada suntingan yang hilang selama kegagalan.',
    ),
    const FailureGuidance(
      failureCase: ReliabilityFailureCase.permissionLoss,
      action: 'Periksa izin folder proyek dan pulihkan akses tulis',
      detail:
          'Permintaan tulis yang ditolak dilaporkan sebagai error terlihat, '
          'bukan gagal diam-diam.',
    ),
    const FailureGuidance(
      failureCase: ReliabilityFailureCase.powerLoss,
      action: 'Buka kembali proyek; entri journal terpotong ditandai KORUP',
      detail:
          'Entri korup disurface agar Anda tahu draf pernah ada; salinan '
          'yang utuh tetap dapat dipulihkan.',
    ),
    const FailureGuidance(
      failureCase: ReliabilityFailureCase.missingMedia,
      action: 'Tautkan ulang file media yang hilang dari Assets',
      detail:
          'Referensi yang hilang terdeteksi saat scan integritas dan tidak '
          'dihapus otomatis.',
    ),
    const FailureGuidance(
      failureCase: ReliabilityFailureCase.corruptIndex,
      action: 'Jalankan repair dari dialog integritas proyek',
      detail:
          'Backup pra-repair dibuat lebih dulu, orfan dikarantina ke trash, '
          'index disinkronkan ulang.',
    ),
  ];

  ReliabilityRecoveryReport report() => ReliabilityRecoveryReport(
    failureCases: failureCases,
    dataLossResults: [
      for (final failureCase in ReliabilityFailureCase.all)
        if (_dataLoss.containsKey(failureCase)) _dataLoss[failureCase]!,
    ],
    recoveryResults: [
      for (final failureCase in ReliabilityFailureCase.all)
        if (_recovery.containsKey(failureCase)) _recovery[failureCase]!,
    ],
    repairResults: [
      for (final failureCase in ReliabilityFailureCase.all)
        if (_repair.containsKey(failureCase)) _repair[failureCase]!,
    ],
    guidance: guidance,
  );
}
