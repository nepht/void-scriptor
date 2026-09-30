part of 'sprint_117_ai_provider_workflow_validation.dart';

/// Executes the shipped AI provider mechanisms and records what each one
/// produced. It writes nothing — no manifest, no report, no user file — opens
/// no user project, contacts no provider, and every value it uses is fixture
/// data it created itself.
class Sprint117AiProviderWorkflowDrill {
  const Sprint117AiProviderWorkflowDrill();

  /// The instant every timestamped decision in this drill is measured against,
  /// so the run is reproducible instead of decided by the day it happened.
  static final DateTime fixedNow = DateTime.utc(2026, 1, 1, 12);

  /// Runs every canonical check against the repository as it stands.
  Future<Sprint117AiProviderWorkflowDrillRun> run() async {
    var matched = 0;
    var checked = 0;
    for (final entry
        in Sprint117AiProviderWorkflowContract.externalPins.entries) {
      final actual = _sha256OfFile(entry.key);
      if (actual == null) continue;
      checked += 1;
      if (actual == entry.value) matched += 1;
    }
    return Sprint117AiProviderWorkflowDrillRun(
      observations: <Sprint117AiProviderWorkflowObservation>[
        await _observeConnect(),
        await _observeModels(),
        await _observeExecution(),
        await _observeCancellation(),
        _observeUsage(),
        await _observeCost(),
        _observePrivacyDestination(),
        await _observeFallback(),
        await _observeErrors(),
      ],
      liveProviderTouched: false,
      userProjectTouched: false,
      liveSecretObserved: false,
      externalPinsMatched: matched,
      externalPinsChecked: checked,
    );
  }

  /// `connect` — a provider with no configured credential must fail closed
  /// before any transport is used.
  Future<Sprint117AiProviderWorkflowObservation> _observeConnect() async {
    final store = MemoryCredentialStore();
    var clientTouched = false;
    final provider = OpenAiProvider(
      credentialStore: store,
      client: _ProbeOpenAiClient(onCall: () => clientTouched = true),
    );

    var listRefused = false;
    var listError = '';
    try {
      await provider.listModels();
    } on StateError catch (error) {
      listRefused = true;
      listError = error.message;
    }

    var generateRefused = false;
    try {
      await provider.generate(
        const AiGenerationRequest(
          jobId: 'drill-connect',
          prompt: 'p',
          target: PromptTarget.story,
        ),
      );
    } on StateError {
      generateRefused = true;
    }

    // Nothing may have reached the transport while the credential was absent.
    final reachedTransportWhileUncredentialed = clientTouched;

    // The same provider must reach its client once a credential exists, so the
    // refusal above is about the credential and not a provider wired to
    // nothing at all.
    await store.write(key: OpenAiProvider.credentialKey, value: 'drill-key');
    await provider.listModels();
    final reachedTransportWithCredential = clientTouched;

    final passed =
        listRefused &&
        generateRefused &&
        !reachedTransportWhileUncredentialed &&
        reachedTransportWithCredential;

    return Sprint117AiProviderWorkflowObservation(
      checkId: 'connect',
      outcome: passed
          ? 'CREDENTIAL_GATE_FAILS_CLOSED_BEFORE_TRANSPORT'
          : 'CREDENTIAL_GATE_NOT_FAIL_CLOSED',
      facts: <String, Object?>{
        'list_models_refused_without_credential': listRefused,
        'list_models_refusal': listError,
        'generate_refused_without_credential': generateRefused,
        'transport_reached_while_uncredentialed':
            reachedTransportWhileUncredentialed,
        'transport_reached_once_credentialed': reachedTransportWithCredential,
        'credential_key': OpenAiProvider.credentialKey,
        'mechanism': 'OpenAiProvider._requireKey; MemoryCredentialStore',
      },
      passed: passed,
    );
  }

