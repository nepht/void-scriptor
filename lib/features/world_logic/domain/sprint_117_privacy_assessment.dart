/// 117.33 — Privacy Assessment (gate gagal-tertutup).
///
/// Kontrak untuk delapan `required_evidence` kanonik step `117.33`:
/// `consent`, `minimization`, `destinations`, `content_exclusion`,
/// `retention`, `deletion`, `disconnect`, `telemetry_controls`.
///
/// Export evidence is still measured, but it is not a separate axis: an
/// export path that never consults the exclusion policy is an exclusion
/// failure, whatever the export screen calls itself.
///
/// Note: the area list below is read verbatim from the canonical
/// `required_evidence` of step `117.33`. No area is taken from a document
/// without a sprint number, and no area is added.
///
/// Status satu cek validasi privasi:
/// * `pass` — nilai yang di-ship sama dengan nilai yang diklaim;
/// * `violation` — permukaan melaporkan Y padahal nilai sebenarnya X;
/// * `unmet` — tuntutan kontrak tidak punya jalur perbaikan di slice ini,
///   dilaporkan sebagai `open_items`, bukan sebagai pelanggaran.
///
/// Kegagalan struktural membuat `pass == false`: area tanpa cek
/// (`missing_area`), area tanpa satu pun `pass` atau yang membawa pelanggaran
/// terukur (`area_without_pass`), `declared`/`observed` kosong (`vacuous`),
/// duplikat `(area, check)` (`duplicate_check`), area di luar daftar wajib
/// (`unknown_area`), dan `no_checks`.
///
/// Murni Dart tanpa dependensi Flutter supaya gate dapat dievaluasi ulang dari
/// fakta yang sudah direkam.
library;

import 'dart:convert';

/// Status satu cek validasi privasi.
enum Sprint117PrivacyStatus { pass, violation, unmet }

/// Satu fakta terukur untuk satu bukti validasi privasi.
final class Sprint117PrivacyCheck {
  const Sprint117PrivacyCheck({
    required this.area,
    required this.check,
    required this.status,
    required this.declared,
    required this.observed,
    this.note = '',
  });

  const factory Sprint117PrivacyCheck.pass_({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note,
  }) = Sprint117PrivacyCheck._pass;

  const factory Sprint117PrivacyCheck.violation({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note,
  }) = Sprint117PrivacyCheck._violation;

  const factory Sprint117PrivacyCheck.unmet({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note,
  }) = Sprint117PrivacyCheck._unmet;

  const Sprint117PrivacyCheck._pass({
    required this.area,
    required this.check,
    required this.declared,
    required this.observed,
    this.note = '',
  }) : status = Sprint117PrivacyStatus.pass;

  const Sprint117PrivacyCheck._violation({
    required this.area,
    required this.check,
    required this.declared,
    required this.observed,
    this.note = '',
  }) : status = Sprint117PrivacyStatus.violation;

  const Sprint117PrivacyCheck._unmet({
    required this.area,
    required this.check,
    required this.declared,
    required this.observed,
    this.note = '',
  }) : status = Sprint117PrivacyStatus.unmet;

  /// Bukti kanonik; harus salah satu dari
  /// [Sprint117PrivacyAssessment.requiredAreas].
  final String area;

  /// Nama cek unik di dalam areanya.
  final String check;

  final Sprint117PrivacyStatus status;

  /// Pernyataan kontrak yang diuji, selalu non-kosong.
  final String declared;

  /// Nilai hasil pengukuran; selalu non-kosong (cek kosong = `vacuous`).
  final String observed;

  /// Konteks tambahan (sumber angka, alasan `unmet`).
  final String note;

  /// Kode kegagalan stabil `area:check`.
  String get code => '$area:$check';

  bool get isViolation => status == Sprint117PrivacyStatus.violation;

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
final class Sprint117PrivacyAssessmentResult {
  const Sprint117PrivacyAssessmentResult({
    required this.checks,
    required this.failures,
  });

  final List<Sprint117PrivacyCheck> checks;

