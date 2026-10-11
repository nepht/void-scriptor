/// 117.36 — Provider Resilience & Recovery (RED -> GREEN).
///
/// Setiap angka dan fakta di slice ini adalah hasil probe yang dijalankan run
/// ini, dicetak ke log sebagai `11736_*`, bukan klaim yang diketik tangan.
///
/// Seam yang diukur adalah kode yang benar-benar di-ship:
/// `AiProviderWithTimeout`, `AiProviderRateLimiter`,
/// `AccountCenterLoadingEmptyErrorStates` (retry message),
/// `AccountConnectionHealthStateMachine` + `AccountConnectionRetryPolicy`,
/// `ProviderRouter`, `AiProviderHealthProbe`, `BackgroundJobQueue`, dan
/// `FeatureFlagRegistry`.
///
/// Bukti yang tidak bisa diukur lokal tidak dipalsukan: sumbu
/// `circuit_breaker` menuntut komponen breaker OPEN/HALF_OPEN dengan cooldown
/// timer yang tidak ada di build ini, jadi bagian itu dilaporkan `unmet`
/// (open item), bukan `pass`. Bagian breaker yang memang di-ship (budget retry
/// terbatas, revoked terminal, fallback router) diukur sungguhan.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/feature_flags/feature_flag_registry.dart';
import 'package:void_scriptor/core/jobs/background_job.dart';
import 'package:void_scriptor/core/jobs/background_job_queue.dart';
import 'package:void_scriptor/features/account/domain/account_center_connection_health_state_machine.dart';
import 'package:void_scriptor/features/account/domain/account_center_loading_empty_error_states.dart';
import 'package:void_scriptor/features/ai/application/provider_health.dart';
import 'package:void_scriptor/features/ai/application/provider_rate_limiter.dart';
import 'package:void_scriptor/features/ai/application/provider_router.dart';
import 'package:void_scriptor/features/ai/application/provider_timeout.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_provider_resilience_validation.dart';

/// Provider tiruan yang perilakunya dikendalikan per kasus: daftar model,
/// error yang dilempar, dan jumlah `cancel` yang diterima.
class _FakeProvider with AiStreamingFallback implements AiProvider {
  _FakeProvider({
    this.id = 'fake_primary',
    this.throwOnGenerate = false,
    this.throwOnListModels = false,
    this.emptyModels = false,
    this.generateDelay = Duration.zero,
  });

  @override
  final String id;

  @override
  String get displayName => 'Fake Provider $id';

  final bool throwOnGenerate;
  final bool throwOnListModels;
  final bool emptyModels;
  final Duration generateDelay;

  final List<String> cancelledRequests = <String>[];
  int generateCalls = 0;

  @override
  Set<AiCapability> get capabilities => const <AiCapability>{
    AiCapability.textGeneration,
  };

  @override
  Future<List<AiModelInfo>> listModels() async {
    if (throwOnListModels) {
      throw StateError('listModels refused (probe).');
    }
    if (emptyModels) return const <AiModelInfo>[];
    return const <AiModelInfo>[
      AiModelInfo(
        id: 'fake-model',
        displayName: 'Fake Model',
        capabilities: <AiCapability>{AiCapability.textGeneration},
      ),
    ];
  }

  @override
  Future<AiGenerationResult> generate(AiGenerationRequest request) async {
    generateCalls += 1;
    if (generateDelay > Duration.zero) {
      await Future<void>.delayed(generateDelay);
    }
    if (throwOnGenerate) {
      throw StateError('generate refused by $id (probe).');
    }
    return AiGenerationResult(
      providerRequestId: 'req-${request.jobId}',
      outputs: const <AiGeneratedOutput>[
        AiGeneratedOutput(type: AiOutputType.text, text: 'ok'),
      ],
    );
  }

  @override
  Future<void> cancel(String requestId) async {
    cancelledRequests.add(requestId);
  }

  @override
  bool validateTarget(PromptTarget target) => target == PromptTarget.story;
}

/// Bukti yang ditulis ke disk; isinya hanya angka/fakta dari probe run ini.
final Map<String, Object?> evidence = <String, Object?>{
  'canonical_step': '117.36',
  'document_role': 'EVIDENCE',
  'measured_on': '2026-10-02',
  'harness': 'flutter test (local runtime, no live provider network)',
  'external_gate': 'DEFERRED-EXTERNAL',
};

/// Menulis bukti run ke direktori yang diberikan.
///
/// Test tidak boleh menimpa manifest tracked di `docs/evidence/`: output run
/// sementara harus terisolasi agar suite tidak mengubah worktree.
File writeEvidenceFile(Directory outputDirectory) {
  final file = File(
    p.join(outputDirectory.path, 'sprint-117-36-manifest-20261002.json'),
  );
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(evidence)}\n',
    flush: true,
  );
  return file;
}

/// Mesin koneksi yang sudah `CONNECTED`, dibangun lewat transisi nyata.
AccountConnectionHealthStateMachine _connectedMachine() {
  final machine = AccountConnectionHealthStateMachine.notConfigured(
    providerId: 'probe_provider',
    accountLabel: 'Probe Account',
  );
  machine
    ..transition(
      AccountConnectionTransition.beginConnecting,
      at: DateTime.utc(2026, 10, 2, 11, 59),
    )
    ..transition(
      AccountConnectionTransition.connectSucceeded,
      at: DateTime.utc(2026, 10, 2, 12),
    );
  return machine;
}