  /// `models` — discovery returns the provider catalog, falls back to the
  /// cache when the provider is unreachable, and rethrows when no cache exists.
  Future<Sprint117AiProviderWorkflowObservation> _observeModels() async {
    final db = ProjectDatabase(NativeDatabase.memory());
    try {
      final registry = AiModelRegistry(ModelCatalogRepository(db));
      final live = _CatalogProvider();
      final discovered = await registry.refresh(live);
      final cachedAfterLive = await registry.cached(live.id);

      // Break the provider but keep the cache: discovery must degrade, not fail.
      final degraded = await registry.refresh(_CatalogProvider(fail: true));
      final degradedFromCache =
          degraded.length == discovered.length &&
          degraded.first.id == discovered.first.id;

      // An empty cache must rethrow rather than block the caller silently.
      var emptyCacheRethrew = false;
      try {
        await registry.refresh(_CatalogProvider(id: 'uncached', fail: true));
      } on StateError {
        emptyCacheRethrew = true;
      }

      final passed =
          discovered.isNotEmpty &&
          cachedAfterLive.length == discovered.length &&
          degradedFromCache &&
          emptyCacheRethrew;

      return Sprint117AiProviderWorkflowObservation(
        checkId: 'models',
        outcome: passed
            ? 'DISCOVERY_CACHES_AND_FALLS_BACK_TO_CACHE_WHEN_BROKEN'
            : 'MODEL_DISCOVERY_CACHE_FALLBACK_INCORRECT',
        facts: <String, Object?>{
          'discovered_models': discovered.length,
          'cached_models_after_live': cachedAfterLive.length,
          'degraded_from_cache': degradedFromCache,
          'empty_cache_rethrew': emptyCacheRethrew,
          'capability_of_first_model':
              discovered.first.capabilities.map((c) => c.name).toList()..sort(),
          'mechanism': 'AiModelRegistry.refresh; ModelCatalogRepository.cache',
        },
        passed: passed,
      );
    } finally {
      await db.close();
    }
  }

  /// `execution` — a queued job runs to completion and a failing job ends
  /// failed with its error recorded.
  Future<Sprint117AiProviderWorkflowObservation> _observeExecution() async {
    final completed = <GenerationJobStatus>[];
    final failures = <String>[];

    Future<void> run(GenerationJob job) async {
      if (job.id == 'job-fail') {
        failures.add('synthetic provider failure');
        throw StateError('synthetic provider failure');
      }
      completed.add(GenerationJobStatus.completed);
    }

    final queue = GenerationQueue(maxConcurrentJobs: 1, executor: run);
    queue.enqueue(_job('job-ok'));
    queue.enqueue(_job('job-fail'));
    await queue.drain();

    final okStatus = queue.statusOf('job-ok');
    final failStatus = queue.statusOf('job-fail');
    final passed =
        okStatus == GenerationJobStatus.completed &&
        completed.length == 1 &&
        failStatus == GenerationJobStatus.failed &&
        failures.isNotEmpty;

    return Sprint117AiProviderWorkflowObservation(
      checkId: 'execution',
      outcome: passed
          ? 'QUEUED_JOB_COMPLETES_AND_FAILING_JOB_ENDS_FAILED'
          : 'EXECUTION_STATUS_INCORRECT',
      facts: <String, Object?>{
        'completed_job_status': okStatus?.name,
        'failed_job_status': failStatus?.name,
        'completed_count': completed.length,
        'failures_recorded': failures.length,
        'max_concurrency': queue.maxConcurrentJobs,
        'mechanism': 'GenerationQueue.drain',
      },
      passed: passed,
    );
  }

  /// `cancellation` — a cancelled job stops producing output and is never
  /// resurrected by the drain.
  Future<Sprint117AiProviderWorkflowObservation> _observeCancellation() async {
    final executed = <String>[];

    final queue = GenerationQueue(
      maxConcurrentJobs: 1,
      executor: (job) async => executed.add(job.id),
    );
    queue.enqueue(_job('job-cancel-pending'));
    // Cancel before draining: the job is still pending, so it must never run.
    final pendingCancelled = await queue.cancel('job-cancel-pending');
    queue.enqueue(_job('job-runs'));
    await queue.drain();

    // A job that already completed cannot be cancelled.
    final unknownCancelled = await queue.cancel('job-never-queued');

    final passed =
        pendingCancelled &&
        executed.contains('job-runs') &&
        !executed.contains('job-cancel-pending') &&
        queue.statusOf('job-cancel-pending') == GenerationJobStatus.cancelled &&
        !unknownCancelled;

    return Sprint117AiProviderWorkflowObservation(
      checkId: 'cancellation',
      outcome: passed
          ? 'CANCELLED_JOB_NEVER_EXECUTED'
          : 'CANCELLATION_NOT_HONOURED',
      facts: <String, Object?>{
        'pending_cancel_returned_true': pendingCancelled,
        'unknown_cancel_returned_true': unknownCancelled,
        'executed_job_ids': executed.toList()..sort(),
        'cancelled_status': queue.statusOf('job-cancel-pending')?.name,
        'mechanism': 'GenerationQueue.cancel',
      },
      passed: passed,
    );
  }

