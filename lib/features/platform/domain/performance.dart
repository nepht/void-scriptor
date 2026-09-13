/// Sprint 50 — Step 50.82–50.86 Startup Target, Memory Baseline, Storage Manager.
class StartupTarget {
  const StartupTarget({
    required this.id,
    required this.targetMs,
    this.measuredMs,
  });

  final String id;
  final int targetMs;
  final int? measuredMs;

  bool get met => measuredMs != null && measuredMs! <= targetMs;
}

class MemoryBaseline {
  const MemoryBaseline({required this.baselineMb, required this.budgetMb});

  final int baselineMb;
  final int budgetMb;

  /// Rasio pemakaian terhadap budget.
  ///
  /// Budget non-positif bukan pembagian yang sah: tanpa penjaga, `0/0`
  /// menjadi NaN dan `baseline/0` menjadi Infinity (vs-hunt-20260914-platform
  /// PLAT-BUG-06). Konfigurasi tanpa budget dilaporkan sebagai 0.0 supaya
  /// pemakai laporan selalu mendapat angka berhingga; [withinBudget] tetap
  /// menjadi pemeriksaan kapasitas yang sebenarnya.
  double get utilization => budgetMb <= 0 ? 0.0 : baselineMb / budgetMb;
  bool get withinBudget => baselineMb <= budgetMb;
}

class StorageManager {
  const StorageManager({
    required this.id,
    required this.totalBytes,
    required this.cacheBytes,
  });

  final String id;
  final int totalBytes;
  final int cacheBytes;

  int get reclaimableBytes => cacheBytes;
}
