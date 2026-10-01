/// 117.31 — OAuth Reauth & Revocation Validation (gate gagal-tertutup).
///
/// Kontrak gagal-tertutup untuk tujuh `required_evidence` kanonik step
/// `117.31` (`expiry`, `rotation`, `reauth`, `provider_revoke`, `disconnect`,
/// `cleanup`, `local_data_preserved`).
///
/// Status per cek:
/// * `pass` — nilai yang di-ship sama persis dengan nilai yang diklaim;
/// * `violation` — permukaan menampilkan/menjumlahkan Y padahal nilai yang
///   benar adalah X;
/// * `unmet` — tuntutan kontrak tidak punya jalur perbaikan di slice ini,
///   dilaporkan sebagai `open_items`, bukan pelanggaran.
///
/// Kegagalan struktural membuat `pass == false`: area tanpa cek
/// (`missing_area`), area tanpa satu pun `pass` atau yang membawa pelanggaran
/// terukur (`area_without_pass`), `declared`/`observed` kosong (`vacuous`),
/// duplikat `(area, check)` (`duplicate_check`), area di luar daftar wajib
/// (`unknown_area`), dan `no_checks`.
///
/// Murni Dart tanpa dependensi Flutter supaya gate bisa dievaluasi ulang dari
/// fakta yang sudah direkam.
library;

/// Status satu cek validasi OAuth reauth/revocation.
enum Sprint117OAuthRevocationStatus { pass, violation, unmet }

/// Satu fakta terukur untuk satu bukti validasi OAuth reauth/revocation.
final class Sprint117OAuthRevocationCheck {
  const Sprint117OAuthRevocationCheck({
    required this.area,
    required this.check,
    required this.status,
    required this.declared,
    required this.observed,
    this.note = '',
  });

  factory Sprint117OAuthRevocationCheck.pass_({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117OAuthRevocationCheck(
    area: area,
    check: check,
    status: Sprint117OAuthRevocationStatus.pass,
    declared: declared,
    observed: observed,
    note: note,
  );

  factory Sprint117OAuthRevocationCheck.violation({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117OAuthRevocationCheck(
    area: area,
    check: check,
    status: Sprint117OAuthRevocationStatus.violation,
    declared: declared,
    observed: observed,
    note: note,
  );

  factory Sprint117OAuthRevocationCheck.unmet({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117OAuthRevocationCheck(
    area: area,
    check: check,
    status: Sprint117OAuthRevocationStatus.unmet,
    declared: declared,
    observed: observed,
    note: note,
  );

  /// Bukti kanonik; harus salah satu dari
  /// [Sprint117OAuthRevocationValidation.requiredAreas].
  final String area;

  /// Nama cek unik di dalam areanya.
  final String check;

  final Sprint117OAuthRevocationStatus status;

  /// Pernyataan kontrak yang diuji, selalu non-kosong.
  final String declared;

  /// Nilai hasil pengukuran; selalu non-kosong (cek kosong = `vacuous`).
  final String observed;

  /// Konteks tambahan (sumber angka, alasan `unmet`).
  final String note;

  /// Kode kegagalan stabil `area:check`.
  String get code => '$area:$check';

  bool get isViolation => status == Sprint117OAuthRevocationStatus.violation;

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
final class Sprint117OAuthRevocationValidationResult {
  const Sprint117OAuthRevocationValidationResult({
    required this.checks,
    required this.failures,
  });

  final List<Sprint117OAuthRevocationCheck> checks;

  /// Kode kegagalan (`missing_area:…`, `violation:…`, `vacuous:…`, …).
  /// Kosong berarti ketujuh bukti terukur dan lolos.
  final List<String> failures;

  bool get pass => failures.isEmpty;

  List<String> get openItems => checks
      .where((c) => c.status == Sprint117OAuthRevocationStatus.unmet)
      .map((c) => c.code)
      .toList();

  List<String> get violationCodes =>
      checks.where((c) => c.isViolation).map((c) => c.code).toList();

  /// Ringkasan runtut untuk laporan/ledger.
  String get summary =>
      'pass=$pass checks=${checks.length} failures=${failures.length} '
      'open=${openItems.length}';

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': '117.31',
    'document_role': 'SPRINT_117_31_OAUTH_REAUTH_REVOCATION_EVIDENCE',
    'required_areas': Sprint117OAuthRevocationValidation.requiredAreas.toList(),
    'surfaces': Sprint117OAuthRevocationValidation.surfaceLabels,
    'verdict': pass
        ? 'OAUTH_REAUTH_REVOCATION_VALIDATED_LOCAL'
        : 'OAUTH_REAUTH_REVOCATION_VALIDATION_FAILED',
    'pass': pass,
    'failures': failures,
    'open_items': openItems,
    'violation_codes': violationCodes,
    'checks': checks.map((c) => c.toJson()).toList(),
  };
}

/// Gate 117.31: evaluasi gagal-tertutup atas fakta terukur.
abstract final class Sprint117OAuthRevocationValidation {
  /// Tujuh bukti kanonik — urutan persis `required_evidence` step `117.31`.
  static const List<String> requiredAreas = <String>[
    'expiry',
    'rotation',
    'reauth',
    'provider_revoke',
    'disconnect',
    'cleanup',
    'local_data_preserved',
  ];

  /// Permukaan tempat tiap bukti diukur (pelaporan, bukan batas pengukuran).
  static const Map<String, String> surfaceLabels = <String, String>{
    'expiry':
        'OAuthTokenGrant.accessTokenExpiresAt -> OAuthTokenGrant.isExpiredAt '
        '+ AccountOAuthFlow._validateTokenResponse',
    'rotation':
        'OAuthTokenResponse.refreshToken -> OAuthFlowErrorCode.'
        'refreshTokenNotRotated + OAuthTokenGrant.generation',
    'reauth':
        'AccountOAuthFlow.rotateTokens -> LinkedIdentity.tokenGeneration + '
        'AccountConnectedAccountsManagement.reauthRequired',
    'provider_revoke':
        'OAuthTokenBroker.revoke -> OAuthFlowErrorCode.revocationFailed + '
        'AccountConnectedAccountsManagement.unlink',
    'disconnect':
        'AccountOAuthFlow.unlink(OAuthUnlinkDecision.unlink) + '
        'AccountConnectedAccountsManagement.unlink(confirmed: true)',
    'cleanup':
        'AccountSecureTokenVault.revoke -> store delete + held-clipboard wipe '
        'matching the revoked key + VaultAuditEvent.kind/secretId',
    'local_data_preserved':
        'AccountCenterTokenExpiryReauthenticationUx.localDataPreserved + '
        'AccountSecureTokenVault (non-local secrets) after revoke',
  };

  static Sprint117OAuthRevocationValidationResult evaluate(
    List<Sprint117OAuthRevocationCheck> checks,
  ) {
    if (checks.isEmpty) {
      return const Sprint117OAuthRevocationValidationResult(
        checks: <Sprint117OAuthRevocationCheck>[],
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
        (c) => c.status == Sprint117OAuthRevocationStatus.pass,
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
    return Sprint117OAuthRevocationValidationResult(
      checks: List<Sprint117OAuthRevocationCheck>.unmodifiable(checks),
      failures: List<String>.unmodifiable(failures),
    );
  }
}