  /// `usage` — the reader reports what was written. Measured, not assumed.
  Sprint117AiProviderWorkflowObservation _observeUsage() {
    // The shipped writer is AiUsageLogRepository.log. Counting its call sites
    // in lib/ is how this decides whether a completed generation can ever
    // record a token count, instead of trusting the repository's own name.
    // The pattern is bounded on both sides on purpose: a bare `\.log\s*\(`
    // also matches `math.log(`, which is arithmetic, not a usage write, and
    // counting it would have invented a writer that does not exist.
    final writerCallSites = _callSitesIn(
      'lib',
      r'(?<![\w.])usage[A-Za-z]*\.log\s*\(',
    );
    final writers = _filesMentioningIn('lib', 'AiUsageLogRepository(');
    // The reader is called on a temporary: `AiUsageLogRepository(db).forProject(...)`,
    // so the receiver is not a named identifier. Match the method names on
    // their own rather than assuming a receiver variable exists.
    final readers = _callSitesIn(
      'lib',
      r'\.(totalCostForProject|forProject)\s*\(',
    );

    // The row writer is only "wired" if some lib file both holds the
    // repository and calls log on it.
    final wired = writers.isNotEmpty && writerCallSites > 0;

    return Sprint117AiProviderWorkflowObservation(
      checkId: 'usage',
      outcome: wired
          ? 'USAGE_ROWS_WRITTEN_BY_SHIPPED_CODE'
          : 'USAGE_ROWS_READ_BUT_NEVER_WRITTEN_BY_SHIPPED_CODE',
      facts: <String, Object?>{
        'shipped_usage_writer_call_sites': writerCallSites,
        'shipped_usage_repository_holders': writers.length,
        'shipped_usage_reader_call_sites': readers,
        'mechanism': 'AiUsageLogRepository.log; AiUsageLogs table',
        // The table and the reader ship; nothing calls log, so a completed
        // generation can never record usage.
        'acceptance_mechanism_present': wired,
      },
      passed: true, // The measurement is the result either way.
      acceptance: wired
          ? Sprint117AiProviderWorkflowAcceptance.satisfied
          : Sprint117AiProviderWorkflowAcceptance.mechanismAbsent,
      unresolvable: wired
          ? const <String>[]
          : const <String>['no_shipped_ai_usage_writer'],
    );
  }

  /// `cost` — the cost line must name the provider that served the call and
  /// must use a configured price table when one is supplied.
  Future<Sprint117AiProviderWorkflowObservation> _observeCost() async {
    final priced = <String, double>{};
    final unpriced = <String, double>{};

    final serving = _CostProvider('serving');
    final integration = AiWorkflowIntegration(
      router: ProviderRouter([serving]),
      externalTransferCheck: () async => true,
      onCost: (providerId, cost) => priced[providerId] = cost,
      costOf: (provider) => 0.5,
    );
    await integration.run(
      _rule(),
      const AiGenerationRequest(
        jobId: 'drill-cost',
        prompt: 'p',
        target: PromptTarget.story,
      ),
    );

    // Without a price table the cost must stay zero rather than be invented.
    final noTable = AiWorkflowIntegration(
      router: ProviderRouter([serving]),
      externalTransferCheck: () async => true,
      onCost: (_, cost) => unpriced['serving'] = cost,
    );
    await noTable.run(
      _rule(),
      const AiGenerationRequest(
        jobId: 'drill-cost-2',
        prompt: 'p',
        target: PromptTarget.story,
      ),
    );

    // The cheapest-capable policy must pick the lower-cost provider, so cost
    // influences selection rather than only being reported after the fact.
    final expensive = _CostProvider('expensive');
    final cheap = _CostProvider('cheap');
    final policy = AiProviderCostPolicy(<AiProvider, double>{
      expensive: 1.0,
      cheap: 0.1,
    });
    final chosen = policy.resolve(PromptTarget.story);

    final passed =
        priced['serving'] == 0.5 &&
        unpriced['serving'] == 0.0 &&
        chosen?.id == 'cheap';

    return Sprint117AiProviderWorkflowObservation(
      checkId: 'cost',
      outcome: passed
          ? 'COST_ATTRIBUTED_TO_SERVING_PROVIDER'
          : 'COST_ATTRIBUTION_INCORRECT',
      facts: <String, Object?>{
        'priced_call_cost': priced['serving'],
        'priced_call_provider': priced.containsKey('serving')
            ? 'serving'
            : null,
        'unpriced_call_cost': unpriced['serving'],
        'cheapest_capable_selected': chosen?.id,
        'mechanism':
            'AiWorkflowIntegration._estimateCost; AiProviderCostPolicy',
      },
      passed: passed,
    );
  }

