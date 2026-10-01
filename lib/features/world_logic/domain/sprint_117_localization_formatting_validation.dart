/// 117.26 — Localization & Formatting Validation.
///
/// Kontrak gagal-tertutup untuk delapan area bukti wajib step kanonik
/// `117.26` (`required_evidence`: `rtl`, `text_expansion`, `relative_time`,
/// `storage_units`, `percentages`, `currency`, `tax`, `provider_names`).
///
/// Status per cek:
/// * `pass` — mekanisme yang di-ship menghasilkan nilai yang dideklarasikan;
/// * `violation` — mekanisme mengklaim X tapi render/interaksi menghasilkan Y;
/// * `unmet` — tuntutan kontrak tidak terpenuhi dan tidak bisa dipenuhi
///   tanpa mengubah token/referensi kanonis dalam slice ini (konflik
///   referensi internal spec); dilaporkan sebagai `open_items`, bukan
///   pelanggaran render.
///
/// Kegagalan struktural membuat `pass == false`: area tanpa cek
/// (`missing_area`), area tanpa satu pun `pass` (`area_without_pass`),
/// `observed`/`declared` kosong (`vacuous`, `vacuous_declared`), duplikat
/// `(area, check)` (`duplicate_check`), area di luar daftar wajib
/// (`unknown_area`), dan `no_checks`.
///
/// Catatan area: `provider_names` memakai nama jamak mengikuti
/// `required_evidence` kanonik, sementara `currency` dan `tax` tunggal
/// mengikuti bentuk yang sama di `sprint_117.json` — keduanya apa adanya di
/// kontrak, tidak diterjemahkan.
///
/// Sumber angka deklarasi: kontrak format
/// `AccountCenterLocalizationFormatting` (115.49: satuan desimal,
/// pengelompokan ribuan, persen `0..100`, uang dengan kode, tax berlabel
/// wilayah), `StorageUsageCardData` (115.19), `AccountOperationalMetrics`
/// (115.x), dan product spec `account_cloud_center_spec.json`
/// (SHA-256
/// `f0589fe77428b94a608f44939df8bbdd599e11b45d8605c59866ddaede99bd88a`).
/// Pengukuran render/interaksi dilakukan test drill, bukan file ini.
///
/// Murni Dart tanpa dependensi Flutter supaya gate bisa dievaluasi ulang
/// dari fakta yang sudah direkam.
library;

/// Status satu cek lokalisasi.
enum Sprint117LocalizationStatus { pass, violation, unmet }

/// Satu fakta terukur untuk sebuah area bukti.
final class Sprint117LocalizationCheck {
  const Sprint117LocalizationCheck({
    required this.area,
    required this.check,
    required this.status,
    required this.declared,
    required this.observed,
    this.note = '',
  });

