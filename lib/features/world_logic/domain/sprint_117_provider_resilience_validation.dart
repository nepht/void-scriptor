// Copyright 2026 Choirudin. All rights reserved.
//
// Sprint 117.36 — Provider Resilience & Recovery.
//
// Fail-closed gate: menguji 8 bukti kanonik (timeout, throttling, retry_after,
// circuit_breaker, cancellation, outage, queue_recovery, kill_switch) sebagai
// kondisi TERUKUR terhadap seam runtime yang benar-benar di-ship. Bentuk
// kegagalan identik dengan slice 117.35: area tanpa check = missing_area, area
// yang hanya punya status pass tanpa predikat terukur = vacuous, area dengan
// satu violation = area_without_pass, area tak dideklarasikan = unknown_area,
// cek terulang = duplicate_check.
//
// Catatan cakupan yang tidak boleh disembunyikan: circuit breaker sebagai
// komponen runtime TIDAK ada di build ini. Yang ada adalah (a) state machine
// koneksi yang RiSE menjadi breaker (retry bounded -> unavailable -> reauth),
// dan (b) fallbackserta rate limiter. Sumbu circuit_breaker karena itu diuji
// pada perilaku yang benar-benar di-ship, dan bagian yang butuh komponen
// breaker penuh dilaporkan unmet, bukan dicatat pass.
//
// Anchor kontrak:
// sprint_117.json step 117.36 required_evidence (urutan persis di bawah).
// Seam runtime: AiProviderWithTimeout (provider_timeout.dart),
// AiProviderRateLimiter (provider_rate_limiter.dart),
// ProviderRouter.generateReportingServingProvider (provider_router.dart),
// AccountConnectionHealthStateMachine + AccountConnectionRetryPolicy
// (account_center_connection_health_state_machine.dart),
// FeatureFlagRegistry.killSwitchActive (feature_flag_registry.dart),
// BackgroundJobQueue.pause/resume/drain (background_job_queue.dart).
library;

/// Status satu cek validasi.
enum Sprint117ResilienceStatus { pass, violation, unmet }

/// Satu fakta terukur untuk satu bukti ketahanan provider.
final class Sprint117ResilienceCheck {
  const Sprint117ResilienceCheck({
    required this.area,
    required this.check,
    required this.status,
    required this.declared,
    required this.observed,
    this.note = '',
  });

  const factory Sprint117ResilienceCheck.pass_({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note,
  }) = Sprint117ResilienceCheck._pass;

  const factory Sprint117ResilienceCheck.violation({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note,
  }) = Sprint117ResilienceCheck._violation;

  const factory Sprint117ResilienceCheck.unmet({
    required String area,
    required String check,
    required String declared,
    required String observed,
    String note,
  }) = Sprint117ResilienceCheck._unmet;

  const Sprint117ResilienceCheck._pass({
    required this.area,
    required this.check,
    required this.declared,
    required this.observed,
    this.note = '',
  }) : status = Sprint117ResilienceStatus.pass;

  const Sprint117ResilienceCheck._violation({
    required this.area,
    required this.check,
    required this.declared,
    required this.observed,
    this.note = '',
  }) : status = Sprint117ResilienceStatus.violation;

  const Sprint117ResilienceCheck._unmet({
    required this.area,
    required this.check,
    required this.declared,
    required this.observed,
    this.note = '',
  }) : status = Sprint117ResilienceStatus.unmet;

  /// Bukti kanonik; harus salah satu dari [Sprint117ProviderResilience.requiredAreas].
  final String area;

  /// Nama cek unik di dalam areanya.
  final String check;

  final Sprint117ResilienceStatus status;

  /// Pernyataan kontrak yang diuji, selalu non-kosong.
  final String declared;

  /// Nilai hasil pengukuran; selalu non-kosong (cek kosong = `vacuous`).
  final String observed;

  /// Konteks tambahan (sumber angka, alasan `unmet`).
  final String note;

  /// Kode kegagalan stabil `area:check`.
  String get code => '$area:$check';

  bool get isViolation => status == Sprint117ResilienceStatus.violation;

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
final class Sprint117ResilienceResult {
  const Sprint117ResilienceResult({
    required this.checks,
    required this.failures,
  });

  final List<Sprint117ResilienceCheck> checks;

  /// Kode kegagalan (`missing_area:...`, `violation:...`, `vacuous:...`, ...).
  /// Kosong berarti semua bukti terukur dan lolos.
  final List<String> failures;