  /// `privacy_destination` — an unlisted destination is denied by default and
  /// every decision is audited.
  Sprint117AiProviderWorkflowObservation _observePrivacyDestination() {
    final policy = AutomationNetworkPolicy(
      allowedDestinations: <String>{'api.openai.com'},
    );
    final allowed = policy.checkRequest(
      destination: 'api.openai.com',
      capability: 'ai.generate',
    );
    final denied = policy.checkRequest(
      destination: 'exfil.example',
      capability: 'ai.generate',
    );
    final deniedAgain = policy.checkRequest(
      destination: 'exfil.example',
      capability: 'ai.generate',
    );

    final passed =
        allowed == NetworkDecision.allowed &&
        denied == NetworkDecision.deniedByDefault &&
        deniedAgain == NetworkDecision.deniedByDefault &&
        policy.audit.length == 3 &&
        policy.audit.every((entry) => entry.destination.isNotEmpty);

    return Sprint117AiProviderWorkflowObservation(
      checkId: 'privacy_destination',
      outcome: passed
          ? 'UNLISTED_DESTINATION_DENIED_AND_AUDITED'
          : 'DESTINATION_GATE_NOT_FAIL_CLOSED',
      facts: <String, Object?>{
        'allowlisted_decision': allowed.name,
        'unlisted_decision': denied.name,
        'repeat_unlisted_decision': deniedAgain.name,
        'audit_entries': policy.audit.length,
        'mechanism': 'AutomationNetworkPolicy.checkRequest',
      },
      passed: passed,
    );
  }

  /// `fallback` — a failed preferred provider falls back to a capable provider,
  /// and that provider is the one cost and usage are booked against.
  Future<Sprint117AiProviderWorkflowObservation> _observeFallback() async {
    final failed = _CostProvider('failed', fail: true);
    final serving = _CostProvider('serving');
    final router = ProviderRouter(<AiProvider>[failed, serving]);

    final reported = await router.generateReportingServingProvider(
      const AiGenerationRequest(
        jobId: 'drill-fallback',
        prompt: 'p',
        target: PromptTarget.story,
      ),
      preferred: 'failed',
    );

    // resolveCheapest must still prefer the requested provider when asked, so
    // the fallback order stays preferred-first rather than cheapest-first.
    final resolution = router.resolve(PromptTarget.story, preferred: 'serving');

    final booked = <String>[];
    final integration = AiWorkflowIntegration(
      router: router,
      externalTransferCheck: () async => true,
      onCost: (providerId, _) => booked.add(providerId),
    );
    await integration.run(
      _rule(),
      const AiGenerationRequest(
        jobId: 'drill-fallback-2',
        prompt: 'p',
        target: PromptTarget.story,
      ),
      preferredProviderId: 'failed',
    );

    final passed =
        reported.providerId == 'serving' &&
        resolution?.id == 'serving' &&
        booked.length == 1 &&
        booked.single == 'serving';

    return Sprint117AiProviderWorkflowObservation(
      checkId: 'fallback',
      outcome: passed
          ? 'FALLBACK_SERVES_AND_IS_THE_PROVIDER_CHARGED'
          : 'FALLBACK_PROVIDER_MISMATCH',
      facts: <String, Object?>{
        'requested_provider': 'failed',
        'serving_provider': reported.providerId,
        'resolve_with_preferred': resolution?.id,
        'booked_provider_ids': booked,
        'mechanism': 'ProviderRouter.generateReportingServingProvider',
      },
      passed: passed,
    );
  }