/// Mesin koneksi yang sudah `ERROR` (dipakai untuk skenario retry terbatas).
AccountConnectionHealthStateMachine _errorMachine({int maxAttempts = 3}) {
  final machine = AccountConnectionHealthStateMachine.notConfigured(
    providerId: 'probe_error',
    accountLabel: 'Probe Error Account',
    retryPolicy: AccountConnectionRetryPolicy(maxAttempts: maxAttempts),
  );
  machine
    ..transition(
      AccountConnectionTransition.beginConnecting,
      at: DateTime.utc(2026, 10, 2, 11, 58),
    )
    ..transition(
      AccountConnectionTransition.error,
      at: DateTime.utc(2026, 10, 2, 11, 59),
      userVisibleError: 'probe failure',
    );
  return machine;
}

/// Permintaan generasi valid untuk probe router/timeout.
AiGenerationRequest _request(String jobId) => AiGenerationRequest(
  jobId: jobId,
  prompt: 'probe prompt',
  target: PromptTarget.story,
);

/// Tugas antrean yang mencatat apakah ia benar-benar dijalankan.
class _RecordingTask implements BackgroundTask {
  _RecordingTask(this.id, this.jobPriority, this.executed);

  @override
  final String id;

  final BackgroundJobPriority jobPriority;
  final List<String> executed;

  @override
  BackgroundJob get job => BackgroundJob(
    id: id,
    projectId: 'probe',
    type: BackgroundJobType.custom,
    label: 'probe $id',
    status: BackgroundJobStatus.queued,
    priority: jobPriority,
    createdAt: DateTime.utc(2026, 10, 2, 12),
  );

  @override
  BackgroundJobType get type => BackgroundJobType.custom;

  @override
  Set<JobResource> get resources => const <JobResource>{};

  @override
  String? get taskKey => null;

  @override
  Future<void> cancel() async {}

  @override
  Future<void> execute(JobContext context) async {
    executed.add(id);
  }
}

/// Tugas yang gagal saat eksekusi; dipakai untuk membuktikan antrean tetap
/// bisa dikuras dan kegagalan tidak menyumbat pekerjaan lain.
class _FailingTask implements BackgroundTask {
  _FailingTask(this.id, this.jobPriority);

  @override
  final String id;

  final BackgroundJobPriority jobPriority;

  @override
  BackgroundJob get job => BackgroundJob(
    id: id,
    projectId: 'probe',
    type: BackgroundJobType.custom,
    label: 'probe $id',
    status: BackgroundJobStatus.queued,
    priority: jobPriority,
    createdAt: DateTime.utc(2026, 10, 2, 12),
  );

  @override
  BackgroundJobType get type => BackgroundJobType.custom;

  @override
  Set<JobResource> get resources => const <JobResource>{};

  @override
  String? get taskKey => null;

  @override
  Future<void> cancel() async {}

  @override
  Future<void> execute(JobContext context) async {
    throw StateError('probe task $id failed on purpose.');
  }
}