  bool get pass => failures.isEmpty;

  List<String> get openItems => checks
      .where((c) => c.status == Sprint117ResilienceStatus.unmet)
      .map((c) => c.code)
      .toList();

  List<String> get violationCodes =>
      checks.where((c) => c.isViolation).map((c) => c.code).toList();

  /// Ringkasan runtut untuk laporan/ledger.
  String get summary =>
      'pass=$pass checks=${checks.length} failures=${failures.length} '
      'open=${openItems.length}';

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': '117.36',
    'document_role': 'SPRINT_117_36_PROVIDER_RESILIENCE_EVIDENCE',
    'required_areas': Sprint117ProviderResilience.requiredAreas.toList(),
    'surfaces': Sprint117ProviderResilience.surfaceLabels,
    'verdict': pass
        ? 'PROVIDER_RESILIENCE_VALIDATED_LOCAL'
        : 'PROVIDER_RESILIENCE_FAILED',
    'pass': pass,
    'failures': failures,
    'open_items': openItems,
    'violation_codes': violationCodes,
    'checks': checks.map((c) => c.toJson()).toList(),
  };
}

/// Gate 117.36: evaluasi gagal-tertutup atas fakta terukur.
abstract final class Sprint117ProviderResilience {
  /// Bukti kanonik - urutan persis `required_evidence` step `117.36`.
  static const List<String> requiredAreas = <String>[
    'timeout',
    'throttling',
    'retry_after',
    'circuit_breaker',
    'cancellation',
    'outage',
    'queue_recovery',
    'kill_switch',
  ];

  /// Permukaan tempat tiap bukti diukur (pelaporan, bukan batas pengukuran).
  static const Map<String, String> surfaceLabels = <String, String>{
    'timeout':
        'AiProviderWithTimeout wraps every operation; a zero/negative budget '
        'is rejected at construction and an exceeded budget surfaces '
        'AiProviderTimeoutException instead of a raw TimeoutException.',
    'throttling':
        'AiProviderRateLimiter.allow() records inside a bounded window; '
        'invalid limits (empty id, maxRequests<=0, window<=zero) are refused '
        'at construction and an unknown provider is never allowed.',
    'retry_after':
        'AiProviderRateLimiter.retryAfter() reports the wait until the oldest '
        'window entry expires, Duration.zero when a slot is free, and null '
        'for an unknown provider; the Account Center retry message renders '
        'the window truthfully and rejects a non-positive retryAfter.',
    'circuit_breaker':
        'AccountConnectionHealthStateMachine + AccountConnectionRetryPolicy: '
        'a bounded retry budget raises StateError once exhausted instead of '
        'reconnecting forever, a REVOKED connection is terminal (no outbound '
        'transition at all, so a revoked provider cannot quietly come back), '
        'and ProviderRouter.generateReportingServingProvider walks the next '
        'capable provider when the primary keeps throwing and reports which '
        'provider actually served the request. An OPEN/HALF_OPEN breaker '
        'component with a cooldown timer is not shipped; that half is '
        'reported unmet, never passed.',
    'cancellation':
        'AiProvider.cancel(requestId) is part of the provider contract and '
        'the timeout wrapper delegates it unmodified; a request cancelled '
        'through the wrapper must reach the delegate exactly once.',
    'outage':
        'AccountConnectionHealthStateMachine outage transitions and '
        'AiProviderHealthProbe: a throwing provider probe reports '
        'unavailable with an error message instead of pretending healthy.',
    'queue_recovery':
        'BackgroundJobQueue pause/resume/drain: pause by priority threshold '
        'holds scheduling, resume releases it, and drain resolves only on a '
        'genuinely empty queue.',
    'kill_switch':
        'FeatureFlagRegistry.engageKillSwitch forces every flag off, makes '
        'isEnabled false for all, and stays engaged until an explicit '
        'disengage or re-enable.',
  };

  static Sprint117ResilienceResult evaluate(
    List<Sprint117ResilienceCheck> checks,
  ) {
    if (checks.isEmpty) {
      return const Sprint117ResilienceResult(
        checks: <Sprint117ResilienceCheck>[],
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
      final hasPass = inArea.any(
        (c) => c.status == Sprint117ResilienceStatus.pass,
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
    return Sprint117ResilienceResult(
      checks: List<Sprint117ResilienceCheck>.unmodifiable(checks),
      failures: List<String>.unmodifiable(failures),
    );
  }
}