  /// Kode kegagalan (`missing_area:…`, `violation:…`, `vacuous:…`, …).
  /// Kosong berarti semua bukti terukur dan lolos.
  final List<String> failures;

  bool get pass => failures.isEmpty;

  List<String> get openItems => checks
      .where((c) => c.status == Sprint117PrivacyStatus.unmet)
      .map((c) => c.code)
      .toList();

  List<String> get violationCodes =>
      checks.where((c) => c.isViolation).map((c) => c.code).toList();

  /// Ringkasan runtut untuk laporan/ledger.
  String get summary =>
      'pass=$pass checks=${checks.length} failures=${failures.length} '
      'open=${openItems.length}';

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': '117.33',
    'document_role': 'SPRINT_117_33_PRIVACY_ASSESSMENT_EVIDENCE',
    'required_areas': Sprint117PrivacyAssessment.requiredAreas.toList(),
    'surfaces': Sprint117PrivacyAssessment.surfaceLabels,
    'verdict': pass
        ? 'PRIVACY_ASSESSMENT_VALIDATED_LOCAL'
        : 'PRIVACY_ASSESSMENT_FAILED',
    'pass': pass,
    'failures': failures,
    'open_items': openItems,
    'violation_codes': violationCodes,
    'checks': checks.map((c) => c.toJson()).toList(),
  };
}

/// Gate 117.33: evaluasi gagal-tertutup atas fakta terukur.
abstract final class Sprint117PrivacyAssessment {
  /// Bukti kanonik — urutan persis `required_evidence` step `117.33`.
  static const List<String> requiredAreas = <String>[
    'consent',
    'minimization',
    'destinations',
    'content_exclusion',
    'retention',
    'deletion',
    'disconnect',
    'telemetry_controls',
  ];

  /// Permukaan tempat tiap bukti diukur (pelaporan, bukan batas pengukuran).
  static const Map<String, String> surfaceLabels = <String, String>{
    'consent':
        'InputConsent/PrivacyPolicy deny-by-default + revoke, '
        'CloudTransferRequest cross-scope consent, '
        'AccountCenterPrivacyDataFlowReview.transferConsentBases',
    'minimization':
        'WorkflowPrivacyPolicy.allowedDataKinds under WorkflowPrivacyEvaluator; '
        'empty allowlist must not mean "everything is declared"',
    'destinations':
        'AutomationNetworkPolicy.checkRequest + '
        'PublishingWorkflowAdapter.isDestinationAllowed exact allowlist',
    'content_exclusion':
        'ArchiveSecretPolicy.isSecretPath over credential-bearing names, '
        'folders, and extensions that portable export must drop',
    'retention':
        'AccountCenterActivityAuditOverview.retentionCutoff, '
        'BackupRetention.maxCopies, rejection of non-positive/unbounded windows',
    'deletion':
        'WorkspaceCharacterDeletionService explicit-decision gate; '
        'retention must remove data, not only hide it from a list',
    'disconnect':
        'AccountConnectedAccountsManagement.unlink confirmed gate + '
        'AccountDisconnectResult.providerRevokeAttempted/providerRevoked',
    'telemetry_controls':
        'PrivacyDashboard.telemetryEnabled, CreatorFeatureFlags.analyticsEnabled, '
        'CreatorPrivacy.allowAiTraining — defaults alone are not enforcement; '
        'export surfaces are measured as content_exclusion evidence',
  };