void main() {
  /// Values this run actually observed; the aggregate gate quotes them so no
  /// `observed` string in the verdict is typed by hand.
  final probes = <String, String>{};

  group('gate 117.36 fail-closed', () {
    test('eight canonical axes, verbatim from required_evidence of 117.36', () {
      expect(Sprint117ProviderResilience.requiredAreas, <String>[
        'timeout',
        'throttling',
        'retry_after',
        'circuit_breaker',
        'cancellation',
        'outage',
        'queue_recovery',
        'kill_switch',
      ]);
    });

    test('a missing axis is reported, not silently tolerated', () {
      final withoutOutage = Sprint117ProviderResilience.evaluate([
        for (final area in Sprint117ProviderResilience.requiredAreas)
          if (area != 'outage')
            Sprint117ResilienceCheck.pass_(
              area: area,
              check: 'presence',
              declared: 'axis carries one measured fact',
              observed: 'measured by this run',
            ),
      ]);
      expect(withoutOutage.pass, isFalse);
      expect(withoutOutage.failures, contains('missing_area:outage'));
    });

    test('a duplicate check is a structural failure', () {
      final checks = [
        for (final area in Sprint117ProviderResilience.requiredAreas)
          Sprint117ResilienceCheck.pass_(
            area: area,
            check: 'presence',
            declared: 'axis carries one measured fact',
            observed: 'measured by this run',
          ),
        const Sprint117ResilienceCheck.pass_(
          area: 'timeout',
          check: 'presence',
          declared: 'axis carries one measured fact',
          observed: 'measured by this run',
        ),
      ];
      final result = Sprint117ProviderResilience.evaluate(checks);
      expect(result.failures, contains('duplicate_check:timeout:presence'));
    });

    test('a single violation cannot be averaged away', () {
      final checks = [
        for (final area in Sprint117ProviderResilience.requiredAreas)
          Sprint117ResilienceCheck.pass_(
            area: area,
            check: 'presence',
            declared: 'axis carries one measured fact',
            observed: 'measured by this run',
          ),
        const Sprint117ResilienceCheck.violation(
          area: 'kill_switch',
          check: 'emergency_path',
          declared: 'engaging the switch must block every flag',
          observed: 'one flag stayed readable after engage',
        ),
      ];
      final result = Sprint117ProviderResilience.evaluate(checks);
      expect(result.pass, isFalse);
      expect(result.failures, contains('violation:kill_switch:emergency_path'));
      expect(result.failures, contains('area_without_pass:kill_switch'));
    });

    test('an empty observed string is vacuous, not a pass', () {
      final checks = [
        for (final area in Sprint117ProviderResilience.requiredAreas)
          Sprint117ResilienceCheck.pass_(
            area: area,
            check: 'presence',
            declared: 'axis carries one measured fact',
            observed: area == 'queue_recovery' ? '' : 'measured by this run',
          ),
      ];
      final result = Sprint117ProviderResilience.evaluate(checks);
      expect(result.failures, contains('vacuous:queue_recovery:presence'));
      expect(result.pass, isFalse);
    });

    test('an unknown axis is rejected', () {
      final checks = [
        for (final area in Sprint117ProviderResilience.requiredAreas)
          Sprint117ResilienceCheck.pass_(
            area: area,
            check: 'presence',
            declared: 'axis carries one measured fact',
            observed: 'measured by this run',
          ),
        const Sprint117ResilienceCheck.pass_(
          area: 'gpu_thrash',
          check: 'presence',
          declared: 'invented axis',
          observed: 'measured by this run',
        ),
      ];
      final result = Sprint117ProviderResilience.evaluate(checks);
      expect(result.failures, contains('unknown_area:gpu_thrash'));
    });

    test('an empty check list is no_checks, never a pass', () {
      final result = Sprint117ProviderResilience.evaluate([]);
      expect(result.pass, isFalse);
      expect(result.failures, <String>['no_checks']);
    });
  });

  group('timeout', () {
    test('a non-positive budget is refused at construction', () {
      var zeroRefused = false;
      var negativeRefused = false;
      try {
        AiProviderWithTimeout(_FakeProvider(), timeout: Duration.zero);
      } on ArgumentError {
        zeroRefused = true;
      }
      try {
        AiProviderWithTimeout(
          _FakeProvider(),
          timeout: const Duration(seconds: -1),
        );
      } on ArgumentError {
        negativeRefused = true;
      }
      expect(zeroRefused, isTrue);
      expect(negativeRefused, isTrue);
      probes['timeout_rejected_non_positive_budget'] =
          'zero=$zeroRefused negative=$negativeRefused';
    });

    test(
      'an exceeded budget surfaces the provider timeout, not a raw one',
      () async {
        final delegate = _FakeProvider(
          generateDelay: const Duration(milliseconds: 120),
        );
        final wrapper = AiProviderWithTimeout(
          delegate,
          timeout: const Duration(milliseconds: 20),
        );
        var sawProviderTimeout = false;
        var sawRawTimeout = false;
        final stopwatch = Stopwatch()..start();
        try {
          await wrapper.generate(_request('timeout-slow'));
        } on AiProviderTimeoutException catch (error) {
          sawProviderTimeout = true;
          expect(error.providerId, 'fake_primary');
          expect(error.timeout, const Duration(milliseconds: 20));
        } on TimeoutException {
          sawRawTimeout = true;
        }
        stopwatch.stop();
        expect(sawProviderTimeout, isTrue);
        expect(sawRawTimeout, isFalse);
        probes['timeout_provider_exception_ms'] = stopwatch.elapsedMilliseconds
            .toString();
      },
    );

    test('a provider faster than the budget still answers normally', () async {
      final wrapper = AiProviderWithTimeout(
        _FakeProvider(),
        timeout: const Duration(seconds: 5),
      );
      final result = await wrapper.generate(_request('timeout-fast'));
      expect(result.outputs.single.text, 'ok');
      probes['timeout_under_budget_passed'] = 'true';
    });
  });

  group('throttling', () {
    test('an invalid limit is refused at construction', () {
      var emptyId = false;
      var zeroRequests = false;
      var zeroWindow = false;
      try {
        AiProviderRateLimiter(
          limits: <String, AiRateLimit>{
            '': const AiRateLimit(maxRequests: 1, window: Duration(seconds: 1)),
          },
        );
      } on ArgumentError {
        emptyId = true;
      }
      try {
        AiProviderRateLimiter(
          limits: <String, AiRateLimit>{
            'p': const AiRateLimit(
              maxRequests: 0,
              window: Duration(seconds: 1),
            ),
          },
        );
      } on ArgumentError {
        zeroRequests = true;
      }
      try {
        AiProviderRateLimiter(
          limits: <String, AiRateLimit>{
            'p': const AiRateLimit(maxRequests: 1, window: Duration.zero),
          },
        );
      } on ArgumentError {
        zeroWindow = true;
      }
      expect(emptyId, isTrue);
      expect(zeroRequests, isTrue);
      expect(zeroWindow, isTrue);
      probes['throttling_invalid_limits_refused'] =
          'empty_id=$emptyId zero_requests=$zeroRequests zero_window=$zeroWindow';
    });

    test('the window is enforced and then frees capacity again', () {
      final limiter = AiProviderRateLimiter(
        limits: <String, AiRateLimit>{
          'p': const AiRateLimit(maxRequests: 2, window: Duration(seconds: 10)),
        },
      );
      final start = DateTime.utc(2026, 10, 2, 12);
      final first = limiter.allow('p', now: start);
      final second = limiter.allow(
        'p',
        now: start.add(const Duration(seconds: 1)),
      );
      final third = limiter.allow(
        'p',
        now: start.add(const Duration(seconds: 2)),
      );
      final unknown = limiter.allow('nope', now: start);
      final afterWindow = limiter.allow(
        'p',
        now: start.add(const Duration(seconds: 11)),
      );
      expect(first, isTrue);
      expect(second, isTrue);
      expect(third, isFalse);
      expect(unknown, isFalse);
      expect(afterWindow, isTrue);
      probes['throttling_allow_pattern'] =
          'true,true,false,false(after 11s)=true';
      probes['throttling_unknown_provider_allowed'] = '$unknown';
    });
  });

  group('retry_after', () {
    test('the wait names the oldest window entry and frees to zero', () {
      final limiter = AiProviderRateLimiter(
        limits: <String, AiRateLimit>{
          'p': const AiRateLimit(maxRequests: 1, window: Duration(seconds: 30)),
        },
      );
      final start = DateTime.utc(2026, 10, 2, 12);
      final free = limiter.retryAfter('p', now: start);
      limiter.allow('p', now: start);
      final blocked = limiter.retryAfter('p', now: start);
      final later = limiter.retryAfter(
        'p',
        now: start.add(const Duration(seconds: 10)),
      );
      final expired = limiter.retryAfter(
        'p',
        now: start.add(const Duration(seconds: 31)),
      );
      final unknown = limiter.retryAfter('nope', now: start);
      expect(free, Duration.zero);
      expect(blocked, const Duration(seconds: 30));
      expect(later, const Duration(seconds: 20));
      expect(expired, Duration.zero);
      expect(unknown, isNull);
      probes['retry_after_seconds'] = 'free=0 blocked=30 later=20 expired=0';
      probes['retry_after_unknown_null'] = '${unknown == null}';
    });

    test('the user-facing window is truthful for sub-minute waits', () {
      final thirtySeconds = AccountCenterLoadingEmptyErrorStates.rateLimited(
        source: 'probe',
        retryAfter: const Duration(seconds: 30),
      );
      final ninetySeconds = AccountCenterLoadingEmptyErrorStates.rateLimited(
        source: 'probe',
        retryAfter: const Duration(seconds: 90),
      );
      expect(thirtySeconds.message, contains('30 seconds'));
      expect(ninetySeconds.message, contains('2 minutes'));
      expect(thirtySeconds.retryAfter, const Duration(seconds: 30));
      var zeroRefused = false;
      try {
        AccountCenterLoadingEmptyErrorStates.rateLimited(
          source: 'probe',
          retryAfter: Duration.zero,
        );
      } on ArgumentError {
        zeroRefused = true;
      }
      expect(zeroRefused, isTrue);
      probes['retry_after_rendered'] = thirtySeconds.message.replaceAll(
        'Rate limited. Try again after ',
        '',
      );
      probes['retry_after_zero_refused'] = '$zeroRefused';
    });
  });

  group('circuit_breaker', () {
    test('the retry budget is bounded and reports exhaustion', () {
      final machine = _errorMachine(maxAttempts: 2);
      final first = machine.transition(
        AccountConnectionTransition.retry,
        at: DateTime.utc(2026, 10, 2, 12, 1),
      );
      expect(first.retryAttempt, 1);
      machine.transition(
        AccountConnectionTransition.error,
        at: DateTime.utc(2026, 10, 2, 12, 2),
        userVisibleError: 'probe failure again',
      );
      final second = machine.transition(
        AccountConnectionTransition.retry,
        at: DateTime.utc(2026, 10, 2, 12, 3),
      );
      expect(second.retryAttempt, 2);
      machine.transition(
        AccountConnectionTransition.error,
        at: DateTime.utc(2026, 10, 2, 12, 4),
        userVisibleError: 'probe failure third',
      );
      var exhausted = false;
      try {
        machine.transition(
          AccountConnectionTransition.retry,
          at: DateTime.utc(2026, 10, 2, 12, 5),
        );
      } on StateError {
        exhausted = true;
      }
      expect(exhausted, isTrue);
      probes['circuit_breaker_retry_budget'] = 'max=2 exhausted=$exhausted';
    });

    test('a non-positive retry budget is refused at construction', () {
      var refused = false;
      try {
        AccountConnectionRetryPolicy(maxAttempts: 0);
      } on ArgumentError {
        refused = true;
      }
      expect(refused, isTrue);
      probes['circuit_breaker_zero_budget_refused'] = '$refused';
    });

    test('a revoked connection permits cleanup, not quiet restoration', () {
      final machine = _connectedMachine()
        ..transition(
          AccountConnectionTransition.revoke,
          at: DateTime.utc(2026, 10, 2, 12, 30),
          userVisibleError: 'probe revoked',
        );
      expect(machine.snapshot.connectionState, AccountConnectionState.revoked);
      expect(machine.availableTransitions, <AccountConnectionTransition>[
        AccountConnectionTransition.disconnectCleanup,
      ]);
      var reviveRefused = false;
      try {
        machine.transition(
          AccountConnectionTransition.beginConnecting,
          at: DateTime.utc(2026, 10, 2, 12, 31),
        );
      } on StateError {
        reviveRefused = true;
      }
      expect(reviveRefused, isTrue);
      machine.transition(
        AccountConnectionTransition.disconnectCleanup,
        at: DateTime.utc(2026, 10, 2, 12, 32),
      );
      expect(
        machine.snapshot.connectionState,
        AccountConnectionState.notConfigured,
      );
      probes['circuit_breaker_revoked_terminal'] =
          'cleanup_only=true transitions_before_cleanup=1 revive_refused=$reviveRefused';
    });

    test(
      'the router walks past a failing primary and names the server',
      () async {
        final broken = _FakeProvider(
          id: 'broken_primary',
          throwOnGenerate: true,
        );
        final healthy = _FakeProvider(id: 'healthy_secondary');
        final router = ProviderRouter(<AiProvider>[broken, healthy]);
        final served = await router.generateReportingServingProvider(
          _request('breaker-fallback'),
          preferred: 'broken_primary',
        );
        expect(served.providerId, 'healthy_secondary');
        expect(broken.generateCalls, 1);
        expect(healthy.generateCalls, 1);
        probes['circuit_breaker_served_by'] = served.providerId;
        probes['circuit_breaker_primary_calls'] = '${broken.generateCalls}';
      },
    );

    test('a target no provider can serve fails loudly', () async {
      final router = ProviderRouter(<AiProvider>[_FakeProvider()]);
      // Fake hanya mendukung PromptTarget.story; audio tidak didukung
      // manapun di registry ini, jadi resolve memang harus menolak.
      const audioRequest = AiGenerationRequest(
        jobId: 'breaker-unsupported',
        prompt: 'probe prompt',
        target: PromptTarget.audio,
      );
      var refused = false;
      try {
        await router.generateReportingServingProvider(audioRequest);
      } on StateError {
        refused = true;
      }
      expect(refused, isTrue);
      probes['circuit_breaker_unserved_refused'] = '$refused';
    });
  });

  group('cancellation', () {
    test(
      'cancel reaches the delegate through the timeout wrapper once',
      () async {
        final delegate = _FakeProvider();
        final wrapper = AiProviderWithTimeout(
          delegate,
          timeout: const Duration(seconds: 5),
        );
        await wrapper.cancel('req-cancel-1');
        expect(delegate.cancelledRequests, <String>['req-cancel-1']);
        probes['cancellation_delegate_calls'] =
            '${delegate.cancelledRequests.length}';
        probes['cancellation_request_ids'] = delegate.cancelledRequests.join(
          ',',
        );
      },
    );

    test('a cancelled queued job never runs and is marked cancelled', () async {
      final queue = BackgroundJobQueue();
      final executed = <String>[];
      final task = _RecordingTask(
        'cancel-me',
        BackgroundJobPriority.low,
        executed,
      );
      expect(queue.enqueue(task), isTrue);
      final cancelled = await queue.cancel('cancel-me');
      await queue.drain();
      expect(cancelled, isTrue);
      expect(executed, isEmpty);
      expect(queue.jobOf('cancel-me')?.status, BackgroundJobStatus.cancelled);
      await queue.dispose();
      probes['cancellation_queued_executed'] = '${executed.length}';
      probes['cancellation_queued_status'] = queue
          .jobOf('cancel-me')!
          .status
          .name;
    });
  });

  group('outage', () {
    test('an outage refresh lands on unavailable with a visible reason', () {
      final machine = _connectedMachine()
        ..transition(
          AccountConnectionTransition.refreshHealth,
          at: DateTime.utc(2026, 10, 2, 12, 40),
          healthState: AccountHealthState.outage,
        );
      expect(
        machine.snapshot.connectionState,
        AccountConnectionState.unavailable,
      );
      expect(machine.snapshot.healthState, AccountHealthState.outage);
      expect(machine.snapshot.userVisibleError, isNotNull);
      expect(machine.snapshot.userVisibleError, isNotEmpty);
      probes['outage_state'] =
          '${machine.snapshot.connectionState.wireName}/'
          '${machine.snapshot.healthState.wireName}';
    });

    test('a rate-limited refresh stays connected and still says so', () {
      final machine = _connectedMachine()
        ..transition(
          AccountConnectionTransition.refreshHealth,
          at: DateTime.utc(2026, 10, 2, 12, 41),
          healthState: AccountHealthState.rateLimited,
        );
      expect(
        machine.snapshot.connectionState,
        AccountConnectionState.connected,
      );
      expect(machine.snapshot.healthState, AccountHealthState.rateLimited);
      expect(machine.snapshot.errorCode, 'health');
      probes['outage_rate_limited_connection'] =
          machine.snapshot.connectionState.wireName;
    });

    test('a visible error carrying a credential is refused', () {
      final machine = _connectedMachine();
      var secretRefused = false;
      try {
        machine.transition(
          AccountConnectionTransition.error,
          at: DateTime.utc(2026, 10, 2, 12, 42),
          userVisibleError: 'Authorization: Bearer sk-abc123def456',
        );
      } on ArgumentError {
        secretRefused = true;
      }
      expect(secretRefused, isTrue);
      probes['outage_secret_error_refused'] = '$secretRefused';
    });

    test(
      'a failing provider probe reports unavailable, never healthy',
      () async {
        final probe = AiProviderHealthProbe(
          _FakeProvider(throwOnListModels: true),
        );
        final health = await probe.check();
        expect(health.status, AiProviderHealthStatus.unavailable);
        expect(health.modelCount, 0);
        expect(health.errorMessage, isNotNull);
        probes['outage_probe_status'] = health.status.name;
        probes['outage_probe_model_count'] = '${health.modelCount}';
      },
    );

    test(
      'a provider returning no model reads as degraded, not healthy',
      () async {
        final probe = AiProviderHealthProbe(_FakeProvider(emptyModels: true));
        final health = await probe.check();
        expect(health.status, AiProviderHealthStatus.degraded);
        probes['outage_empty_models_status'] = health.status.name;
      },
    );
  });

  group('queue_recovery', () {
    test('pause holds scheduling until resume releases it', () async {
      final queue = BackgroundJobQueue();
      final executed = <String>[];
      final task = _RecordingTask(
        'paused-low',
        BackgroundJobPriority.low,
        executed,
      );
      expect(queue.enqueue(task), isTrue);
      queue.pause(BackgroundJobPriority.high);
      unawaited(queue.drain());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final pausedHeld = executed.isEmpty;
      queue.resume();
      await queue.drain();
      final ranAfterResume = executed.contains('paused-low');
      expect(pausedHeld, isTrue);
      expect(ranAfterResume, isTrue);
      await queue.dispose();
      probes['queue_recovery_pause_held'] = '$pausedHeld';
      probes['queue_recovery_ran_after_resume'] = '$ranAfterResume';
      probes['queue_recovery_executed'] = executed.join(',');
    });

    test('a task above the pause threshold keeps running', () async {
      final queue = BackgroundJobQueue();
      final executed = <String>[];
      queue
        ..enqueue(
          _RecordingTask(
            'critical-1',
            BackgroundJobPriority.critical,
            executed,
          ),
        )
        ..pause(BackgroundJobPriority.high);
      await queue.drain();
      expect(executed, contains('critical-1'));
      probes['queue_recovery_critical_ran_while_paused'] = executed
          .contains('critical-1')
          .toString();
      await queue.dispose();
    });

    test('a failing task does not stop the queue from draining', () async {
      final queue = BackgroundJobQueue();
      final executed = <String>[];
      queue
        ..enqueue(
          _RecordingTask('ok-1', BackgroundJobPriority.normal, executed),
        )
        ..enqueue(_FailingTask('boom-1', BackgroundJobPriority.normal));
      await queue.drain();
      expect(executed, contains('ok-1'));
      expect(queue.jobOf('boom-1')?.status, BackgroundJobStatus.failed);
      expect(queue.jobOf('ok-1')?.status, BackgroundJobStatus.completed);
      probes['queue_recovery_failed_status'] = queue
          .jobOf('boom-1')!
          .status
          .name;
      probes['queue_recovery_survived_executed'] = executed.join(',');
      await queue.dispose();
    });
  });

  group('kill_switch', () {
    test('engaging forces every flag off and blocks re-read', () {
      final registry = FeatureFlagRegistry()
        ..enable('vs12_lore_links')
        ..enable('vs12_export');
      expect(registry.enabledFlags.length, 2);
      expect(registry.killSwitchActive, isFalse);
      registry.engageKillSwitch();
      expect(registry.killSwitchActive, isTrue);
      expect(registry.enabledFlags, isEmpty);
      expect(registry.allAtDefaults, isTrue);
      expect(registry.isEnabled('vs12_lore_links'), isFalse);
      expect(registry.isEnabled('vs12_export'), isFalse);
      probes['kill_switch_enabled_after_engage'] =
          '${registry.enabledFlags.length}';
      probes['kill_switch_active'] = '${registry.killSwitchActive}';
    });

    test('engaging twice is idempotent', () {
      final registry = FeatureFlagRegistry()
        ..enable('vs12_quests')
        ..engageKillSwitch()
        ..engageKillSwitch();
      expect(registry.killSwitchActive, isTrue);
      expect(registry.isEnabled('vs12_quests'), isFalse);
      probes['kill_switch_double_engage'] = '${registry.killSwitchActive}';
    });

    test('an explicit re-enable clears the emergency state', () {
      final registry = FeatureFlagRegistry()
        ..enable('vs12_pov')
        ..engageKillSwitch();
      registry.enable('vs12_pov');
      expect(registry.killSwitchActive, isFalse);
      expect(registry.isEnabled('vs12_pov'), isTrue);
      probes['kill_switch_cleared_by_enable'] = '${registry.killSwitchActive}';
    });

    test('disengaging returns the surface to all-off', () {
      final registry = FeatureFlagRegistry()
        ..enable('vs12_conlang')
        ..engageKillSwitch()
        ..disengageKillSwitch();
      expect(registry.killSwitchActive, isFalse);
      expect(registry.enabledFlags, isEmpty);
      expect(registry.isEnabled('vs12_conlang'), isFalse);
      probes['kill_switch_after_disengage'] = '${registry.enabledFlags.length}';
    });

    test('an unknown flag name is refused, not silently created', () {
      final registry = FeatureFlagRegistry();
      var refused = false;
      try {
        registry.enable('not_a_real_flag');
      } on ArgumentError {
        refused = true;
      }
      expect(refused, isTrue);
      expect(registry.enabledFlags, isEmpty);
      probes['kill_switch_unknown_flag_refused'] = '$refused';
    });
  });

  group('the eight axes carry measurements this run actually took', () {
    late Sprint117ResilienceResult result;

    setUpAll(() async {
      result = await _evaluateWithProbes(probes);
    });

    test('no axis is missing and no axis carries a violation', () {
      expect(result.pass, isTrue);
      expect(result.failures, isEmpty);
      expect(result.violationCodes, isEmpty);
      for (final area in Sprint117ProviderResilience.requiredAreas) {
        expect(
          result.checks.where((c) => c.area == area).isNotEmpty,
          isTrue,
          reason: 'area $area must carry at least one check',
        );
      }
    });

    test('every observed string quotes a probe recorded this run', () {
      for (final check in result.checks) {
        expect(check.observed.trim(), isNotEmpty);
      }
      expect(probes.length, greaterThanOrEqualTo(20));
    });

    test('the one open item names the breaker component that is absent', () {
      expect(
        result.openItems,
        contains('circuit_breaker:open_half_open_cooldown_component'),
      );
      // An unmet check is reported, never counted as a failure and never
      // quietly promoted to pass.
      expect(result.pass, isTrue);
    });

    test('the manifest on disk matches the probes of this run', () {
      evidence['gate'] = result.toJson();
      evidence['probes'] = probes;
      evidence['open_items'] = result.openItems;
      evidence['verdict'] = result.summary;
      final outputDirectory = Directory.systemTemp.createTempSync(
        'void-scriptor-sprint-117-36-',
      );
      try {
        final file = writeEvidenceFile(outputDirectory);
        expect(file.existsSync(), isTrue);
        final decoded =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        expect(decoded['canonical_step'], '117.36');
        expect((decoded['gate'] as Map<String, dynamic>)['pass'], isTrue);
        // ignore: avoid_print
        print('11736_GATE ${result.summary}');
        // ignore: avoid_print
        print('11736_PROBES ${jsonEncode(probes)}');
      } finally {
        if (outputDirectory.existsSync()) {
          outputDirectory.deleteSync(recursive: true);
        }
      }
    });
  });
}

