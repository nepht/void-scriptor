/// 117.25 — Accessibility Validation.
///
/// Kontrak gagal-tertutup untuk delapan area bukti wajib step kanonik
/// `117.25` (`required_evidence`: `keyboard`, `focus`, `screen_reader`,
/// `status_text`, `chart_alternative`, `progress_semantics`,
/// `touch_targets`, `scaling`). Objective step juga menutup *reduced
/// motion*; fakta itu diukur sebagai cek di area `focus`
/// (`reduced_motion_ring_duration`) karena daftar bukti kanonik tidak
/// memuat area tersendiri.
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
/// Sumber angka deklarasi: kontrak aksesibilitas
/// `AccountCenterAccessibility` (115.7 baseline interaksi, 115.48
/// verifikasi keyboard/screen-reader, 116.47 gerbang visual brand),
/// token `AccountCenterDesignTokens.density` (115.5:
/// `tabBarHeight=40`, `minimumTouchTarget=44`), IA kanonik
/// `AccountCenterInformationArchitecture`, dan product spec
/// `account_cloud_center_spec.json` (SHA-256
/// `f0589fe77428b94a608f44939df8bbdd599e11b45d8605c59866ddaede99bd88a`).
/// Pengukuran render/interaksi dilakukan test drill, bukan file ini.
///
/// Murni Dart tanpa dependensi Flutter supaya gate bisa dievaluasi ulang
/// dari fakta yang sudah direkam.
library;

/// Status satu cek aksesibilitas.
enum Sprint117AccessibilityStatus { pass, violation, unmet }

/// Satu fakta terukur untuk sebuah area bukti.
final class Sprint117AccessibilityCheck {
  const Sprint117AccessibilityCheck({
    required this.area,
    required this.check,
    required this.status,
    required this.declared,
    required this.observed,
    this.note = '',
  });

  factory Sprint117AccessibilityCheck.pass({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117AccessibilityCheck(
    area: area,
    check: check,
    status: Sprint117AccessibilityStatus.pass,
    declared: declared,
    observed: observed,
    note: note,
  );

  factory Sprint117AccessibilityCheck.violation({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117AccessibilityCheck(
    area: area,
    check: check,
    status: Sprint117AccessibilityStatus.violation,
    declared: declared,
    observed: observed,
    note: note,
  );

  factory Sprint117AccessibilityCheck.unmet({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117AccessibilityCheck(
    area: area,
    check: check,
    status: Sprint117AccessibilityStatus.unmet,
    declared: declared,
    observed: observed,
    note: note,
  );

  /// Area bukti kanonik; harus salah satu dari
  /// [Sprint117AccessibilityValidation.requiredAreas].
  final String area;

  /// Nama cek unik di dalam areanya.
  final String check;

  final Sprint117AccessibilityStatus status;

  /// Pernyataan kontrak/token yang diuji, selalu non-kosong.
  final String declared;

  /// Nilai hasil pengukuran; selalu non-kosong (cek kosong = `vacuous`).
  final String observed;

  /// Konteks tambahan (viewport, sumber angka, alasan `unmet`).
  final String note;

  /// Kode kegagalan stabil `area:check`.
  String get code => '$area:$check';

  bool get isViolation => status == Sprint117AccessibilityStatus.violation;

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
final class Sprint117AccessibilityValidationResult {
  const Sprint117AccessibilityValidationResult({
    required this.checks,
    required this.failures,
  });

  final List<Sprint117AccessibilityCheck> checks;

  /// Kode kegagalan (`missing_area:…`, `violation:…`, `vacuous:…`, …).
  /// Kosong berarti seluruh delapan area terukur dan lolos.
  final List<String> failures;

  bool get pass => failures.isEmpty;

  /// Cek `unmet`: konflik referensi tanpa jalur perbaikan di slice ini,
  /// dilaporkan terbuka.
  List<String> get openItems => checks
      .where((c) => c.status == Sprint117AccessibilityStatus.unmet)
      .map((c) => c.code)
      .toList();

  List<String> get violationCodes =>
      checks.where((c) => c.isViolation).map((c) => c.code).toList();

  /// Ringkasan runtut untuk laporan/ledger.
  String get summary =>
      'pass=$pass checks=${checks.length} failures=${failures.length} '
      'open=${openItems.length}';

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': '117.25',
    'document_role': 'SPRINT_117_25_ACCESSIBILITY_VALIDATION_EVIDENCE',
    'required_areas': Sprint117AccessibilityValidation.requiredAreas.toList(),
    'viewports': Sprint117AccessibilityValidation.viewportLabels,
    'verdict': pass
        ? 'ACCESSIBILITY_VALIDATION_LOCAL'
        : 'ACCESSIBILITY_VALIDATION_FAILED',
    'pass': pass,
    'failures': failures,
    'open_items': openItems,
    'violation_codes': violationCodes,
    'checks': checks.map((c) => c.toJson()).toList(),
  };
}

/// Gate 117.25: evaluasi gagal-tertutup atas fakta terukur.
abstract final class Sprint117AccessibilityValidation {
  /// Delapan area wajib — urutan persis `required_evidence` kanonik.
  static const List<String> requiredAreas = <String>[
    'keyboard',
    'focus',
    'screen_reader',
    'status_text',
    'chart_alternative',
    'progress_semantics',
    'touch_targets',
    'scaling',
  ];

  /// Label viewport pemakaian per area (pelaporan; bukan batas pengukuran).
  static const Map<String, String> viewportLabels = <String, String>{
    'keyboard': '1440x900 traversal keyboard penuh',
    'focus': '1440x900 + 390x844 traversal + reduced motion',
    'screen_reader': '1440x900 + 390x844 semantics sweep',
    'status_text': '1440x900 semantics sweep (guest)',
    'chart_alternative': '1440x900 semantics sweep (guest)',
    'progress_semantics': 'guest + StorageUsageCard fixture data',
    'touch_targets': '1440x900 + 390x844 widget render boxes',
    'scaling': '1920/1180/600/390 pada text scale 2.0',
  };

  static Sprint117AccessibilityValidationResult evaluate(
    List<Sprint117AccessibilityCheck> checks,
  ) {
    if (checks.isEmpty) {
      return Sprint117AccessibilityValidationResult(
        checks: List<Sprint117AccessibilityCheck>.unmodifiable(checks),
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
      if (inArea.every((c) => c.status != Sprint117AccessibilityStatus.pass)) {
        failures.add('area_without_pass:$area');
      }
    }
    final known = requiredAreas.toSet();
    for (final area in checks.map((c) => c.area).toSet()) {
      if (!known.contains(area)) {
        failures.add('unknown_area:$area');
      }
    }
    return Sprint117AccessibilityValidationResult(
      checks: List<Sprint117AccessibilityCheck>.unmodifiable(checks),
      failures: List<String>.unmodifiable(failures),
    );
  }
}
