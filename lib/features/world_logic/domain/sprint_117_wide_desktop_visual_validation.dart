/// 117.23 — Wide Desktop Visual Validation.
///
/// Kontrak gagal-tertutup untuk delapan area bukti wajib step kanonik
/// `117.23` (`required_evidence`: `1536x1024`, `layout_dimensions`,
/// `card_grid`, `avatar`, `icons`, `progress`, `charts`, `status_bar`).
/// Delapan area itu diukur terhadap layar Account & Cloud Center yang
/// benar-benar di-render pada viewport referensi, bukan terhadap deklarasi
/// token.
///
/// Status per cek:
/// * `pass` — mekanisme yang di-ship menghasilkan nilai yang dideklarasikan;
/// * `violation` — mekanisme mengklaim X tapi render menghasilkan Y;
/// * `unmet` — kapasitas dideklarasikan di token/spec tetapi tidak punya
///   jalur render di layar referensi; dilaporkan sebagai `open_items`
///   (bukan pelanggaran: UI tidak pernah mengklaim kemampuan itu tampil).
///
/// Kegagalan struktural membuat `pass == false`: area tanpa cek
/// (`missing_area`), area tanpa satu pun `pass` (`area_without_pass`),
/// `observed` kosong (`vacuous`), duplikat `(area, check)`
/// (`duplicate_check`), dan area di luar daftar wajib (`unknown_area`).
///
/// Sumber angka deklarasi: product spec `account_cloud_center_spec.json`
/// (SHA-256 `f0589fe77428b94a608f44939df8bbd599e11b45d8605c59866ddaede99bd88a`)
/// lewat `AccountCenterDesignTokens` (115.5) dan kontrak frame
/// `AccountCenterWideDesktopFrame` (115.45). Pengukuran render dilakukan
/// test drill, bukan file ini.
///
/// Murni Dart tanpa dependensi Flutter supaya gate bisa dievaluasi ulang
/// dari fakta yang sudah direkam.
library;

import 'package:void_scriptor/features/account/domain/account_center_design_tokens.dart';

/// Status satu cek visual.
enum Sprint117VisualStatus { pass, violation, unmet }

/// Satu fakta terukur untuk sebuah area bukti.
final class Sprint117VisualCheck {
  const Sprint117VisualCheck({
    required this.area,
    required this.check,
    required this.status,
    required this.declared,
    required this.observed,
    this.note = '',
  });

  factory Sprint117VisualCheck.pass({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117VisualCheck(
    area: area,
    check: check,
    status: Sprint117VisualStatus.pass,
    declared: declared,
    observed: observed,
    note: note,
  );

  factory Sprint117VisualCheck.violation({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117VisualCheck(
    area: area,
    check: check,
    status: Sprint117VisualStatus.violation,
    declared: declared,
    observed: observed,
    note: note,
  );

  factory Sprint117VisualCheck.unmet({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117VisualCheck(
    area: area,
    check: check,
    status: Sprint117VisualStatus.unmet,
    declared: declared,
    observed: observed,
    note: note,
  );

  /// Area bukti kanonik; harus salah satu dari
  /// [Sprint117WideDesktopVisualValidation.requiredAreas].
  final String area;

  /// Nama cek unik di dalam areanya.
  final String check;

  final Sprint117VisualStatus status;

  /// Nilai yang dideklarasikan kontrak/token, selalu non-kosong.
  final String declared;

  /// Nilai hasil pengukuran; selalu non-kosong (cek kosong = `vacuous`).
  final String observed;

  /// Konteks tambahan (sumber angka, alasan `unmet`).
  final String note;

  /// Kode kegagalan stabil `area:check`.
  String get code => '$area:$check';

  bool get isViolation => status == Sprint117VisualStatus.violation;

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
final class Sprint117WideDesktopVisualResult {
  const Sprint117WideDesktopVisualResult({
    required this.checks,
    required this.failures,
  });

  final List<Sprint117VisualCheck> checks;

  /// Kode kegagalan (`missing_area:…`, `violation:…`, `vacuous:…`, …).
  /// Kosong berarti seluruh delapan area terukur dan lolos.
  final List<String> failures;

  bool get pass => failures.isEmpty;

  /// Cek `unmet`: kapasitas tanpa jalur render, dilaporkan terbuka.
  List<String> get openItems => checks
      .where((c) => c.status == Sprint117VisualStatus.unmet)
      .map((c) => c.code)
      .toList();

  List<String> get violationCodes =>
      checks.where((c) => c.isViolation).map((c) => c.code).toList();

  /// Ringkasan runtut untuk laporan/ledger.
  String get summary =>
      'pass=$pass checks=${checks.length} failures=${failures.length} '
      'open=${openItems.length}';

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': '117.23',
    'document_role': 'SPRINT_117_23_WIDE_DESKTOP_VISUAL_VALIDATION_EVIDENCE',
    'viewport': '1536x1024',
    'spec_document': AccountCenterDesignTokens.specDocument,
    'spec_sha256': AccountCenterDesignTokens.specSha256,
    'required_areas': Sprint117WideDesktopVisualValidation.requiredAreas
        .toList(),
    'verdict': pass
        ? 'WIDE_DESKTOP_VISUAL_VALIDATION_LOCAL'
        : 'WIDE_DESKTOP_VISUAL_VALIDATION_FAILED',
    'pass': pass,
    'failures': failures,
    'open_items': openItems,
    'violation_codes': violationCodes,
    'checks': checks.map((c) => c.toJson()).toList(),
  };
}

/// Gate 117.23: evaluasi gagal-tertutup atas fakta terukur.
abstract final class Sprint117WideDesktopVisualValidation {
  /// Delapan area wajib — urutan persis `required_evidence` kanonik.
  static const List<String> requiredAreas = <String>[
    '1536x1024',
    'layout_dimensions',
    'card_grid',
    'avatar',
    'icons',
    'progress',
    'charts',
    'status_bar',
  ];

  static Sprint117WideDesktopVisualResult evaluate(
    List<Sprint117VisualCheck> checks,
  ) {
    if (checks.isEmpty) {
      return Sprint117WideDesktopVisualResult(
        checks: List<Sprint117VisualCheck>.unmodifiable(checks),
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
      if (inArea.every((c) => c.status != Sprint117VisualStatus.pass)) {
        failures.add('area_without_pass:$area');
      }
    }
    final known = requiredAreas.toSet();
    for (final area in checks.map((c) => c.area).toSet()) {
      if (!known.contains(area)) {
        failures.add('unknown_area:$area');
      }
    }
    return Sprint117WideDesktopVisualResult(
      checks: List<Sprint117VisualCheck>.unmodifiable(checks),
      failures: List<String>.unmodifiable(failures),
    );
  }
}