  factory Sprint117LocalizationCheck.pass({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117LocalizationCheck(
    area: area,
    check: check,
    status: Sprint117LocalizationStatus.pass,
    declared: declared,
    observed: observed,
    note: note,
  );

  factory Sprint117LocalizationCheck.violation({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117LocalizationCheck(
    area: area,
    check: check,
    status: Sprint117LocalizationStatus.violation,
    declared: declared,
    observed: observed,
    note: note,
  );

  factory Sprint117LocalizationCheck.unmet({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117LocalizationCheck(
    area: area,
    check: check,
    status: Sprint117LocalizationStatus.unmet,
    declared: declared,
    observed: observed,
    note: note,
  );

  /// Area bukti kanonik; harus salah satu dari
  /// [Sprint117LocalizationValidation.requiredAreas].
  final String area;

  /// Nama cek unik di dalam areanya.
  final String check;

  final Sprint117LocalizationStatus status;

  /// Pernyataan kontrak/token yang diuji, selalu non-kosong.
  final String declared;

  /// Nilai hasil pengukuran; selalu non-kosong (cek kosong = `vacuous`).
  final String observed;

  /// Konteks tambahan (locale, viewport, sumber angka, alasan `unmet`).
  final String note;

  /// Kode kegagalan stabil `area:check`.
  String get code => '$area:$check';

  bool get isViolation => status == Sprint117LocalizationStatus.violation;

  Map<String, Object?> toJson() => <String, Object?>{
    'area': area,
    'check': check,
    'status': status.name,
    'declared': declared,
    'observed': observed,
    if (note.isNotEmpty) 'note': note,
  };
}

/// Hasil evaluasi: daftar cek + kegagalan struktural/violasi.
final class Sprint117LocalizationValidationResult {
  const Sprint117LocalizationValidationResult({
    required this.checks,
    required this.failures,
  });

  final List<Sprint117LocalizationCheck> checks;

  /// Kode kegagalan (`missing_area:…`, `violation:…`, `vacuous:…`, …).
  /// Kosong berarti seluruh delapan area terukur dan lolos.
  final List<String> failures;

  bool get pass => failures.isEmpty;

  /// Cek `unmet`: konflik referensi tanpa jalur perbaikan di slice ini,
  /// dilaporkan terbuka.
  List<String> get openItems => checks
      .where((c) => c.status == Sprint117LocalizationStatus.unmet)
      .map((c) => c.code)
      .toList();

  List<String> get violationCodes =>
      checks.where((c) => c.isViolation).map((c) => c.code).toList();

  /// Ringkasan runtut untuk laporan/ledger.
  String get summary =>
      'pass=$pass checks=${checks.length} failures=${failures.length} '
      'open=${openItems.length}';

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': '117.26',
    'document_role':
        'SPRINT_117_26_LOCALIZATION_FORMATTING_VALIDATION_EVIDENCE',
    'required_areas': Sprint117LocalizationValidation.requiredAreas.toList(),
    'viewports': Sprint117LocalizationValidation.viewportLabels,
    'verdict': pass
        ? 'LOCALIZATION_FORMATTING_VALIDATION_LOCAL'
        : 'LOCALIZATION_FORMATTING_VALIDATION_FAILED',
    'pass': pass,
    'failures': failures,
    'open_items': openItems,
    'violation_codes': violationCodes,
    'checks': checks.map((c) => c.toJson()).toList(),
  };
}

/// Gate 117.26: evaluasi gagal-tertutup atas fakta terukur.
abstract final class Sprint117LocalizationValidation {
  /// Delapan area wajib — urutan persis `required_evidence` kanonik.
  static const List<String> requiredAreas = <String>[
    'rtl',
    'text_expansion',
    'relative_time',
    'storage_units',
    'percentages',
    'currency',
    'tax',
    'provider_names',
  ];

  /// Label viewport/locale pemakaian per area (pelaporan; bukan batas
  /// pengukuran).
  static const Map<String, String> viewportLabels = <String, String>{
    'rtl': '1536x1024 + 390x844 ambient TextDirection.rtl',
    'text_expansion': '1536x1024 + 390x844 pada text scale 2.0',
    'relative_time': 'jam injeksi (tanpa wall clock) pada locale en',
    'storage_units': '1536x1024 + widget StorageUsageCard terisolasi',
    'percentages': '1536x1024 kartu metrik + domain storage',
    'currency': '1536x1024 kartu AI Usage + domain kontrak',
    'tax': 'token Invoice.taxInformation + kontrak taxDisplay',
    'provider_names': '1536x1024 panel Quick Connect + registry manifest',
  };

  static Sprint117LocalizationValidationResult evaluate(
    List<Sprint117LocalizationCheck> checks,
  ) {
    if (checks.isEmpty) {
      return Sprint117LocalizationValidationResult(
        checks: List<Sprint117LocalizationCheck>.unmodifiable(checks),
        failures: const <String>['no_checks'],
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
      if (inArea.every((c) => c.status != Sprint117LocalizationStatus.pass)) {
        failures.add('area_without_pass:$area');
      }
    }
    final known = requiredAreas.toSet();
    for (final area in checks.map((c) => c.area).toSet()) {
      if (!known.contains(area)) {
        failures.add('unknown_area:$area');
      }
    }
    return Sprint117LocalizationValidationResult(
      checks: List<Sprint117LocalizationCheck>.unmodifiable(checks),
      failures: List<String>.unmodifiable(failures),
    );
  }
}
