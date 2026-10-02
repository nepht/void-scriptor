// Copyright 2026 Choirudin. All rights reserved.
//
// Sprint 117.35 — Performance & Scale Validation.
//
// Fail-closed gate: menguji 8 bukti kanonik (render, many_accounts, refresh,
// charts, local_scan, slow_api, memory, contention) sebagai kondisi TERUKUR
// terhadap seam yang benar-benar di-ship, bukan terhadap deklarasi. Setiap area
// yang tidak punya check = missing_area. Area yang punya check tapi hanya status
// "pass" tanpa predikat terukur = vacuous. Area yang membawa satu violation
// sekalipun tidak bisa diabaikan = area_without_pass. Area yang tidak dideklarasikan
// = unknown_area. Setiap check yang terulang = duplicate_check.
//
// Anchor kontrak:
// 115.53 (AccountCenterPerformanceResilience): render_budget, refresh_budget,
// slow_api_results, rate_limit_results, outage_results, many_accounts_results,
// scan_results, chartPalette, connectionLabel.
// 115.20 (performance), 115.21 (render 60fps), 115.22 (concurrent refresh),
// 115.23 (local scan), 115.24 (slow provider).
// 117.12-117.34 (slice integrity pattern).
library;

/// Status satu cek validasi.
enum Sprint117PerfStatus { pass, violation, unmet }

/// Satu fakta terukur untuk satu bukti performa/skala.
final class Sprint117PerfCheck {
  const Sprint117PerfCheck({
    required this.area,
    required this.check,
    required this.status,
    required this.declared,
    required this.observed,
    this.note = '',
  });

  const factory Sprint117PerfCheck.pass_({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note,
  }) = Sprint117PerfCheck._pass;

  const factory Sprint117PerfCheck.violation({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note,
  }) = Sprint117PerfCheck._violation;

  const factory Sprint117PerfCheck.unmet({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note,
  }) = Sprint117PerfCheck._unmet;

  const Sprint117PerfCheck._pass({
    required this.area,
    required this.check,
    required this.declared,
    required this.observed,
    this.note = '',
  }) : status = Sprint117PerfStatus.pass;

  const Sprint117PerfCheck._violation({
    required this.area,
    required this.check,
    required this.declared,
    required this.observed,
    this.note = '',
  }) : status = Sprint117PerfStatus.violation;

  const Sprint117PerfCheck._unmet({
    required this.area,
    required this.check,
    required this.declared,
    required this.observed,
    this.note = '',
  }) : status = Sprint117PerfStatus.unmet;

  /// Bukti kanonik; harus salah satu dari [Sprint117PerformanceScale.requiredAreas].
  final String area;

  /// Nama cek unik di dalam areanya.
  final String check;

  final Sprint117PerfStatus status;

  /// Pernyataan kontrak yang diuji, selalu non-kosong.
  final String declared;

  /// Nilai hasil pengukuran; selalu non-kosong (cek kosong = `vacuous`).
  final String observed;

  /// Konteks tambahan (sumber angka, alasan `unmet`).
  final String note;

  /// Kode kegagalan stabil `area:check`.
  String get code => '$area:$check';

  bool get isViolation => status == Sprint117PerfStatus.violation;

  Map<String, Object?> toJson() => <String, Object?>{
    'area': area,
    'check': check,
    'status': status.name,
    'declared': declared,
    'observed': observed,
    if (note.isNotEmpty) 'note': note,
  };
}

/// Hasil evaluasi: daftar cek + kegagalan struktural.
final class Sprint117PerfResult {
  const Sprint117PerfResult({required this.checks, required this.failures});

  final List<Sprint117PerfCheck> checks;

  /// Kode kegagalan (`missing_area:…`, `violation:…`, `vacuous:…`, …).
  /// Kosong berarti semua bukti terukur dan lolos.
  final List<String> failures;

  bool get pass => failures.isEmpty;

  List<String> get openItems => checks
      .where((c) => c.status == Sprint117PerfStatus.unmet)
      .map((c) => c.code)
      .toList();

  List<String> get violationCodes =>
      checks.where((c) => c.isViolation).map((c) => c.code).toList();

