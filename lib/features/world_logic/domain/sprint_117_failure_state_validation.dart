/// 117.28 — Failure-State Validation.
///
/// Kontrak gagal-tertutup untuk sembilan state kegagalan wajib step kanonik
/// `117.28` (`required_states`: `expired`, `revoked`, `scope_denied`,
/// `rate_limited`, `outage`, `region_block`, `unsupported_plan`,
/// `partial_data`, `error`).
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
/// Anchor: `AccountCenterLoadingEmptyErrorStates` (115.42 surface contract
/// yang memodelkan state kegagalan + `retryAfter` + `canRetry`), state
/// machine koneksi 115.10 (`expired`/`revoked` terminal + recovery copy),
/// OAuth 115.11 (`scope_denied` lewat `scopeEscalation`), dan gate
/// fail-closed `requireAvailableForCheckout` (115.51 region) serta
/// `entitlementStateAt` (115.54 plan).
///
/// Murni Dart tanpa dependensi Flutter supaya gate bisa dievaluasi ulang
/// dari fakta yang sudah direkam.
library;

/// Status satu cek failure-state.
enum Sprint117FailureStateStatus { pass, violation, unmet }

/// Satu fakta terukur untuk sebuah state kegagalan.
final class Sprint117FailureStateCheck {
  const Sprint117FailureStateCheck({
    required this.area,
    required this.check,
    required this.status,
    required this.declared,
    required this.observed,
    this.note = '',
  });

  factory Sprint117FailureStateCheck.pass({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117FailureStateCheck(
    area: area,
    check: check,
    status: Sprint117FailureStateStatus.pass,
    declared: declared,
    observed: observed,
    note: note,
  );

  factory Sprint117FailureStateCheck.violation({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117FailureStateCheck(
    area: area,
    check: check,
    status: Sprint117FailureStateStatus.violation,
    declared: declared,
    observed: observed,
    note: note,
  );

  factory Sprint117FailureStateCheck.unmet({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117FailureStateCheck(
    area: area,
    check: check,
    status: Sprint117FailureStateStatus.unmet,
    declared: declared,
    observed: observed,
    note: note,
  );

  /// State kegagalan kanonik; harus salah satu dari
  /// [Sprint117FailureStateValidation.requiredStates].
  final String area;

  /// Nama cek unik di dalam areanya.
  final String check;

  final Sprint117FailureStateStatus status;

  /// Pernyataan kontrak yang diuji, selalu non-kosong.
  final String declared;

  /// Nilai hasil pengukuran; selalu non-kosong (cek kosong = `vacuous`).
  final String observed;

  /// Konteks tambahan (sumber angka, alasan `unmet`).
  final String note;

  /// Kode kegagalan stabil `area:check`.
  String get code => '$area:$check';

  bool get isViolation => status == Sprint117FailureStateStatus.violation;

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
final class Sprint117FailureStateValidationResult {
  const Sprint117FailureStateValidationResult({
    required this.checks,
    required this.failures,
  });

  final List<Sprint117FailureStateCheck> checks;

  /// Kode kegagalan (`missing_area:…`, `violation:…`, `vacuous:…`, …).
  /// Kosong berarti seluruh sembilan state terukur dan lolos.
  final List<String> failures;

  bool get pass => failures.isEmpty;

  /// Cek `unmet`: kontrak yang tidak punya jalur perbaikan di slice ini,
  /// dilaporkan terbuka.
  List<String> get openItems => checks
      .where((c) => c.status == Sprint117FailureStateStatus.unmet)
      .map((c) => c.code)
      .toList();

  List<String> get violationCodes =>
      checks.where((c) => c.isViolation).map((c) => c.code).toList();

  /// Ringkasan runtut untuk laporan/ledger.
  String get summary =>
      'pass=$pass checks=${checks.length} failures=${failures.length} '
      'open=${openItems.length}';

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': '117.28',
    'document_role': 'SPRINT_117_28_FAILURE_STATE_VALIDATION_EVIDENCE',
    'required_states': Sprint117FailureStateValidation.requiredStates.toList(),
    'surfaces': Sprint117FailureStateValidation.surfaceLabels,
    'verdict': pass
        ? 'FAILURE_STATE_VALIDATION_LOCAL'
        : 'FAILURE_STATE_VALIDATION_FAILED',
    'pass': pass,
    'failures': failures,
    'open_items': openItems,
    'violation_codes': violationCodes,
    'checks': checks.map((c) => c.toJson()).toList(),
  };
}

/// Gate 117.28: evaluasi gagal-tertutup atas fakta terukur.
abstract final class Sprint117FailureStateValidation {
  /// Sembilan state wajib — urutan persis `required_states` kanonik.
  static const List<String> requiredStates = <String>[
    'expired',
    'revoked',
    'scope_denied',
    'rate_limited',
    'outage',
    'region_block',
    'unsupported_plan',
    'partial_data',
    'error',
  ];

  /// Permukaan tempat tiap state diukur (pelaporan, bukan batas pengukuran).
  static const Map<String, String> surfaceLabels = <String, String>{
    'expired': 'AccountConnectionHealthStateMachine.expire + reauthRequired',
    'revoked': 'AccountConnectionHealthStateMachine.revoke + terminal state',
    'scope_denied': 'OAuthFlowException(scopeEscalation) atas scope subset',
    'rate_limited': 'AccountCenterLoadingEmptyErrorStates.rateLimited',
    'outage': 'AccountCenterLoadingEmptyErrorStates.outage',
    'region_block': 'AccountCenterPaymentMethods.requireAvailableForCheckout',
    'unsupported_plan':
        'AccountCenterSubscriptionEntitlementModel.entitlementStateAt',
    'partial_data': 'AccountCenterLoadingEmptyErrorStates.partial',
    'error':
        'AccountCenterLoadingEmptyErrorStates.error + visible-error validation',
  };

  static Sprint117FailureStateValidationResult evaluate(
    List<Sprint117FailureStateCheck> checks,
  ) {
    if (checks.isEmpty) {
      return const Sprint117FailureStateValidationResult(
        checks: <Sprint117FailureStateCheck>[],
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
    for (final area in requiredStates) {
      final inArea = checks.where((c) => c.area == area).toList();
      if (inArea.isEmpty) {
        failures.add('missing_area:$area');
        continue;
      }
      if (inArea.every((c) => c.status != Sprint117FailureStateStatus.pass)) {
        failures.add('area_without_pass:$area');
      }
    }
    final known = requiredStates.toSet();
    if (known.length != requiredStates.length) {
      failures.add('non_canonical_required_states');
    }
    for (final area in checks.map((c) => c.area).toSet()) {
      if (!known.contains(area)) {
        failures.add('unknown_area:$area');
      }
    }
    return Sprint117FailureStateValidationResult(
      checks: List<Sprint117FailureStateCheck>.unmodifiable(checks),
      failures: List<String>.unmodifiable(failures),
    );
  }
}
