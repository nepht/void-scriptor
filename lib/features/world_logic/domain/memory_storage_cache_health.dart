/// Memory, storage, and cache health contract for Sprint 114.17.
///
/// Dependency-free model that compares memory pressure, storage growth,
/// snapshot retention growth, cache pressure, temp artifact growth, and
/// search index growth against the frozen budgets across the six canonical
/// signals: memory_pressure, storage_growth, snapshot_growth,
/// cache_pressure, temp_growth, and index_growth. `cache_pressure` is the
/// root recovery signal: cache eviction and reclaim must honestly recover
/// before a failed growth or pressure signal counts as resolved. An absent
/// observation set stays BLOCKED without health claims. Live resource
/// telemetry on production hardware, native memory profiling, real disk
/// measurement, and public distribution remain external gates and are not
/// claimed here.
enum MemorySignal {
  memoryPressure,
  storageGrowth,
  snapshotGrowth,
  cachePressure,
  tempGrowth,
  indexGrowth,
}

enum MemoryOutcome { ok, failed, recovered }

enum MemoryStorageState { pass, fail, blocked }

class MemoryObservation {
  const MemoryObservation({
    required this.signal,
    required this.outcome,
    required this.note,
  });

  final MemorySignal signal;
  final MemoryOutcome outcome;
  final String note;
}

class MemoryStorageReport {
  const MemoryStorageReport({
    required this.state,
    required this.observations,
    required this.coveredSignals,
    required this.invalidFields,
    required this.violations,
    required this.notes,
  });

  final MemoryStorageState state;
  final List<MemoryObservation> observations;
  final List<MemorySignal> coveredSignals;
  final List<String> invalidFields;
  final List<String> violations;
  final List<String> notes;
}

class MemoryStorageCacheHealth {
  static const List<MemorySignal> canonicalSignals = <MemorySignal>[
    MemorySignal.memoryPressure,
    MemorySignal.storageGrowth,
    MemorySignal.snapshotGrowth,
    MemorySignal.cachePressure,
    MemorySignal.tempGrowth,
    MemorySignal.indexGrowth,
  ];

  MemoryStorageReport evaluate(List<MemoryObservation>? observations) {
    if (observations == null || observations.isEmpty) {
      return const MemoryStorageReport(
        state: MemoryStorageState.blocked,
        observations: <MemoryObservation>[],
        coveredSignals: <MemorySignal>[],
        invalidFields: <String>[],
        violations: <String>[],
        notes: <String>[
          'Belum ada observasi memori/penyimpanan/cache; tidak ada klaim '
              'kesehatan; live resource telemetry DEFERRED-EXTERNAL.',
        ],
      );
    }

    final covered = <MemorySignal>{
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

    // Aturan lintas-sinyal hanya dinilai saat cakupan lengkap; cakupan
    // belum lengkap sudah gagal lewat invalidasi `signals`.
    final violations = <String>[];
    if (invalid.isEmpty) {
      MemoryOutcome outcomeOf(MemorySignal signal) =>
          observations.firstWhere((o) => o.signal == signal).outcome;

      final cacheOutcome = outcomeOf(MemorySignal.cachePressure);
      final cacheFailed = cacheOutcome == MemoryOutcome.failed;
      final cacheRecovered = cacheOutcome == MemoryOutcome.recovered;

      const pressureGrowthSignals = <MemorySignal, String>{
        MemorySignal.memoryPressure: 'memory_pressure',
        MemorySignal.storageGrowth: 'storage_growth',
        MemorySignal.snapshotGrowth: 'snapshot_growth',
        MemorySignal.tempGrowth: 'temp_growth',
        MemorySignal.indexGrowth: 'index_growth',
      };

      var anyPressureGrowthOk = false;
      for (final entry in pressureGrowthSignals.entries) {
        final outcome = outcomeOf(entry.key);
        if (outcome == MemoryOutcome.ok) {
          anyPressureGrowthOk = true;
        }
        if (outcome == MemoryOutcome.failed && !cacheRecovered) {
          violations.add('${entry.value}_unrecovered');
        }
      }
      if (cacheFailed && anyPressureGrowthOk) {
        violations.add('cache_pressure_ignored');
      }
    }

    return MemoryStorageReport(
      state: invalid.isEmpty && violations.isEmpty
          ? MemoryStorageState.pass
          : MemoryStorageState.fail,
      observations: List<MemoryObservation>.unmodifiable(observations),
      coveredSignals: List<MemorySignal>.unmodifiable(
        canonicalSignals.where(covered.contains),
      ),
      invalidFields: List<String>.unmodifiable(invalid.toSet()),
      violations: List<String>.unmodifiable(violations.toSet()),
      notes: const <String>[
        'Verifikasi kontrak lokal atas enam sinyal memori/penyimpanan/cache; '
            'profil memori native, pengukuran disk nyata, dan publikasi '
            'distribusi DEFERRED-EXTERNAL.',
      ],
    );
  }
}