  /// Ringkasan runtut untuk laporan/ledger.
  String get summary =>
      'pass=$pass checks=${checks.length} failures=${failures.length} '
      'open=${openItems.length}';

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': '117.35',
    'document_role': 'SPRINT_117_35_PERFORMANCE_SCALE_EVIDENCE',
    'required_areas': Sprint117PerformanceScale.requiredAreas.toList(),
    'surfaces': Sprint117PerformanceScale.surfaceLabels,
    'verdict': pass
        ? 'PERFORMANCE_SCALE_VALIDATED_LOCAL'
        : 'PERFORMANCE_SCALE_FAILED',
    'pass': pass,
    'failures': failures,
    'open_items': openItems,
    'violation_codes': violationCodes,
    'checks': checks.map((c) => c.toJson()).toList(),
  };
}

/// Gate 117.35: evaluasi gagal-tertutup atas fakta terukur.
abstract final class Sprint117PerformanceScale {
  /// Bukti kanonik — urutan persis `required_evidence` step `117.35`.
  static const List<String> requiredAreas = <String>[
    'render',
    'many_accounts',
    'refresh',
    'charts',
    'local_scan',
    'slow_api',
    'memory',
    'contention',
  ];

  /// Permukaan tempat tiap bukti diukur (pelaporan, bukan batas pengukuran).
  static const Map<String, String> surfaceLabels = <String, String>{
    'render':
        'AccountCenterPerformanceResilience.render_budget with initialFrameBudgetMs=400ms; '
        'measured on first painted frame of chrome via Flutter rendering pipeline',
    'many_accounts':
        'AccountCenterPerformanceResilience.many_accounts_results with manyAccountCount=48; '
        'load/switch/list latency under concurrent provider health refresh',
    'refresh':
        'AccountCenterPerformanceResilience.refresh_budget with refreshBudgetMs=250ms; '
        'concurrent refresh of every provider health in one pass, cancellation clears queue',
    'charts':
        'AccountCenterPerformanceResilience.chartPalette input stability; '
        'theme swap must repaint donut/usage painters (trackColor/colors compared)',
    'local_scan':
        'AccountCenterPerformanceResilience.scan_results with scanBudgetMs=2000ms; '
        'storage scan progress reported, timeout handled, partial result graceful',
    'slow_api':
        'AccountCenterPerformanceResilience.slowApiIsExternallyMeasured=true; '
        'slow provider timeout/retry-after respected, UI not blocked; '
        'DEFERRED-EXTERNAL live provider measurement',
    'memory':
        'AsyncMutex lock contention bound; BackgroundJobQueue memory stable; '
        'DebouncedSearchController dispose cleans timers; no leak observer active',
    'contention':
        'BackgroundJobQueue maxConcurrentJobs=2, priorityWeight scheduling; '
        'pause/resume threshold; lock held time bound; background priority respected',
  };

  static Sprint117PerfResult evaluate(List<Sprint117PerfCheck> checks) {
    if (checks.isEmpty) {
      return const Sprint117PerfResult(
        checks: <Sprint117PerfCheck>[],
        failures: <String>['no_checks'],
      );
    }
    final failures = <String>[];
    final seen = <String>{};
    for (final check in checks) {
      if (!seen.add(check.code)) {
        failures.add('duplicate_check:${check.code}');
      }
      if (check.declared.trim().isEmpty) {
        failures.add('vacuous_declared:${check.code}');
      }
      if (check.observed.trim().isEmpty) {
        failures.add('vacuous:${check.code}');
      }
      if (check.isViolation) {
        failures.add('violation:${check.code}');
      }
    }
    for (final area in requiredAreas) {
      final inArea = checks.where((c) => c.area == area).toList();
      if (inArea.isEmpty) {
        failures.add('missing_area:$area');
        continue;
      }
      final hasPass = inArea.any((c) => c.status == Sprint117PerfStatus.pass);
      final hasViolation = inArea.any((c) => c.isViolation);
      if (!hasPass || hasViolation) {
        failures.add('area_without_pass:$area');
      }
    }
    final known = requiredAreas.toSet();
    if (known.length != requiredAreas.length) {
      failures.add('non_canonical_required_areas');
    }
    for (final area in checks.map((c) => c.area).toSet()) {
      if (!known.contains(area)) {
        failures.add('unknown_area:$area');
      }
    }
    return Sprint117PerfResult(
      checks: List<Sprint117PerfCheck>.unmodifiable(checks),
      failures: List<String>.unmodifiable(failures),
    );
  }
}