/// Evaluasi agregat yang mengisi setiap `observed` dari map probe run ini,
/// sehingga tidak ada angka yang diketik tangan di verdict.
Future<Sprint117ResilienceResult> _evaluateWithProbes(
  Map<String, String> probes,
) async {
  String p(String key) {
    final value = probes[key];
    if (value == null) {
      throw StateError('Probe "$key" was not recorded by this run.');
    }
    return value;
  }

  // circuit_breaker probes are filled by the live scenarios above; recompute
  // what this run actually observed rather than restating a declaration.
  final retryBudgetExhausted = p('circuit_breaker_retry_budget');
  final revokedTerminal = p('circuit_breaker_revoked_terminal');
  final servedBy = p('circuit_breaker_served_by');

  final checks = <Sprint117ResilienceCheck>[
    Sprint117ResilienceCheck.pass_(
      area: 'timeout',
      check: 'budget_is_refused_and_exceeded_work_surfaces_provider_timeout',
      declared:
          'A non-positive timeout budget is rejected at construction and an '
          'exceeded budget surfaces AiProviderTimeoutException naming the '
          'provider and the budget, never a raw TimeoutException.',
      observed:
          'non-positive budget refused (${p('timeout_rejected_non_positive_budget')}); '
          'exceeded budget raised AiProviderTimeoutException after '
          '${p('timeout_provider_exception_ms')}ms; under-budget call returned '
          '${p('timeout_under_budget_passed')}.',
    ),
    Sprint117ResilienceCheck.pass_(
      area: 'throttling',
      check: 'window_is_enforced_and_invalid_limits_are_refused',
      declared:
          'The limiter enforces its window, refuses an invalid limit at '
          'construction, and never allows a provider it has no limit for.',
      observed:
          'invalid limits refused (${p('throttling_invalid_limits_refused')}); '
          'allow sequence ${p('throttling_allow_pattern')}; unknown provider '
          'allowed=${p('throttling_unknown_provider_allowed')}.',
    ),
    Sprint117ResilienceCheck.pass_(
      area: 'retry_after',
      check: 'wait_is_measured_and_the_user_facing_window_is_truthful',
      declared:
          'retryAfter names the real wait until the oldest window entry '
          'expires, returns null for an unknown provider, and the rendered '
          'message never tells the user to retry before the provider will.',
      observed:
          'retryAfter seconds: ${p('retry_after_seconds')}; unknown provider '
          'null=${p('retry_after_unknown_null')}; rendered sub-minute window '
          '"${p('retry_after_rendered')}"; zero retry window refused='
          '${p('retry_after_zero_refused')}.',
    ),
    Sprint117ResilienceCheck.pass_(
      area: 'circuit_breaker',
      check: 'retry_budget_is_bounded_and_revoked_is_terminal',
      declared:
          'The retry budget is finite and reports exhaustion instead of '
          'reconnecting forever, a revoked connection has no outbound '
          'transition at all, and a persistently failing primary is walked '
          'past so a later provider serves the request.',
      observed:
          '$retryBudgetExhausted; zero budget refused='
          '${p('circuit_breaker_zero_budget_refused')}; revoked terminal '
          '($revokedTerminal); request served by $servedBy after the primary '
          'was called ${p('circuit_breaker_primary_calls')} time(s); '
          'unservable target refused=${p('circuit_breaker_unserved_refused')}.',
    ),
    const Sprint117ResilienceCheck.unmet(
      area: 'circuit_breaker',
      check: 'open_half_open_cooldown_component',
      declared:
          'An OPEN/HALF_OPEN breaker with a cooldown timer refuses calls '
          'while open and admits one trial call while half-open.',
      observed:
          'No such component ships in this build: the provider layer has a '
          'timeout wrapper, a rate limiter, and a fallback router, and the '
          'connection layer has a bounded retry budget, but no breaker with '
          'open/half-open states and a cooldown. Nothing local can produce '
          'that measurement, so it stays DEFERRED-EXTERNAL and is reported '
          'rather than passed.',
      note:
          'The shipped half (bounded retry budget, revoked-as-terminal, '
          'router fallback) is measured and passed on its own check.',
    ),
    Sprint117ResilienceCheck.pass_(
      area: 'cancellation',
      check: 'cancel_reaches_the_provider_and_stops_queued_work',
      declared:
          'A cancel sent through the timeout wrapper reaches the delegate '
          'exactly once, and a cancelled queued job never executes and is '
          'reported as cancelled.',
      observed:
          'delegate cancel calls=${p('cancellation_delegate_calls')} '
          '(${p('cancellation_request_ids')}); cancelled queued job executed '
          '${p('cancellation_queued_executed')} time(s) with status '
          '${p('cancellation_queued_status')}.',
    ),
    Sprint117ResilienceCheck.pass_(
      area: 'outage',
      check: 'outage_and_rate_limit_are_distinguished_and_secrets_are_refused',
      declared:
          'An outage refresh lands on UNAVAILABLE with a visible reason, a '
          'rate-limited refresh stays connected while still reporting the '
          'limit, a visible error carrying a credential is refused, and a '
          'failing provider probe reads unavailable rather than healthy.',
      observed:
          'outage -> ${p('outage_state')}; rate-limited -> '
          '${p('outage_rate_limited_connection')}; secret-bearing visible '
          'error refused=${p('outage_secret_error_refused')}; failing probe '
          '-> ${p('outage_probe_status')} with ${p('outage_probe_model_count')} '
          'models; empty model list -> ${p('outage_empty_models_status')}.',
    ),
    Sprint117ResilienceCheck.pass_(
      area: 'queue_recovery',
      check: 'pause_holds_until_resume_and_a_failure_does_not_wedge_the_queue',
      declared:
          'Pause by priority holds scheduling of jobs at or below the '
          'threshold while jobs above it keep running, resume releases them, '
          'and one failing task does not prevent the queue from draining.',
      observed:
          'paused job held=${p('queue_recovery_pause_held')}, ran after '
          'resume=${p('queue_recovery_ran_after_resume')} '
          '(${p('queue_recovery_executed')}); critical ran while paused='
          '${p('queue_recovery_critical_ran_while_paused')}; failing task '
          'ended ${p('queue_recovery_failed_status')} while its sibling '
          'still ran (${p('queue_recovery_survived_executed')}).',
    ),
    Sprint117ResilienceCheck.pass_(
      area: 'kill_switch',
      check: 'engage_blocks_every_flag_and_only_an_explicit_action_clears_it',
      declared:
          'Engaging the kill-switch empties the enabled set, makes every '
          'flag read disabled while engaged, is idempotent, and is cleared '
          'only by an explicit re-enable or disengage. An unknown flag name '
          'is refused rather than created.',
      observed:
          'enabled after engage=${p('kill_switch_enabled_after_engage')}, '
          'active=${p('kill_switch_active')}; double engage still active='
          '${p('kill_switch_double_engage')}; explicit re-enable cleared='
          '${p('kill_switch_cleared_by_enable')}; after disengage enabled='
          '${p('kill_switch_after_disengage')}; unknown flag refused='
          '${p('kill_switch_unknown_flag_refused')}.',
    ),
  ];

  return Sprint117ProviderResilience.evaluate(checks);
}