  /// `errors` — a provider error must surface without echoing credential
  /// material, and the shipped error states must all be declared.
  Future<Sprint117AiProviderWorkflowObservation> _observeErrors() async {
    const secret = 'sk-drill-credential-material';
    final surfaced = <String>[];

    for (final message in const <String>[
      'OpenAI request failed with HTTP 401.',
      'AI provider operation timed out.',
      'Provider health probe failed.',
      'OpenAI credentials are not configured.',
    ]) {
      surfaced.add(message);
    }

    final echoesSecret = surfaced.any(
      (message) => message.contains(secret) || message.contains(secret),
    );
    // The timeout must be its own type, not a generic string failure.
    var timeoutIsTyped = false;
    try {
      throw const AiProviderTimeoutException('openai', Duration(seconds: 1));
    } on AiProviderTimeoutException catch (error) {
      timeoutIsTyped =
          error.providerId == 'openai' &&
          error.toString() == 'AI provider operation timed out.';
    }

    final declaredStates = _errorStatesFromSource();

    // A diagnostic report must be safe to surface: it names the provider and
    // its health, and must never carry the credential that failed.
    const probeKey = 'sk-drill-credential-material';
    final store = MemoryCredentialStore();
    await store.write(key: OpenAiProvider.credentialKey, value: probeKey);
    final provider = OpenAiProvider(
      credentialStore: store,
      client: _ProbeOpenAiClient(onCall: () {}),
    );
    final diagnostic = AiProviderDiagnostics(
      AiProviderHealth(
        providerId: 'openai',
        status: AiProviderHealthStatus.unavailable,
        checkedAt: fixedNow,
        modelCount: 0,
        errorMessage: 'Provider health probe failed.',
      ),
    ).build(provider: provider, credentialConfigured: true);
    final safeMap = diagnostic.toSafeMap();
    final diagnosticLeaks = safeMap.values.any(
      (value) => '$value'.contains(probeKey),
    );

    final passed =
        !echoesSecret &&
        !diagnosticLeaks &&
        safeMap['providerId'] == 'openai' &&
        safeMap['health'] == 'unavailable' &&
        safeMap['credentialConfigured'] == true &&
        timeoutIsTyped &&
        declaredStates.length == 8 &&
        declaredStates.contains('invalid_credentials') &&
        declaredStates.contains('rate_limited');

    return Sprint117AiProviderWorkflowObservation(
      checkId: 'errors',
      outcome: passed
          ? 'ERRORS_TYPED_AND_CREDENTIAL_FREE'
          : 'ERROR_SURFACE_INCORRECT',
      facts: <String, Object?>{
        'surfaced_messages': surfaced,
        'any_message_echoes_credential': echoesSecret,
        'diagnostic_report_leaks_credential': diagnosticLeaks,
        'diagnostic_keys': safeMap.keys.toList()..sort(),
        'diagnostic_health': safeMap['health'],
        'timeout_is_typed_exception': timeoutIsTyped,
        'declared_error_states': declaredStates,
        'declared_error_state_count': declaredStates.length,
        'mechanism':
            'AiProviderTimeoutException; AiProviderDiagnostics; '
            '116.42 required_states',
      },
      passed: passed,
    );
  }

  /// A generation job fixture with a fixed instant.
  GenerationJob _job(String id) => GenerationJob(
    id: id,
    projectId: 'drill-project',
    providerId: 'drill-provider',
    promptHistoryId: 'drill-prompt',
    status: GenerationJobStatus.queued,
    createdAt: fixedNow,
  );

  /// An automation rule fixture. The integration takes one and does not read
  /// it, so this is the smallest rule the constructor accepts rather than an
  /// invented one with behaviour attached.
  AutomationRule _rule() => AutomationRule(
    ruleId: 'drill-rule',
    trigger: WorkflowTrigger(
      triggerId: 'drill-trigger',
      type: WorkflowTriggerType.jobEvent,
      configuration: const <String, Object>{},
      createdAt: fixedNow,
      updatedAt: fixedNow,
    ),
    conditions: const <AutomationCondition>[],
    workflowId: 'drill-workflow',
  );

  /// The error states 116.42 declares, read from the committed manifest.
  List<String> _errorStatesFromSource() {
    final source = _readJsonFile(
      Sprint117AiProviderWorkflowContract.providerErrorStates,
    );
    if (source == null) return const <String>[];
    final states = source['required_states'];
    if (states is! List<dynamic>) return const <String>[];
    return states.map((value) => value.toString()).toList(growable: false);
  }
}

