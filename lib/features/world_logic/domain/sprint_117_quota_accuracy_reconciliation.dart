/// 117.29 — Quota Accuracy Reconciliation (gate gagal-tertutup).
///
/// Kontrak gagal-tertutup untuk tujuh bukti kanonik step `117.29`
/// (`acceptance`: `api_match`, `local_scan_match`, `timestamp`,
/// `unit_conversion`, `rounding`, `no_mock`, `unavailable_state`).
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
/// `observed`/`declared` kosong (`vacuous`), duplikat `(area, check)`
/// (`duplicate_check`), area di luar daftar wajib (`unknown_area`), dan
/// `no_checks`.
///
/// Murni Dart tanpa dependensi Flutter supaya gate bisa dievaluasi ulang dari
/// fakta yang sudah direkam.
library;

/// Status satu cek akurasi quota.
enum Sprint117QuotaAccuracyStatus { pass, violation, unmet }

/// Satu fakta terukur untuk satu bukti akurasi quota.
final class Sprint117QuotaAccuracyCheck {
  const Sprint117QuotaAccuracyCheck({
    required this.area,
    required this.check,
    required this.status,
    required this.declared,
    required this.observed,
    this.note = '',
  });

  factory Sprint117QuotaAccuracyCheck.pass_({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117QuotaAccuracyCheck(
    area: area,
    check: check,
    status: Sprint117QuotaAccuracyStatus.pass,
    declared: declared,
    observed: observed,
    note: note,
  );

  factory Sprint117QuotaAccuracyCheck.violation({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117QuotaAccuracyCheck(
    area: area,
    check: check,
    status: Sprint117QuotaAccuracyStatus.violation,
    declared: declared,
    observed: observed,
    note: note,
  );

  factory Sprint117QuotaAccuracyCheck.unmet({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117QuotaAccuracyCheck(
    area: area,
    check: check,
    status: Sprint117QuotaAccuracyStatus.unmet,
    declared: declared,
    observed: observed,
    note: note,
  );

  /// Bukti kanonik; harus salah satu dari
  /// [Sprint117QuotaAccuracyValidation.requiredAreas].
  final String area;

  /// Nama cek unik di dalam areanya.
  final String check;

  final Sprint117QuotaAccuracyStatus status;

  /// Pernyataan kontrak yang diuji, selalu non-kosong.
  final String declared;

  /// Nilai hasil pengukuran; selalu non-kosong (cek kosong = `vacuous`).
  final String observed;

  /// Konteks tambahan (sumber angka, alasan `unmet`).
  final String note;

  /// Kode kegagalan stabil `area:check`.
  String get code => '$area:$check';

  bool get isViolation => status == Sprint117QuotaAccuracyStatus.violation;

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
final class Sprint117QuotaAccuracyValidationResult {
  const Sprint117QuotaAccuracyValidationResult({
    required this.checks,
    required this.failures,
  });

  final List<Sprint117QuotaAccuracyCheck> checks;

  /// Kode kegagalan (`missing_area:…`, `violation:…`, `vacuous:…`, …).
  /// Kosong berarti ketujuh bukti terukur dan lolos.
  final List<String> failures;

  bool get pass => failures.isEmpty;

  List<String> get openItems => checks
      .where((c) => c.status == Sprint117QuotaAccuracyStatus.unmet)
      .map((c) => c.code)
      .toList();

  List<String> get violationCodes =>
      checks.where((c) => c.isViolation).map((c) => c.code).toList();

  /// Ringkasan runtut untuk laporan/ledger.
  String get summary =>
      'pass=$pass checks=${checks.length} failures=${failures.length} '
      'open=${openItems.length}';

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': '117.29',
    'document_role': 'SPRINT_117_29_QUOTA_ACCURACY_RECONCILIATION_EVIDENCE',
    'required_areas': Sprint117QuotaAccuracyValidation.requiredAreas.toList(),
    'surfaces': Sprint117QuotaAccuracyValidation.surfaceLabels,
    'verdict': pass
        ? 'QUOTA_ACCURACY_RECONCILED_LOCAL'
        : 'QUOTA_ACCURACY_RECONCILIATION_FAILED',
    'pass': pass,
    'failures': failures,
    'open_items': openItems,
    'violation_codes': violationCodes,
    'checks': checks.map((c) => c.toJson()).toList(),
  };
}

/// Gate 117.29: evaluasi gagal-tertutup atas fakta terukur.
abstract final class Sprint117QuotaAccuracyValidation {
  /// Tujuh bukti kanonik — urutan persis `acceptance` step `117.29`.
  static const List<String> requiredAreas = <String>[
    'api_match',
    'local_scan_match',
    'timestamp',
    'unit_conversion',
    'rounding',
    'no_mock',
    'unavailable_state',
  ];

  /// Permukaan tempat tiap bukti diukur (pelaporan, bukan batas pengukuran).
  static const Map<String, String> surfaceLabels = <String, String>{
    'api_match':
        'ProviderQuotaReading -> StorageUsageCardData + '
        'CloudStorageAggregation.from',
    'local_scan_match':
        'StorageDistributionRecord(localScan) -> '
        'AccountCenterStorageDistributionReport.chart.totalBytes',
    'timestamp':
        'ProviderQuotaResult.fromReading + '
        'StorageUsageCardData._freshness + '
        'StorageDistributionFreshnessPolicy.classify',
    'unit_conversion':
        'ProviderQuotaUnit -> bytes in '
        'CloudStorageAggregation.from',
    'rounding': 'AccountCenterLocalizationFormatting.storageUnits boundary',
    'no_mock':
        'StorageRecordSource.userDeclared + '
        'AccountCenterStorageDistributionReport.referenceMockValuesAllowed',
    'unavailable_state':
        'CloudStorageAggregationStatus.unavailable + '
        'StorageUsageCardData.unknownQuota + RightRailStorageLine',
  };

  static Sprint117QuotaAccuracyValidationResult evaluate(
    List<Sprint117QuotaAccuracyCheck> checks,
  ) {
    if (checks.isEmpty) {
      return const Sprint117QuotaAccuracyValidationResult(
        checks: <Sprint117QuotaAccuracyCheck>[],
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
      if (inArea.every((c) => c.status != Sprint117QuotaAccuracyStatus.pass)) {
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
    return Sprint117QuotaAccuracyValidationResult(
      checks: List<Sprint117QuotaAccuracyCheck>.unmodifiable(checks),
      failures: List<String>.unmodifiable(failures),
    );
  }
}
