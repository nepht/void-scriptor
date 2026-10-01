/// 117.34 — Billing & Webhook Integrity (gate gagal-tertutup).
///
/// Kontrak untuk delapan `required_evidence` kanonik step `117.34`:
/// `signature`, `idempotency`, `retry`, `event_order`, `entitlement`,
/// `refund`, `chargeback`, `audit`.
///
/// The area list is read verbatim from the canonical `required_evidence` of
/// step `117.34`. No area is taken from a document without a sprint number,
/// and none is added.
///
/// Status satu cek validasi:
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

/// Status satu cek validasi integritas billing dan webhook.
enum Sprint117BillingStatus { pass, violation, unmet }

/// Satu fakta terukur untuk satu bukti integritas billing/webhook.
final class Sprint117BillingCheck {
  const Sprint117BillingCheck({
    required this.area,
    required this.check,
    required this.status,
    required this.declared,
    required this.observed,
    this.note = '',
  });

  const factory Sprint117BillingCheck.pass_({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note,
  }) = Sprint117BillingCheck._pass;

  const factory Sprint117BillingCheck.violation({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note,
  }) = Sprint117BillingCheck._violation;

  const factory Sprint117BillingCheck.unmet({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note,
  }) = Sprint117BillingCheck._unmet;

  const Sprint117BillingCheck._pass({
    required this.area,
    required this.check,
    required this.declared,
    required this.observed,
    this.note = '',
  }) : status = Sprint117BillingStatus.pass;

  const Sprint117BillingCheck._violation({
    required this.area,
    required this.check,
    required this.declared,
    required this.observed,
    this.note = '',
  }) : status = Sprint117BillingStatus.violation;

  const Sprint117BillingCheck._unmet({
    required this.area,
    required this.check,
    required this.declared,
    required this.observed,
    this.note = '',
  }) : status = Sprint117BillingStatus.unmet;

  /// Bukti kanonik; harus salah satu dari
  /// [Sprint117BillingIntegrity.requiredAreas].
  final String area;

  /// Nama cek unik di dalam areanya.
  final String check;

  final Sprint117BillingStatus status;

  /// Pernyataan kontrak yang diuji, selalu non-kosong.
  final String declared;

  /// Nilai hasil pengukuran; selalu non-kosong (cek kosong = `vacuous`).
  final String observed;

  /// Konteks tambahan (sumber angka, alasan `unmet`).
  final String note;

  /// Kode kegagalan stabil `area:check`.
  String get code => '$area:$check';

  bool get isViolation => status == Sprint117BillingStatus.violation;

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
final class Sprint117BillingIntegrityResult {
  const Sprint117BillingIntegrityResult({
    required this.checks,
    required this.failures,
  });

  final List<Sprint117BillingCheck> checks;

  /// Kode kegagalan (`missing_area:…`, `violation:…`, `vacuous:…`, …).
  /// Kosong berarti semua bukti terukur dan lolos.
  final List<String> failures;

  bool get pass => failures.isEmpty;

  List<String> get openItems => checks
      .where((c) => c.status == Sprint117BillingStatus.unmet)
      .map((c) => c.code)
      .toList();

  List<String> get violationCodes =>
      checks.where((c) => c.isViolation).map((c) => c.code).toList();

  /// Ringkasan runtut untuk laporan/ledger.
  String get summary =>
      'pass=$pass checks=${checks.length} failures=${failures.length} '
      'open=${openItems.length}';

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': '117.34',
    'document_role': 'SPRINT_117_34_BILLING_WEBHOOK_INTEGRITY_EVIDENCE',
    'required_areas': Sprint117BillingIntegrity.requiredAreas.toList(),
    'surfaces': Sprint117BillingIntegrity.surfaceLabels,
    'verdict': pass
        ? 'BILLING_WEBHOOK_INTEGRITY_VALIDATED_LOCAL'
        : 'BILLING_WEBHOOK_INTEGRITY_FAILED',
    'pass': pass,
    'failures': failures,
    'open_items': openItems,
    'violation_codes': violationCodes,
    'checks': checks.map((c) => c.toJson()).toList(),
  };
}

/// Gate 117.34: evaluasi gagal-tertutup atas fakta terukur.
abstract final class Sprint117BillingIntegrity {
  /// Bukti kanonik — urutan persis `required_evidence` step `117.34`.
  static const List<String> requiredAreas = <String>[
    'signature',
    'idempotency',
    'retry',
    'event_order',
    'entitlement',
    'refund',
    'chargeback',
    'audit',
  ];

  /// Permukaan tempat tiap bukti diukur (pelaporan, bukan batas pengukuran).
  static const Map<String, String> surfaceLabels = <String, String>{
    'signature':
        'AccountCenterSecurityBillingVerification.verifyWebhook constant-time '
        'HMAC-SHA256 over v1:<ts>:<body>, malformed header rejected before '
        'hashing; Sprint116BillingReconciliation rejects any signatureStatus '
        'that is not VERIFIED',
    'idempotency':
        'Sprint116BillingReconciliation id consumption and '
        'AccountWebhookReplayGuard.isReplay retention window; a provider retry '
        'must not bill twice',
    'retry':
        'Sprint116BillingReconciliationContract.maxRetryCount bound and '
        'Sprint116RetryPolicy/Sprint116RetryAttempt backoff evidence',
    'event_order':
        'Sprint116BillingReconciliation sequence sort applied AFTER '
        'authenticity, so an out-of-order or forged delivery cannot reorder '
        'or evict a genuine renewal',
    'entitlement':
        'AccountCenterSubscriptionEntitlementModel.entitlementStateAt window + '
        '_lapseInstant, Agreement with Sprint116OfflineEntitlement snapshot',
    'refund':
        'AccountCenterInvoiceHistory.refundableRemaining, InvoiceRefund '
        'settle/reject/cancel terminal guards, and the derived '
        'partially_refunded verdict in paymentStatusFor',
    'chargeback':
        'InvoiceDispute.resolve terminal verdicts and the won-dispute refund '
        'derivation in paymentStatusFor/refundableRemaining',
    'audit':
        'AccountCenterInvoiceHistory.audit must record every money-moving '
        'transition, not only the request that asked for it',
  };

  static Sprint117BillingIntegrityResult evaluate(
    List<Sprint117BillingCheck> checks,
  ) {
    if (checks.isEmpty) {
      return const Sprint117BillingIntegrityResult(
        checks: <Sprint117BillingCheck>[],
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
      // what lets a failed axis report as validated: the failure list then says
      // only that something was violated, never which evidence area failed.
      final hasPass = inArea.any(
        (c) => c.status == Sprint117BillingStatus.pass,
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
    return Sprint117BillingIntegrityResult(
      checks: List<Sprint117BillingCheck>.unmodifiable(checks),
      failures: List<String>.unmodifiable(failures),
    );
  }
}