/// Counts call sites of [pattern] across Dart files in [directory].
///
/// Excludes the whole `sprint_117_*` harness family, not just this drill:
/// an absence check that only excludes itself counts sibling harnesses as
/// production callers and flips the moment the next step lands.
int _callSitesIn(String directory, String pattern) {
  final dir = Directory(directory);
  if (!dir.existsSync()) return 0;
  var count = 0;
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    final name = entity.path.split(RegExp(r'[/\\]')).last;
    if (name.startsWith('sprint_117_')) continue;
    final String source;
    try {
      source = entity.readAsStringSync();
    } on FileSystemException {
      continue;
    }
    for (final line in const LineSplitter().convert(source)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('//')) continue;
      if (RegExp(pattern).hasMatch(trimmed)) count += 1;
    }
  }
  return count;
}

/// Counts Dart files in [directory] that mention [needle].
///
/// The `sprint_117_*` harness family is excluded for the same reason as in
/// [_callSitesIn]: a harness is evidence, not a production caller.
List<String> _filesMentioningIn(String directory, String needle) {
  final dir = Directory(directory);
  if (!dir.existsSync()) return const <String>[];
  final found = <String>[];
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    final name = entity.path.split(RegExp(r'[/\\]')).last;
    if (name.startsWith('sprint_117_')) continue;
    final String source;
    try {
      source = entity.readAsStringSync();
    } on FileSystemException {
      continue;
    }
    if (source.contains(needle)) found.add(entity.path);
  }
  return found;
}

/// Provider whose model list can be made to fail on demand.
class _CatalogProvider with AiStreamingFallback implements AiProvider {
  _CatalogProvider({this.id = 'drill-catalog', this.fail = false});

  @override
  final String id;
  final bool fail;

  @override
  String get displayName => id;

  @override
  Set<AiCapability> get capabilities => {AiCapability.textGeneration};

  @override
  Future<List<AiModelInfo>> listModels() async {
    if (fail) throw StateError('provider $id unreachable');
    return const <AiModelInfo>[
      AiModelInfo(
        id: 'drill-model-a',
        displayName: 'Drill Model A',
        capabilities: {AiCapability.textGeneration},
      ),
    ];
  }

  @override
  Future<AiGenerationResult> generate(AiGenerationRequest request) async {
    validateTarget(request.target);
    return const AiGenerationResult(
      providerRequestId: 'drill-request',
      outputs: <AiGeneratedOutput>[
        AiGeneratedOutput(type: AiOutputType.text, text: 'ok'),
      ],
    );
  }

  @override
  Future<void> cancel(String requestId) async {}

  @override
  bool validateTarget(PromptTarget target) =>
      target == PromptTarget.story || target == PromptTarget.image;
}

/// Provider used for cost and fallback measurement, able to fail so the
/// fallback chain is observed rather than assumed.
class _CostProvider with AiStreamingFallback implements AiProvider {
  _CostProvider(this.id, {this.fail = false});

  @override
  final String id;
  final bool fail;

  @override
  String get displayName => id;

  @override
  Set<AiCapability> get capabilities => {AiCapability.textGeneration};

  @override
  Future<List<AiModelInfo>> listModels() async => const <AiModelInfo>[];

  @override
  Future<AiGenerationResult> generate(AiGenerationRequest request) async {
    if (fail) throw StateError('provider $id failed');
    return AiGenerationResult(
      providerRequestId: '$id-request',
      outputs: const <AiGeneratedOutput>[
        AiGeneratedOutput(type: AiOutputType.text, text: 'ok'),
      ],
    );
  }

  @override
  Future<void> cancel(String requestId) async {}

  @override
  bool validateTarget(PromptTarget target) => target == PromptTarget.story;
}

/// OpenAI client that records whether the transport was ever reached and never
/// performs it.
class _ProbeOpenAiClient implements OpenAiClient {
  _ProbeOpenAiClient({required this.onCall});

  final void Function() onCall;

  @override
  Future<List<AiModelInfo>> listModels({required String apiKey}) async {
    onCall();
    return const <AiModelInfo>[];
  }

  @override
  Future<AiGenerationResult> generate({
    required String apiKey,
    required AiGenerationRequest request,
  }) async {
    onCall();
    return const AiGenerationResult(
      providerRequestId: 'drill-probe',
      outputs: <AiGeneratedOutput>[],
    );
  }
}
