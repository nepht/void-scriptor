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

  double get utilization => baselineMb / budgetMb;
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