  static Sprint117PrivacyAssessmentResult evaluate(
    List<Sprint117PrivacyCheck> checks,
  ) {
    if (checks.isEmpty) {
      return const Sprint117PrivacyAssessmentResult(
        checks: <Sprint117PrivacyCheck>[],
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
      // An area counts as covered only when it carries a passing measurement
      // and no measured violation. Leaving a defective area looking covered is
      // what let a failed axis report as validated: the failure list then said
      // only that something was violated, never which evidence area was not
      // validated.
      final hasPass = inArea.any(
        (c) => c.status == Sprint117PrivacyStatus.pass,
      );
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
    return Sprint117PrivacyAssessmentResult(
      checks: List<Sprint117PrivacyCheck>.unmodifiable(checks),
      failures: List<String>.unmodifiable(failures),
    );
  }
}

/// Klasifikasi data yang menolak nilai tak dikenal.
///
/// Ada supaya gate dapat menyatakan keputusan sebagai fakta terukur: setiap
/// `dataKind` yang diuji harus punya nama yang jelas dan klasifikasi yang
/// dapat dipertanggungjawabkan. Kelas ini hanya mengklasifikasi — ia tidak
/// memutuskan apakah sebuah transfer diizinkan.
enum Sprint117DataClass {
  /// Nama yang boleh diproses: bukan rahasia, bukan konten kreatif.
  operational,

  /// Data yang keluar dari perangkat dan butuh consent eksplisit.
  transferBound,

  /// Kredensial: tidak boleh punya default plaintext.
  credential,

  /// Konten kreatif pengguna: tidak boleh menjadi metrik.
  creativeContent,

  /// Tidak dikenal: gagal-tertutup, bukan dianggap aman.
  unknown,
}

/// Klasifikasi satu `dataKind` terhadap nama yang dikenal.
///
/// Default fail-closed: nama yang tidak dikenal menjadi [unknown], bukan
/// [operational]. Menganggap nama tak dikenal sebagai aman membuat gate
/// privacy bisa dilewati hanya dengan memilih nama baru.
Sprint117DataClass classifyDataKind(String? dataKind) {
  final name = (dataKind ?? '').trim().toLowerCase();
  if (name.isEmpty) return Sprint117DataClass.unknown;
  if (const <String>{
    'token',
    'access_token',
    'refresh_token',
    'api_key',
    'apikey',
    'secret',
    'password',
    'credential',
    'credentials',
    'client_secret',
    'private_key',
  }.contains(name)) {
    return Sprint117DataClass.credential;
  }
  if (const <String>{
    'manuscript',
    'novel',
    'chapter',
    'scene',
    'character',
    'lore',
    'draft',
    'story.text',
    'user.full.content',
    'screen',
    'recording',
  }.contains(name)) {
    return Sprint117DataClass.creativeContent;
  }
  if (const <String>{
    'image',
    'user.content',
    'user.profile',
    'account.profile',
  }.contains(name)) {
    return Sprint117DataClass.transferBound;
  }
  if (const <String>{
    'scene_count',
    'chapter_count',
    'word_count',
    'session_duration',
    'feature_flag',
    'outcome',
    'surface',
  }.contains(name)) {
    return Sprint117DataClass.operational;
  }
  // Fail-closed: a name this build has never heard of is not operational by
  // default. Defaulting here to `operational` would let any gate driven by
  // this classifier be walked by typing a new name — the exact fail-open the
  // classifier exists to prevent.
  return Sprint117DataClass.unknown;
}

/// Menghitung baris metrik untuk satu flag pada satu snapshot.
///
/// Ada supaya gate dapat menyatakan kardinalitas sebagai fakta terukur, bukan
/// sebagai klaim: minimalisasi yang tidak membatasi jumlah nilai `surface`
/// per flag bukan minimalisasi, karena setiap nilai unik adalah satu baris
/// yang menandai apa yang pernah disentuh pengguna.
int countMetricRows(Iterable<Map<String, Object?>> snapshot, String flag) =>
    snapshot.where((row) => row['flag'] == flag).length;

/// Ringkasan deterministik untuk ledger: jumlah baris dan kunci yang bertahan.
String describeMetricSnapshot(List<Map<String, Object?>> snapshot) {
  final keys = <String>{for (final row in snapshot) ...row.keys};
  final sorted = keys.toList()..sort();
  return 'rows=${snapshot.length} keys=$sorted';
}

/// Serialisasi stabil untuk bukti yang ditulis ulang.
String encodeAssessment(Sprint117PrivacyAssessmentResult result) =>
    const JsonEncoder.withIndent('  ').convert(result.toJson());
