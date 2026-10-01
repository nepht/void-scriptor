/// 117.24 — Responsive Layout Validation.
///
/// Kontrak gagal-tertutup untuk delapan area bukti wajib step kanonik
/// `117.24` (`required_evidence`: `1440_plus`, `1180`, `900`, `600`,
/// `mobile`, `drawer`, `reflow`, `no_overflow`). Delapan area itu diukur
/// terhadap layar Account & Cloud Center yang benar-benar di-render pada
/// viewport tiap tier, bukan terhadap deklarasi token.
///
/// Status per cek:
/// * `pass` — mekanisme yang di-ship menghasilkan nilai yang dideklarasikan;
/// * `violation` — mekanisme mengklaim X tapi render menghasilkan Y;
/// * `unmet` — kapasitas dideklarasikan di kontrak/token tetapi tidak punya
///   jalur render di layar; dilaporkan sebagai `open_items` (bukan
///   pelanggaran: UI tidak pernah mengklaim kemampuan itu tampil).
///
/// Kegagalan struktural membuat `pass == false`: area tanpa cek
/// (`missing_area`), area tanpa satu pun `pass` (`area_without_pass`),
/// `observed`/`declared` kosong (`vacuous`, `vacuous_declared`), duplikat
/// `(area, check)` (`duplicate_check`), area di luar daftar wajib
/// (`unknown_area`), dan `no_checks`.
///
/// Sumber angka deklarasi: kontrak frame `AccountCenterWideDesktopFrame`
/// (115.45), adaptasi desktop/tablet `AccountCenterDesktopTabletAdaptation`
/// (115.46), adaptasi mobile `AccountCenterMobileAdaptation` (115.47),
/// grid responsif `AccountCenterResponsiveGrid` (115.6), dan token
/// `AccountCenterDesignTokens` (115.5) — semuanya berpijak pada product spec
/// `account_cloud_center_spec.json` (SHA-256 `f0589fe77428b94a608f44939df8
/// bbdd599e11b45d8605c59866ddaede99bd88a`). Pengukuran render dilakukan
/// test drill, bukan file ini.
///
/// Murni Dart tanpa dependensi Flutter supaya gate bisa dievaluasi ulang
/// dari fakta yang sudah direkam.
library;

/// Status satu cek responsif.
enum Sprint117ResponsiveStatus { pass, violation, unmet }

/// Satu fakta terukur untuk sebuah area bukti.
final class Sprint117ResponsiveCheck {
  const Sprint117ResponsiveCheck({
    required this.area,
    required this.check,
    required this.status,
    required this.declared,
    required this.observed,
    this.note = '',
  });

  factory Sprint117ResponsiveCheck.pass({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117ResponsiveCheck(
    area: area,
    check: check,
    status: Sprint117ResponsiveStatus.pass,
    declared: declared,
    observed: observed,
    note: note,
  );

  factory Sprint117ResponsiveCheck.violation({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117ResponsiveCheck(
    area: area,
    check: check,
    status: Sprint117ResponsiveStatus.violation,
    declared: declared,
    observed: observed,
    note: note,
  );

  factory Sprint117ResponsiveCheck.unmet({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117ResponsiveCheck(
    area: area,
    check: check,
    status: Sprint117ResponsiveStatus.unmet,
    declared: declared,
    observed: observed,
    note: note,
  );

  /// Area bukti kanonik; harus salah satu dari
  /// [Sprint117ResponsiveLayoutValidation.requiredAreas].
  final String area;

  /// Nama cek unik di dalam areanya.
  final String check;

  final Sprint117ResponsiveStatus status;

  /// Pernyataan kontrak/token yang diuji, selalu non-kosong.
  final String declared;

  /// Nilai hasil pengukuran; selalu non-kosong (cek kosong = `vacuous`).
  final String observed;

  /// Konteks tambahan (viewport, sumber angka, alasan `unmet`).
  final String note;

  /// Kode kegagalan stabil `area:check`.
  String get code => '$area:$check';

  bool get isViolation => status == Sprint117ResponsiveStatus.violation;

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
final class Sprint117ResponsiveLayoutResult {
  const Sprint117ResponsiveLayoutResult({
    required this.checks,
    required this.failures,
  });

  final List<Sprint117ResponsiveCheck> checks;

  /// Kode kegagalan (`missing_area:…`, `violation:…`, `vacuous:…`, …).
  /// Kosong berarti seluruh delapan area terukur dan lolos.
  final List<String> failures;

  bool get pass => failures.isEmpty;

  /// Cek `unmet`: kapasitas tanpa jalur render, dilaporkan terbuka.
  List<String> get openItems => checks
      .where((c) => c.status == Sprint117ResponsiveStatus.unmet)
      .map((c) => c.code)
      .toList();

  List<String> get violationCodes =>
      checks.where((c) => c.isViolation).map((c) => c.code).toList();

  /// Ringkasan runtut untuk laporan/ledger.
  String get summary =>
      'pass=$pass checks=${checks.length} failures=${failures.length} '
      'open=${openItems.length}';

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': '117.24',
    'document_role': 'SPRINT_117_24_RESPONSIVE_LAYOUT_VALIDATION_EVIDENCE',
    'required_areas': Sprint117ResponsiveLayoutValidation.requiredAreas
        .toList(),
    'viewports': Sprint117ResponsiveLayoutValidation.viewportLabels,
    'verdict': pass
        ? 'RESPONSIVE_LAYOUT_VALIDATION_LOCAL'
        : 'RESPONSIVE_LAYOUT_VALIDATION_FAILED',
    'pass': pass,
    'failures': failures,
    'open_items': openItems,
    'violation_codes': violationCodes,
    'checks': checks.map((c) => c.toJson()).toList(),
  };
}

/// Gate 117.24: evaluasi gagal-tertutup atas fakta terukur.
abstract final class Sprint117ResponsiveLayoutValidation {
  /// Delapan area wajib — urutan persis `required_evidence` kanonik.
  static const List<String> requiredAreas = <String>[
    '1440_plus',
    '1180',
    '900',
    '600',
    'mobile',
    'drawer',
    'reflow',
    'no_overflow',
  ];

  /// Label viewport pemakaian per area (pelaporan; bukan batas pengukuran).
  static const Map<String, String> viewportLabels = <String, String>{
    '1440_plus': '1920x1080 + boundary 1440x900',
    '1180': '1180x900 (desktop)',
    '900': '900x800 (compact_desktop)',
    '600': '600x800 (tablet)',
    'mobile': '390x844 (mobile)',
    'drawer': '1180x900 drawer open/close',
    'reflow': '1920/1440/1439/1180/900/600/390',
    'no_overflow': 'semua viewport + siklus drawer',
  };

  static Sprint117ResponsiveLayoutResult evaluate(
    List<Sprint117ResponsiveCheck> checks,
  ) {
    if (checks.isEmpty) {
      return Sprint117ResponsiveLayoutResult(
        checks: List<Sprint117ResponsiveCheck>.unmodifiable(checks),
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
      if (inArea.every((c) => c.status != Sprint117ResponsiveStatus.pass)) {
        failures.add('area_without_pass:$area');
      }
    }
    final known = requiredAreas.toSet();
    for (final area in checks.map((c) => c.area).toSet()) {
      if (!known.contains(area)) {
        failures.add('unknown_area:$area');
      }
    }
    return Sprint117ResponsiveLayoutResult(
      checks: List<Sprint117ResponsiveCheck>.unmodifiable(checks),
      failures: List<String>.unmodifiable(failures),
    );
  }
}
