/// 117.32 — Security Assessment (gate gagal-tertutup).
///
/// Kontrak untuk delapan `required_evidence` kanonik step `117.32`:
/// `oauth`, `redirects`, `vault`, `sessions`, `permissions`, `webhooks`,
/// `dependencies`, `log_redaction`.
///
/// Status satu cek validasi keamanan:
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

import 'package:crypto/crypto.dart';

import '../../../core/security/crypto/key_derivation.dart';

/// Status satu cek validasi keamanan.
enum Sprint117SecurityStatus { pass, violation, unmet }

/// Satu fakta terukur untuk satu bukti validasi keamanan.
final class Sprint117SecurityCheck {
  const Sprint117SecurityCheck({
    required this.area,
    required this.check,
    required this.status,
    required this.declared,
    required this.observed,
    this.note = '',
  });

  factory Sprint117SecurityCheck.pass_({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117SecurityCheck(
    area: area,
    check: check,
    status: Sprint117SecurityStatus.pass,
    declared: declared,
    observed: observed,
    note: note,
  );

  factory Sprint117SecurityCheck.violation({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117SecurityCheck(
    area: area,
    check: check,
    status: Sprint117SecurityStatus.violation,
    declared: declared,
    observed: observed,
    note: note,
  );

  factory Sprint117SecurityCheck.unmet({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117SecurityCheck(
    area: area,
    check: check,
    status: Sprint117SecurityStatus.unmet,
    declared: declared,
    observed: observed,
    note: note,
  );

  /// Bukti kanonik; harus salah satu dari
  /// [Sprint117SecurityAssessment.requiredAreas].
  final String area;

  /// Nama cek unik di dalam areanya.
  final String check;

  final Sprint117SecurityStatus status;

  /// Pernyataan kontrak yang diuji, selalu non-kosong.
  final String declared;

  /// Nilai hasil pengukuran; selalu non-kosong (cek kosong = `vacuous`).
  final String observed;

  /// Konteks tambahan (sumber angka, alasan `unmet`).
  final String note;

  /// Kode kegagalan stabil `area:check`.
  String get code => '$area:$check';

  bool get isViolation => status == Sprint117SecurityStatus.violation;

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
final class Sprint117SecurityAssessmentResult {
  const Sprint117SecurityAssessmentResult({
    required this.checks,
    required this.failures,
  });

  final List<Sprint117SecurityCheck> checks;

  /// Kode kegagalan (`missing_area:…`, `violation:…`, `vacuous:…`, …).
  /// Kosong berarti kedelapan bukti terukur dan lolos.
  final List<String> failures;

  bool get pass => failures.isEmpty;

  List<String> get openItems => checks
      .where((c) => c.status == Sprint117SecurityStatus.unmet)
      .map((c) => c.code)
      .toList();

  List<String> get violationCodes =>
      checks.where((c) => c.isViolation).map((c) => c.code).toList();

  /// Ringkasan runtut untuk laporan/ledger.
  String get summary =>
      'pass=$pass checks=${checks.length} failures=${failures.length} '
      'open=${openItems.length}';

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': '117.32',
    'document_role': 'SPRINT_117_32_SECURITY_ASSESSMENT_EVIDENCE',
    'required_areas': Sprint117SecurityAssessment.requiredAreas.toList(),
    'surfaces': Sprint117SecurityAssessment.surfaceLabels,
    'verdict': pass
        ? 'SECURITY_ASSESSMENT_VALIDATED_LOCAL'
        : 'SECURITY_ASSESSMENT_FAILED',
    'pass': pass,
    'failures': failures,
    'open_items': openItems,
    'violation_codes': violationCodes,
    'checks': checks.map((c) => c.toJson()).toList(),
  };
}

/// Gate 117.32: evaluasi gagal-tertutup atas fakta terukur.
abstract final class Sprint117SecurityAssessment {
  /// Delapan bukti kanonik — urutan persis `required_evidence` step `117.32`.
  static const List<String> requiredAreas = <String>[
    'oauth',
    'redirects',
    'vault',
    'sessions',
    'permissions',
    'webhooks',
    'dependencies',
    'log_redaction',
  ];

  /// Permukaan tempat tiap bukti diukur (pelaporan, bukan batas pengukuran).
  static const Map<String, String> surfaceLabels = <String, String>{
    'oauth':
        'AccountOAuthFlow.startAuthorization PKCE verifier + state + nonce, '
        'consumed-on-complete, PendingAuthorizationRegistry live entries',
    'redirects':
        'OAuthProviderConfiguration scheme validation + '
        'OAuthRedirectMatching.matches (scheme/host/port/path/userInfo)',
    'vault':
        'AccountSecureTokenVault read/reauthenticate + VaultAuditEvent.secret '
        'never populated + revoke clipboard wipe',
    'sessions':
        'AuthSessionStoreIo.load JSON shape guard + AuthSessionJson schema',
    'permissions':
        'PluginManifest.fromJson permission validation via '
        'PluginPermissionSet.validate + PluginSandbox.require',
    'webhooks':
        'Sprint117WebhookSignatureVerifier HMAC-SHA256 over the raw payload; '
        'Sprint116 manifest signature_status is self-attested, not evidence',
    'dependencies':
        'pubspec.lock hosted sha256 pins, git/path sources, '
        'dependency_overrides, SecretScanner over the lockfile',
    'log_redaction':
        'SecretScanner pattern families + SecretRedactor.redact '
        'case-insensitivity and order independence',
  };

  static Sprint117SecurityAssessmentResult evaluate(
    List<Sprint117SecurityCheck> checks,
  ) {
    if (checks.isEmpty) {
      return const Sprint117SecurityAssessmentResult(
        checks: <Sprint117SecurityCheck>[],
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
      // and no measured violation. A violation already fails the gate on its
      // own code, but leaving the area looking covered is what let a defective
      // area pass for a validated one: the failure list then said only that
      // something was violated, never which evidence area was not validated.
      final hasPass = inArea.any(
        (c) => c.status == Sprint117SecurityStatus.pass,
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
    return Sprint117SecurityAssessmentResult(
      checks: List<Sprint117SecurityCheck>.unmodifiable(checks),
      failures: List<String>.unmodifiable(failures),
    );
  }
}

/// Verifikasi tanda tangan webhook berbasis HMAC-SHA256 atas payload mentah.
///
/// Menggantikan ketidaklayakan "signature_status" yang self-dideklarasikan di
/// manifest yang ditulis pihak yang sama: status `VERIFIED` adalah pernyataan,
/// bukan bukti, dan siapa pun yang menulis manifest bisa mengisinya.
final class Sprint117WebhookSignatureVerifier {
  Sprint117WebhookSignatureVerifier.withSecretKey(this._key);

  final SecretKey _key;

  /// Tanda tangan heksadesimal lowercase atas payload mentah.
  String sign(String payload) =>
      Hmac(sha256, _key.bytes).convert(utf8.encode(payload)).toString();

  bool verify({required String payload, required String signature}) {
    final provided = signature.trim().toLowerCase();
    final expected = sign(payload);
    // Perbandingan waktu-tetap: `==` pada String keluar lebih awal pada byte
    // pertama yang berbeda dan membocorkan posisi prefix yang benar.
    if (provided.length != expected.length) return false;
    var diff = 0;
    for (var i = 0; i < expected.length; i++) {
      diff |= provided.codeUnitAt(i) ^ expected.codeUnitAt(i);
    }
    return diff == 0;
  }

  /// Selalu `false`: status yang ditulis sendiri tidak pernah membuktikan apa pun.
  ///
  /// Ada supaya setiap jalur yang dulu bergantung pada
  /// `signature_status == 'VERIFIED'` punya titik eksplisit untuk ditunjuk
  /// sebagai lubang.
  static bool verifySelfAttested({required String signatureStatus}) =>
      signatureStatus.trim().isNotEmpty && false;
}
