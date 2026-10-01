/// 117.30 — Usage, Credits & Cost Reconciliation (gate gagal-tertutup).
///
/// Kontrak gagal-tertutup untuk tujuh bukti kanonik step `117.30`
/// (`acceptance`: `source_match`, `app_credit_separation`, `provider_usage`,
/// `estimated_label`, `currency`, `period`, `unavailable_balance`).
///
/// Status per cek:
/// * `pass` — nilai yang di-ship sama persis dengan nilai yang diklaim;
/// * `violation` — permukaan menampilkan/menjumlahkan Y padahal nilai yang
///   benar adalah X;
/// * `unmet` — tuntutan kontrak tidak punya jalur perbaikan di slice ini,
///   dilaporkan sebagai `open_items`, bukan pelanggaran.
///
/// Kegagalan struktural membuat `pass == false`: area tanpa cek
/// (`missing_area`), area tanpa satu pun `pass` (`area_without_pass`),
/// `declared`/`observed` kosong (`vacuous`), duplikat `(area, check)`
/// (`duplicate_check`), area di luar daftar wajib (`unknown_area`), dan
/// `no_checks`.
///
/// Murni Dart tanpa dependensi Flutter supaya gate bisa dievaluasi ulang dari
/// fakta yang sudah direkam.
library;

/// Status satu cek rekonsiliasi usage/credit/biaya.
enum Sprint117UsageCostStatus { pass, violation, unmet }

/// Satu fakta terukur untuk satu bukti rekonsiliasi usage/credit/biaya.
final class Sprint117UsageCostCheck {
  const Sprint117UsageCostCheck({
    required this.area,
    required this.check,
    required this.status,
    required this.declared,
    required this.observed,
    this.note = '',
  });

  factory Sprint117UsageCostCheck.pass_({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117UsageCostCheck(
    area: area,
    check: check,
    status: Sprint117UsageCostStatus.pass,
    declared: declared,
    observed: observed,
    note: note,
  );

  factory Sprint117UsageCostCheck.violation({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117UsageCostCheck(
    area: area,
    check: check,
    status: Sprint117UsageCostStatus.violation,
    declared: declared,
    observed: observed,
    note: note,
  );

  factory Sprint117UsageCostCheck.unmet({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117UsageCostCheck(
    area: area,
    check: check,
    status: Sprint117UsageCostStatus.unmet,
    declared: declared,
    observed: observed,
    note: note,
  );

  /// Bukti kanonik; harus salah satu dari
  /// [Sprint117UsageCostValidation.requiredAreas].
  final String area;

  /// Nama cek unik di dalam areanya.
  final String check;

  final Sprint117UsageCostStatus status;

  /// Pernyataan kontrak yang diuji, selalu non-kosong.
  final String declared;

  /// Nilai hasil pengukuran; selalu non-kosong (cek kosong = `vacuous`).
  final String observed;

  /// Konteks tambahan (sumber angka, alasan `unmet`).
  final String note;

  /// Kode kegagalan stabil `area:check`.
  String get code => '$area:$check';

  bool get isViolation => status == Sprint117UsageCostStatus.violation;

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
final class Sprint117UsageCostValidationResult {
  const Sprint117UsageCostValidationResult({
    required this.checks,
    required this.failures,
  });

  final List<Sprint117UsageCostCheck> checks;

  /// Kode kegagalan (`missing_area:…`, `violation:…`, `vacuous:…`, …).
  /// Kosong berarti ketujuh bukti terukur dan lolos.
  final List<String> failures;

  bool get pass => failures.isEmpty;

  List<String> get openItems => checks
      .where((c) => c.status == Sprint117UsageCostStatus.unmet)
      .map((c) => c.code)
      .toList();

  List<String> get violationCodes =>
      checks.where((c) => c.isViolation).map((c) => c.code).toList();

  /// Ringkasan runtut untuk laporan/ledger.
  String get summary =>
      'pass=$pass checks=${checks.length} failures=${failures.length} '
      'open=${openItems.length}';

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': '117.30',
    'document_role': 'SPRINT_117_30_USAGE_CREDITS_COST_RECONCILIATION_EVIDENCE',
    'required_areas': Sprint117UsageCostValidation.requiredAreas.toList(),
    'surfaces': Sprint117UsageCostValidation.surfaceLabels,
    'verdict': pass
        ? 'USAGE_CREDITS_COST_RECONCILED_LOCAL'
        : 'USAGE_CREDITS_COST_RECONCILIATION_FAILED',
    'pass': pass,
    'failures': failures,
    'open_items': openItems,
    'violation_codes': violationCodes,
    'checks': checks.map((c) => c.toJson()).toList(),
  };
}

/// Gate 117.30: evaluasi gagal-tertutup atas fakta terukur.
abstract final class Sprint117UsageCostValidation {
  /// Tujuh bukti kanonik — urutan persis `acceptance` step `117.30`.
  static const List<String> requiredAreas = <String>[
    'source_match',
    'app_credit_separation',
    'provider_usage',
    'estimated_label',
    'currency',
    'period',
    'unavailable_balance',
  ];

  /// Permukaan tempat tiap bukti diukur (pelaporan, bukan batas pengukuran).
  static const Map<String, String> surfaceLabels = <String, String>{
    'source_match':
        'ProviderUsageRecord.source -> AiUsageRow.costLabel/costText + '
        'AccountCenterAiUsageReport.textSummary',
    'app_credit_separation':
        'ApplicationCreditBalance -> '
        'AccountCenterAiUsageReport.applicationCreditsRemaining (never a '
        'provider cost bucket) + RightRailCredits',
    'provider_usage':
        'ProviderUsageRecord.quantity -> AiUsageRow + '
        'AccountCenterAiUsageReport.quantityTotals',
    'estimated_label':
        'AiUsageRow.costLabel/costText + AiUsageCostTotal.label + '
        'AccountCenterAiUsageReport.costIsExact',
    'currency':
        'ProviderUsageRecord.currency -> AiUsageCostTotal.bucket key + '
        'AccountCenterLocalizationFormatting.formatCurrency + costIsExact',
    'period':
        'ProviderUsageRecord.billingPeriod vs measuredAt -> '
        'AiUsageChart.periods + AccountCenterAiUsageReport.periodMismatchCount',
    'unavailable_balance':
        'ApplicationCreditBalance.unavailable + ProviderBalance.unavailable + '
        'textSummary credits clause',
  };

  static Sprint117UsageCostValidationResult evaluate(
    List<Sprint117UsageCostCheck> checks,
  ) {
    if (checks.isEmpty) {
      return const Sprint117UsageCostValidationResult(
        checks: <Sprint117UsageCostCheck>[],
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
      if (inArea.every((c) => c.status != Sprint117UsageCostStatus.pass)) {
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
    return Sprint117UsageCostValidationResult(
      checks: List<Sprint117UsageCostCheck>.unmodifiable(checks),
      failures: List<String>.unmodifiable(failures),
    );
  }
}
