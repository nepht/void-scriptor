/// 117.27 — Offline & Cached-State Validation.
///
/// Kontrak gagal-tertutup untuk enam area bukti wajib step kanonik
/// `117.27` (`required_evidence`: `cached_metadata`, `freshness`,
/// `remote_disabled`, `local_available`, `reconnect`, `cache_clear`).
///
/// Status per cek:
/// * `pass` — mekanisme yang di-ship menghasilkan nilai yang dideklarasikan;
/// * `violation` — mekanisme mengklaim X tapi render/interaksi menghasilkan Y;
/// * `unmet` — tuntutan kontrak tidak terpenuhi dan tidak bisa dipenuhi
///   tanpa mengubah kontrak kanonis dalam slice ini; dilaporkan sebagai
///   `open_items`, bukan pelanggaran.
///
/// Kegagalan struktural membuat `pass == false`: area tanpa cek
/// (`missing_area`), area tanpa satu pun `pass` (`area_without_pass`),
/// `observed`/`declared` kosong (`vacuous`, `vacuous_declared`), duplikat
/// `(area, check)` (`duplicate_check`), area di luar daftar wajib
/// (`unknown_area`), dan `no_checks`.
///
/// Anchor: kontrak offline `AccountCenterOfflineMode` (115.44: cached
/// metadata ber-freshness, remote action mati, local settings dan local
/// storage tetap tersedia, reconnect-and-refresh eksplisit), sertifikasi
/// cache 116.44 (`Sprint116OfflineCacheContract`: TTL, `cache_clear`),
/// `ProjectCacheService`/`ProjectResilienceRepository.clearCache` (jalur
/// hapus cache yang di-ship), dan tabel `CacheEntries`
/// (`lib/database/project/tables/project_resilience.dart`).
///
/// Murni Dart tanpa dependensi Flutter supaya gate bisa dievaluasi ulang
/// dari fakta yang sudah direkam.
library;

/// Status satu cek state offline.
enum Sprint117OfflineStateStatus { pass, violation, unmet }

/// Satu fakta terukur untuk sebuah area bukti.
final class Sprint117OfflineStateCheck {
  const Sprint117OfflineStateCheck({
    required this.area,
    required this.check,
    required this.status,
    required this.declared,
    required this.observed,
    this.note = '',
  });

  factory Sprint117OfflineStateCheck.pass({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117OfflineStateCheck(
    area: area,
    check: check,
    status: Sprint117OfflineStateStatus.pass,
    declared: declared,
    observed: observed,
    note: note,
  );

  factory Sprint117OfflineStateCheck.violation({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117OfflineStateCheck(
    area: area,
    check: check,
    status: Sprint117OfflineStateStatus.violation,
    declared: declared,
    observed: observed,
    note: note,
  );

  factory Sprint117OfflineStateCheck.unmet({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117OfflineStateCheck(
    area: area,
    check: check,
    status: Sprint117OfflineStateStatus.unmet,
    declared: declared,
    observed: observed,
    note: note,
  );

  /// Area bukti kanonik; harus salah satu dari
  /// [Sprint117OfflineStateValidation.requiredAreas].
  final String area;

  /// Nama cek unik di dalam areanya.
  final String check;

  final Sprint117OfflineStateStatus status;

  /// Pernyataan kontrak yang diuji, selalu non-kosong.
  final String declared;

  /// Nilai hasil pengukuran; selalu non-kosong (cek kosong = `vacuous`).
  final String observed;

  /// Konteks tambahan (sumber angka, alasan `unmet`).
  final String note;

  /// Kode kegagalan stabil `area:check`.
  String get code => '$area:$check';

  bool get isViolation => status == Sprint117OfflineStateStatus.violation;

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
final class Sprint117OfflineStateValidationResult {
  const Sprint117OfflineStateValidationResult({
    required this.checks,
    required this.failures,
  });

  final List<Sprint117OfflineStateCheck> checks;

  /// Kode kegagalan (`missing_area:…`, `violation:…`, `vacuous:…`, …).
  /// Kosong berarti seluruh enam area terukur dan lolos.
  final List<String> failures;

  bool get pass => failures.isEmpty;

  /// Cek `unmet`: kontrak yang tidak punya jalur perbaikan di slice ini,
  /// dilaporkan terbuka.
  List<String> get openItems => checks
      .where((c) => c.status == Sprint117OfflineStateStatus.unmet)
      .map((c) => c.code)
      .toList();

  List<String> get violationCodes =>
      checks.where((c) => c.isViolation).map((c) => c.code).toList();

  /// Ringkasan runtut untuk laporan/ledger.
  String get summary =>
      'pass=$pass checks=${checks.length} failures=${failures.length} '
      'open=${openItems.length}';

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': '117.27',
    'document_role': 'SPRINT_117_27_OFFLINE_CACHED_STATE_VALIDATION_EVIDENCE',
    'required_areas': Sprint117OfflineStateValidation.requiredAreas.toList(),
    'surfaces': Sprint117OfflineStateValidation.surfaceLabels,
    'verdict': pass
        ? 'OFFLINE_CACHED_STATE_VALIDATION_LOCAL'
        : 'OFFLINE_CACHED_STATE_VALIDATION_FAILED',
    'pass': pass,
    'failures': failures,
    'open_items': openItems,
    'violation_codes': violationCodes,
    'checks': checks.map((c) => c.toJson()).toList(),
  };
}

/// Gate 117.27: evaluasi gagal-tertutup atas fakta terukur.
abstract final class Sprint117OfflineStateValidation {
  /// Enam area wajib — urutan persis `required_evidence` kanonik.
  static const List<String> requiredAreas = <String>[
    'cached_metadata',
    'freshness',
    'remote_disabled',
    'local_available',
    'reconnect',
    'cache_clear',
  ];

  /// Permukaan tempat tiap area diukur (pelaporan, bukan batas pengukuran).
  static const Map<String, String> surfaceLabels = <String, String>{
    'cached_metadata': 'AccountCenterOfflineMode.cached + notice render',
    'freshness': 'AccountCenterOfflineFreshnessPolicy.classify jam injeksi',
    'remote_disabled':
        'performRemoteAction untuk 7 aksi + notice setelah reconnect',
    'local_available':
        'AccountCenterLocalSetting/AccountCenterLocalStorageDetails',
    'reconnect': 'AccountCenterReconnectPlan.apply pada jam injeksi',
    'cache_clear': 'ProjectCacheService.clear pada package sementara',
  };

  static Sprint117OfflineStateValidationResult evaluate(
    List<Sprint117OfflineStateCheck> checks,
  ) {
    if (checks.isEmpty) {
      return const Sprint117OfflineStateValidationResult(
        checks: <Sprint117OfflineStateCheck>[],
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
      if (inArea.every((c) => c.status != Sprint117OfflineStateStatus.pass)) {
        failures.add('area_without_pass:$area');
      }
    }
    final known = requiredAreas.toSet();
    for (final area in checks.map((c) => c.area).toSet()) {
      if (!known.contains(area)) {
        failures.add('unknown_area:$area');
      }
    }
    return Sprint117OfflineStateValidationResult(
      checks: List<Sprint117OfflineStateCheck>.unmodifiable(checks),
      failures: List<String>.unmodifiable(failures),
    );
  }
}
