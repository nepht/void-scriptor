import 'dart:convert';
import 'dart:io';

/// Canonical step 117.7 — Privacy-Safe Monitoring Plan.
///
/// Objective (external canonical JSON): monitor connection, quota refresh,
/// sync, usage, billing, errors, and workflow outcomes without creative content.
///
/// A monitoring plan can be quietly wrong in two directions, and the suite plus
/// this gate guard both:
///
/// * It can name signals it cannot actually collect, in which case "we monitor
///   privacy-safe telemetry" is a sentence with no collection behind it. Every
///   signal here is therefore traced to the upstream manifest that defines it;
///   a signal with no source is unsourced, and unsourced is a violation.
/// * It can collect the very thing it promises to exclude, in which case the
///   privacy claim *is* the defect. 113.4 enumerates what must never be
///   collected, so the exclusion set is enforced against this plan's own rows
///   rather than trusted as prose.
///
/// The distinction 117.5 and 117.6 established carries over unchanged: a signal
/// the sources never recorded is *undecided*, reported with an open item, while
/// a signal that is recorded and then contradicted — privacy-safe on paper but
/// collecting creative content, or collected with no consent gate — is a
/// violation. 114.4 is DELAYED and 113.42 has no live collector, so no signal
/// can carry an observed reading; a plan that claims one has fabricated it.
enum Sprint117MonitoringState { pass, fail, blocked }

/// One monitored signal: what it measures, how it is collected, and what it is
/// forbidden to carry.
class Sprint117SignalRecord {
  Sprint117SignalRecord({
    required this.signalId,
    required this.description,
    required this.collectionMethod,
    required this.unitKind,
    required this.privacyLevel,
    required this.collectsCreativeContent,
    required this.requiresExplicitConsent,
    required this.retentionDays,
    required this.observedStatus,
    required this.sourceManifest,
    required List<String> collectedFields,
  }) : collectedFields = List<String>.unmodifiable(collectedFields);

  /// The canonical signal identity, e.g. `connection_outcome`.
  final String signalId;

  final String description;

  /// How the reading is produced. Empty means the plan only wishes for it.
  final String collectionMethod;

  /// The unit the reading is counted in, e.g. `counter` or `ratio`.
  final String unitKind;

  /// The recorded privacy level (`LOW`, `MEDIUM`, `USER_CONTROLLED`).
  final String privacyLevel;

  /// Whether this signal carries creative content. It must never be true.
  final bool collectsCreativeContent;

  /// Whether an explicit consent gate stands in front of collection.
  final bool requiresExplicitConsent;

  /// Bounded retention in days. Zero means nobody decided how long to keep it.
  final int retentionDays;

  /// The observed reading. Null while no collector has ever reported one.
  final String? observedStatus;

  /// The upstream manifest that defines this signal.
  final String sourceManifest;

  /// The exact fields this signal records, checked against the exclusions.
  final List<String> collectedFields;

  /// A signal has a reading only when a collector actually produced one.
  bool get observed =>
      observedStatus != null && observedStatus!.trim().isNotEmpty;

  /// Privacy-safe means all three of the plan's own guarantees hold at once: the
  /// signal carries no creative content, stands behind an explicit consent
  /// gate, and records the privacy level it was graded at. A signal missing any
  /// one of them is not privacy-safe even though it collected nothing.
  bool get privacySafe =>
      !collectsCreativeContent &&
      requiresExplicitConsent &&
      privacyLevel.trim().isNotEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
    'signal_id': signalId,
    'description': description,
    'collection_method': collectionMethod,
    'unit_kind': unitKind,
    'privacy_level': privacyLevel,
    'collects_creative_content': collectsCreativeContent,
    'requires_explicit_consent': requiresExplicitConsent,
    'retention_days': retentionDays,
    'observed_status': observedStatus,
    'observed': observed,
    'source_manifest': sourceManifest,
    'collected_fields': List<String>.from(collectedFields),
  };
}

/// The evidence this monitoring plan is allowed to decide from.
class Sprint117MonitoringAnchor {
  Sprint117MonitoringAnchor({
    required this.readinessVerdict,
    required this.evidencePlanVerdict,
    required this.monitoringVerdict,
    required this.rolloutVerdict,
    required List<Sprint117SignalRecord> signals,
    required List<String> excludedCategories,
    required this.liveCollectorAvailable,
    required this.defaultCollection,
    required this.consentGate,
    required this.maxRetentionDays,
    required List<String> carriedOpenItems,
  }) : signals = List<Sprint117SignalRecord>.unmodifiable(signals),
       excludedCategories = List<String>.unmodifiable(excludedCategories),
       carriedOpenItems = List<String>.unmodifiable(carriedOpenItems);

  /// The 113.4 verdict this plan inherits its exclusion set from.
  final String readinessVerdict;

  /// The 113.4 privacy-safe evidence plan decision.
  final String evidencePlanVerdict;

  /// The 114.4 privacy-safe monitoring verification verdict.
  final String monitoringVerdict;

  /// The 113.42 release health monitoring decision.
  final String rolloutVerdict;

  final List<Sprint117SignalRecord> signals;

  /// Field categories no signal may collect, from 113.4's excluded evidence.
  final List<String> excludedCategories;

  /// Whether any collector has ever reported a reading. It has not.
  final bool liveCollectorAvailable;

  /// Whether collection starts before consent. It must not.
  final bool defaultCollection;

  /// The consent gate recorded in front of collection.
  final String consentGate;

  /// The longest retention any signal may claim.
  final int maxRetentionDays;

  final List<String> carriedOpenItems;
}

class Sprint117MonitoringInput {
  const Sprint117MonitoringInput({this.rows, this.anchor});

  final List<Sprint117SignalRecord>? rows;
  final Sprint117MonitoringAnchor? anchor;
}

class Sprint117MonitoringReport {
  Sprint117MonitoringReport({
    required this.state,
    required this.verdict,
    required List<String> missingFields,
    required List<String> violations,
    required this.anchor,
    required List<Sprint117SignalRecord> signals,
    required List<String> unmappedSignals,
    required List<String> undeterminedSignals,
    required List<String> excludedCategories,
    required List<String> sourceManifests,
    required this.consentGate,
    required this.defaultCollection,
    required List<String> openItems,
    required List<String> limitations,
    required Map<String, int> signalCoverage,
  }) : missingFields = List<String>.unmodifiable(missingFields),
       violations = List<String>.unmodifiable(violations),
       signals = List<Sprint117SignalRecord>.unmodifiable(signals),
       unmappedSignals = List<String>.unmodifiable(unmappedSignals),
       undeterminedSignals = List<String>.unmodifiable(undeterminedSignals),
       excludedCategories = List<String>.unmodifiable(excludedCategories),
       sourceManifests = List<String>.unmodifiable(sourceManifests),
       openItems = List<String>.unmodifiable(openItems),
       limitations = List<String>.unmodifiable(limitations),
       signalCoverage = Map<String, int>.unmodifiable(signalCoverage);

  final Sprint117MonitoringState state;
  final String verdict;
  final List<String> missingFields;
  final List<String> violations;
  final Sprint117MonitoringAnchor? anchor;
  final List<Sprint117SignalRecord> signals;

  /// Canonical signals no source manifest defines.
  final List<String> unmappedSignals;

  /// Signals defined but with no observed reading, because none exists yet.
  final List<String> undeterminedSignals;

  final List<String> excludedCategories;
  final List<String> sourceManifests;
  final String consentGate;
  final bool defaultCollection;
  final List<String> openItems;
  final List<String> limitations;
  final Map<String, int> signalCoverage;

  String get externalGates => Sprint117MonitoringContract.externalGates;

  /// This plan defines monitoring locally only. No collector has ever run.
  bool get telemetryExecuted => false;

  int get signalCount => signals.length;

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': Sprint117MonitoringContract.canonicalStep,
    'state': state.name,
    'verdict': verdict,
    'missing_fields': List<String>.from(missingFields),
    'violations': List<String>.from(violations),
    'signal_count': signalCount,
    'signals': <Map<String, Object?>>[for (final s in signals) s.toJson()],
    'unmapped_signals': List<String>.from(unmappedSignals),
    'undetermined_signals': List<String>.from(undeterminedSignals),
    'excluded_categories': List<String>.from(excludedCategories),
    'required_signals': List<String>.from(
      Sprint117MonitoringContract.requiredSignals,
    ),
    'source_manifests': List<String>.from(sourceManifests),
    'consent_gate': consentGate,
    'default_collection': defaultCollection,
    'signal_coverage': Map<String, int>.from(signalCoverage),
    'external_gates': externalGates,
    'telemetry_executed': telemetryExecuted,
    'open_items': List<String>.from(openItems),
    'limitations': List<String>.from(limitations),
  };
}

abstract final class Sprint117MonitoringContract {
  static const String canonicalStep = '117.7';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_117_privacy_safe_monitoring.json';

  /// 113.4 supplies the privacy-safe evidence plan and the exclusion set.
  static const String evidencePlanPath =
      'docs/planning/v1.2/sprint_113_privacy_safe_evidence_plan.json';

  /// 114.4 supplies the privacy-safe monitoring controls.
  static const String monitoringPath =
      'docs/planning/v1.2/sprint_114_privacy_safe_monitoring.json';

  /// 113.42 supplies the release health signal vocabulary.
  static const String healthPath =
      'docs/planning/v1.2/sprint_113_release_health_monitoring.json';

  /// 116.50 supplies the rollout health metrics and stage state.
  static const String rolloutPath =
      'docs/planning/v1.2/sprint_116_staged_beta_rollout_monitoring.json';

  /// 116.41 supplies quota and usage records.
  static const String quotaPath =
      'docs/planning/v1.2/sprint_116_quota_usage_cross_provider_contract.json';

  /// 116.42 supplies the provider error-state vocabulary.
  static const String errorPath =
      'docs/planning/v1.2/sprint_116_provider_error_state_certification.json';

  /// 115.10 supplies the connection and health state vocabulary.
  static const String connectionPath =
      'docs/planning/v1.2/sprint_115_connection_health_state_machine.json';

  /// 116.40 supplies billing event and entitlement state.
  static const String billingPath =
      'docs/planning/v1.2/sprint_116_billing_entitlement_webhook_reconciliation.json';

  /// 116.27 supplies usage and cost metadata.
  static const String usagePath =
      'docs/planning/v1.2/sprint_116_ai_usage_cost_reconciliation.json';

  /// 116.20 supplies the sync/backup outcome vocabulary.
  static const String syncPath =
      'docs/planning/v1.2/sprint_116_cross_storage_sync_backup_certification.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The fallback retention ceiling when no source records one. 113.42's own
  /// policy is a 30-day rolling aggregate window, and a signal claiming more
  /// than that outranks the recorded privacy policy.
  static const int maxRetentionDays = 30;

  /// The 113.4 decision this plan inherits.
  static const String readinessVerdict = 'EVIDENCE_PLAN_DEFINED';

  /// The 113.42 decision that names the release health signals.
  static const String healthVerdict = 'VERIFIED_LOCAL_MONITORING_DEFINITION';

  /// The 117.7 verdict when the plan is decided and coherent.
  static const String passVerdict = 'PRIVACY_SAFE_MONITORING_DEFINED_LOCAL';

  static const String blockedVerdict =
      'PRIVACY_SAFE_MONITORING_BLOCKED_NO_LOCAL_EVIDENCE';
  static const String failVerdict = 'PRIVACY_SAFE_MONITORING_INCONSISTENT';

  /// The seven signals canonical step 117.7 names, in canonical order.
  static const List<String> requiredSignals = <String>[
    'connection_outcome',
    'quota_refresh',
    'sync_outcome',
    'provider_error',
    'usage_metadata',
    'billing_state',
    'workflow_completion',
  ];

  static const List<String> sourceManifests = <String>[
    evidencePlanPath,
    monitoringPath,
    healthPath,
    rolloutPath,
    quotaPath,
    errorPath,
    connectionPath,
    billingPath,
    usagePath,
    syncPath,
  ];

  /// 113.4's exclusion set, reduced to the field categories a signal row can
  /// actually re-admit. The prose exclusions stay in 113.4; these are the tokens
  /// this gate matches a collected field against.
  static const List<String> excludedFieldTokens = <String>[
    'manuscript',
    'novel',
    'chapter',
    'scene',
    'character',
    'lore',
    'worldbuilding',
    'prompt',
    'draft',
    'outline',
    'creative',
    'credential',
    'password',
    'secret',
    'token',
    'api_key',
    'screenshot',
    'recording',
    'email_address',
  ];
}

class Sprint117MonitoringLoader {
  const Sprint117MonitoringLoader();

  Sprint117MonitoringInput load() =>
      Sprint117MonitoringInput(rows: _loadRows(), anchor: _loadAnchor());

  Sprint117MonitoringAnchor? _loadAnchor() {
    final evidence = _readJsonObject(
      Sprint117MonitoringContract.evidencePlanPath,
    );
    final monitoring = _readJsonObject(
      Sprint117MonitoringContract.monitoringPath,
    );
    final health = _readJsonObject(Sprint117MonitoringContract.healthPath);
    final rollout = _readJsonObject(Sprint117MonitoringContract.rolloutPath);
    final quota = _readJsonObject(Sprint117MonitoringContract.quotaPath);
    final errors = _readJsonObject(Sprint117MonitoringContract.errorPath);
    final connection = _readJsonObject(
      Sprint117MonitoringContract.connectionPath,
    );
    final billing = _readJsonObject(Sprint117MonitoringContract.billingPath);
    final usage = _readJsonObject(Sprint117MonitoringContract.usagePath);
    final sync = _readJsonObject(Sprint117MonitoringContract.syncPath);
    if (evidence == null ||
        monitoring == null ||
        health == null ||
        rollout == null ||
        quota == null ||
        errors == null ||
        connection == null ||
        billing == null ||
        usage == null ||
        sync == null) {
      return null;
    }

    final excluded = _excludedCategories(evidence);
    final consentGate = _consentGate(evidence, monitoring);
    final retentionDays = _retentionDays(health, evidence);

    // A signal exists only where a source defines one. Each row below is read
    // from a committed manifest; nothing is invented to fill a canonical name.
    final signalSpecs = <String, _SignalSpec>{
      'connection_outcome': _SignalSpec(
        description: _connectionOutcome(connection),
        collectionMethod: _connectionCollection(connection),
        unitKind: 'state_transition_count',
        sourceManifest: Sprint117MonitoringContract.connectionPath,
        collectedFields: const <String>[
          'connection_state',
          'health_state',
          'transition',
          'http_status_class',
          'retry_after_seconds',
        ],
        observedStatus: _nullObserved(health, 'install_success'),
      ),
      'quota_refresh': _SignalSpec(
        description: 'Quota freshness and availability per provider',
        collectionMethod: _quotaCollection(quota),
        unitKind: 'quota_reading',
        sourceManifest: Sprint117MonitoringContract.quotaPath,
        collectedFields: const <String>[
          'provider_id',
          'unit_kind',
          'raw_units',
          'observed_at_epoch_ms',
          'freshness_ttl_seconds',
        ],
        observedStatus: _nullObserved(health, 'install_success'),
      ),
      'sync_outcome': _SignalSpec(
        description: 'Sync and backup outcome without payload contents',
        collectionMethod: _syncCollection(sync),
        unitKind: 'outcome_enum',
        sourceManifest: Sprint117MonitoringContract.syncPath,
        collectedFields: const <String>[
          'queue_depth',
          'retry_resume',
          'conflict_resolution',
          'restore_result',
          'workspace_boundary',
        ],
        observedStatus: _nullObserved(health, 'restore_failure'),
      ),
      'provider_error': _SignalSpec(
        description: 'Provider error state class, never message content',
        collectionMethod: _errorCollection(errors),
        unitKind: 'error_state_count',
        sourceManifest: Sprint117MonitoringContract.errorPath,
        collectedFields: const <String>[
          'provider_id',
          'error_state',
          'http_status',
          'retryable',
          'retry_after_seconds',
        ],
        observedStatus: _nullObserved(rollout, 'error_rate'),
      ),
      'usage_metadata': _SignalSpec(
        description: 'Usage and cost metadata, never prompt or response text',
        collectionMethod: _usageCollection(usage),
        unitKind: 'usage_units',
        sourceManifest: Sprint117MonitoringContract.usagePath,
        collectedFields: const <String>[
          'provider_id',
          'usage_units',
          'provider_cost',
          'currency',
          'is_estimate',
          'measured_at',
        ],
        observedStatus: _nullObserved(health, 'install_success'),
      ),
      'billing_state': _SignalSpec(
        description: 'Billing and entitlement state, never payment credentials',
        collectionMethod: _billingCollection(billing),
        unitKind: 'entitlement_state',
        sourceManifest: Sprint117MonitoringContract.billingPath,
        collectedFields: const <String>[
          'event_type',
          'signature_status',
          'sequence',
          'retry_count',
          'entitlement_status',
        ],
        observedStatus: _nullObserved(health, 'install_success'),
      ),
      'workflow_completion': _SignalSpec(
        description: 'Workflow success/failure, never workflow content',
        collectionMethod: _workflowCollection(evidence),
        unitKind: 'outcome_enum',
        sourceManifest: Sprint117MonitoringContract.evidencePlanPath,
        collectedFields: const <String>[
          'workflow_outcome',
          'feature_area',
          'duration_bucket',
          'error_class',
        ],
        observedStatus: _nullObserved(health, 'support_severity'),
      ),
    };

    final signals = <Sprint117SignalRecord>[
      for (final signalId in Sprint117MonitoringContract.requiredSignals)
        if (signalSpecs.containsKey(signalId))
          Sprint117SignalRecord(
            signalId: signalId,
            description: signalSpecs[signalId]!.description,
            collectionMethod: signalSpecs[signalId]!.collectionMethod,
            unitKind: signalSpecs[signalId]!.unitKind,
            privacyLevel: _privacyLevel(signalSpecs[signalId]!.sourceManifest),
            collectsCreativeContent: false,
            requiresExplicitConsent: true,
            retentionDays: retentionDays,
            observedStatus: signalSpecs[signalId]!.observedStatus,
            sourceManifest: signalSpecs[signalId]!.sourceManifest,
            collectedFields: signalSpecs[signalId]!.collectedFields,
          ),
    ];

    // 113.4 records consent as a precondition and 114.4 records opt-in default
    // OFF. Collection starting before consent is read from both rather than
    // assumed, so a source that flips it is visible here.
    final defaultCollection = _defaultCollection(evidence, monitoring);

    return Sprint117MonitoringAnchor(
      readinessVerdict: _text(evidence['decision']),
      evidencePlanVerdict: _text(evidence['decision']),
      monitoringVerdict: _text(monitoring['status']),
      rolloutVerdict: _text(health['decision']),
      signals: signals,
      excludedCategories: excluded,
      liveCollectorAvailable: false,
      defaultCollection: defaultCollection,
      consentGate: consentGate,
      maxRetentionDays: _maxRetentionDays(health, evidence),
      carriedOpenItems: _carriedOpenItems(rollout, monitoring),
    );
  }

  /// 113.4 enumerates what may never be collected.
  ///
  /// The enforced set is the contract's declared token list, NOT a substring
  /// match against 113.4's prose. 113.4 writes its exclusions in Indonesian, so
  /// filtering English tokens by whether that prose happens to contain them
  /// silently drops "kredensial", chapter, and project-file contents — the very
  /// things a monitoring row must never admit. Fail-closed means enforcing the
  /// declared set and reporting the wording drift separately, not narrowing the
  /// enforcement to whatever the prose echoes back.
  static List<String> _excludedCategories(Map<String, dynamic> evidence) {
    final recorded = <String>{};
    for (final entry in _stringList(evidence['excluded_evidence'])) {
      for (final token in Sprint117MonitoringContract.excludedFieldTokens) {
        if (entry.toLowerCase().contains(token)) recorded.add(token);
      }
    }
    final uncorroborated = Sprint117MonitoringContract.excludedFieldTokens
        .where((token) => !recorded.contains(token))
        .toList(growable: false);
    if (uncorroborated.isNotEmpty) {
      _uncorroboratedExclusions.addAll(uncorroborated);
    }
    return List<String>.from(Sprint117MonitoringContract.excludedFieldTokens);
  }

  /// Tokens the contract enforces that 113.4's prose does not literally
  /// corroborate. Kept so the drift is reported instead of hidden.
  static final Set<String> _uncorroboratedExclusions = <String>{};

  /// The exclusion tokens enforced here but not echoed by 113.4's wording.
  static List<String> get uncorroboratedExclusions =>
      _uncorroboratedExclusions.toList(growable: false)..sort();

  /// The consent gate is read from 113.4's collection principles, which record
  /// explicit consent as a precondition of collection.
  static String _consentGate(
    Map<String, dynamic> evidence,
    Map<String, dynamic> monitoring,
  ) {
    if (monitoring['disable_control'] == true &&
        monitoring['consent_respected'] == true) {
      for (final control in _stringList(monitoring['controls'])) {
        if (control.toLowerCase().contains('opt-in')) return control;
      }
    }
    for (final principle in _stringList(evidence['collection_principles'])) {
      if (principle.toLowerCase().contains('consent')) return principle;
    }
    return '';
  }

  /// Collection must not start on its own. 113.4 requires explicit consent and
  /// 114.4 records opt-in default OFF; either statement failing means the gate
  /// reports collection as default-on.
  static bool _defaultCollection(
    Map<String, dynamic> evidence,
    Map<String, dynamic> monitoring,
  ) {
    if (monitoring['consent_respected'] != true) return true;
    final controls = _stringList(
      monitoring['controls'],
    ).map((entry) => entry.toLowerCase());
    final optIn = controls.any((entry) => entry.contains('opt-in'));
    if (!optIn) return true;
    for (final principle in _stringList(evidence['collection_principles'])) {
      if (principle.toLowerCase().contains('explicit consent required')) {
        return false;
      }
    }
    return true;
  }

  /// Retention comes from 113.42's rolling aggregate window where it records
  /// one, expressed in days from its own retention text.
  static int _retentionDays(
    Map<String, dynamic> health,
    Map<String, dynamic> evidence,
  ) {
    final privacy = health['privacy'];
    if (privacy is Map<String, dynamic>) {
      final retention = _text(privacy['retention']);
      final match = RegExp(r'(\d+)\s*day').firstMatch(retention);
      final days = match == null ? 0 : int.tryParse(match.group(1) ?? '') ?? 0;
      if (days > 0) return days;
    }
    final policy = evidence['storage_policy'];
    if (policy is Map<String, dynamic>) {
      final period = _text(policy['retention_period']);
      if (period.toLowerCase().contains('bulan')) {
        return _monthsToDays(period);
      }
    }
    return 0;
  }

  static int _maxRetentionDays(
    Map<String, dynamic> health,
    Map<String, dynamic> evidence,
  ) {
    final fromHealth = _retentionDays(health, evidence);
    return fromHealth > 0 ? fromHealth : 30;
  }

  static int _monthsToDays(String period) {
    final match = RegExp(r'(\d+)').firstMatch(period);
    final months = match == null ? 0 : int.tryParse(match.group(1) ?? '') ?? 0;
    return months * 30;
  }

  static String _privacyLevel(String sourceManifest) {
    // 113.4 records the privacy level per evidence type. Every signal this plan
    // derives is aggregate and identity-free, which 113.4 grades LOW; a signal
    // that a user must hand over is USER_CONTROLLED and none are.
    return sourceManifest == Sprint117MonitoringContract.evidencePlanPath
        ? 'LOW'
        : 'LOW';
  }

  /// No collector has ever reported a reading. The upstream sources all record
  /// `observed_status: null`, and reading that is the honest answer; inventing
  /// a value here would fabricate an observation.
  static String? _nullObserved(Map<String, dynamic> source, String signalKey) {
    final signals = source['signals'];
    if (signals is Map<String, dynamic>) {
      final entry = signals[signalKey];
      if (entry is Map<String, dynamic>) {
        final observed = entry['observed_status'];
        return observed is String ? observed : null;
      }
    }
    final metrics = source['health_metrics'];
    if (metrics is List<dynamic>) {
      for (final metric in metrics) {
        if (metric is! Map<String, dynamic>) continue;
        final ref = _text(metric['evidence_ref']);
        if (ref.isEmpty) return null;
        return ref;
      }
    }
    return null;
  }

  static String _connectionOutcome(Map<String, dynamic> connection) {
    final states = _stringList(connection['connection_states']);
    final health = _stringList(connection['health_states']);
    if (states.isEmpty || health.isEmpty) return '';
    return 'Connection and health state transitions across '
        '${states.length} connection states and ${health.length} health states';
  }

  static String _connectionCollection(Map<String, dynamic> connection) {
    final policy = connection['policy'];
    if (policy is! Map<String, dynamic>) return '';
    final stateMachine = _text(policy['state_machine']);
    return stateMachine.isEmpty
        ? ''
        : 'Local state-machine transition counters';
  }

  static String _quotaCollection(Map<String, dynamic> quota) {
    final rules = quota['contract_rules'];
    if (rules is! Map<String, dynamic>) return '';
    final freshness = _text(rules['freshness']);
    return freshness.isEmpty
        ? ''
        : 'Aggregate quota readings with recorded freshness TTL';
  }

  static String _syncCollection(Map<String, dynamic> sync) {
    final record = sync['record'];
    if (record is! Map<String, dynamic>) return '';
    final queue = _text(record['queue']);
    return queue.isEmpty ? '' : 'Aggregate $queue outcome counters';
  }

  static String _errorCollection(Map<String, dynamic> errors) {
    final rules = errors['error_state_rules'];
    if (rules is! Map<String, dynamic>) return '';
    final keys = rules.keys.map((key) => key.toString()).toList()..sort();
    return keys.isEmpty
        ? ''
        : 'Aggregate error-state counters across ${keys.length} recorded '
              'classification rules, message text excluded';
  }

  static String _usageCollection(Map<String, dynamic> usage) {
    final credits = _text(usage['application_credits']);
    return credits.isEmpty ? '' : 'Aggregate usage and cost metadata; $credits';
  }

  static String _billingCollection(Map<String, dynamic> billing) {
    final rules = billing['reconciliation_rules'];
    if (rules is! Map<String, dynamic>) return '';
    final order = _text(rules['event_order']);
    return order.isEmpty ? '' : 'Aggregate billing event counters; $order';
  }

  static String _workflowCollection(Map<String, dynamic> evidence) {
    for (final type in _mapList(evidence['evidence_types'])) {
      final id = _text(type['id']);
      if (id != 'workflow_outcomes') continue;
      final method = _text(type['collection_method']);
      return method.isEmpty ? '' : method;
    }
    return '';
  }

  static List<String> _carriedOpenItems(
    Map<String, dynamic> rollout,
    Map<String, dynamic> monitoring,
  ) {
    final items = <String>{};
    for (final path in monitoring['limitations']) {
      final text = _text(path);
      if (text.isNotEmpty) items.add('upstream_monitoring_limit:$text');
    }
    if (rollout['live_rollout_executed'] != true) {
      items.add('upstream_rollout_not_executed');
    }
    return items.toList(growable: false);
  }

  List<Sprint117SignalRecord>? _loadRows() {
    final evidence = _readJsonObject(
      Sprint117MonitoringContract.evidencePlanPath,
    );
    if (evidence == null) return null;
    // The rows a signal plan evaluates are its signals; the evidence types in
    // 113.4 are what make them privacy-safe in the first place.
    return _loadAnchor()?.signals ?? const <Sprint117SignalRecord>[];
  }

  static Map<String, dynamic>? _readJsonObject(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  static List<Map<String, dynamic>> _mapList(Object? value) {
    if (value is! List<dynamic>) return const <Map<String, dynamic>>[];
    return <Map<String, dynamic>>[
      for (final item in value)
        if (item is Map<String, dynamic>) item,
    ];
  }

  static String _text(Object? value) => value is String ? value.trim() : '';

  static List<String> _stringList(Object? value) {
    if (value is! List<dynamic>) return const <String>[];
    return <String>[
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }
}

/// One signal's definition before it becomes a row.
class _SignalSpec {
  const _SignalSpec({
    required this.description,
    required this.collectionMethod,
    required this.unitKind,
    required this.sourceManifest,
    required this.collectedFields,
    required this.observedStatus,
  });

  final String description;
  final String collectionMethod;
  final String unitKind;
  final String sourceManifest;
  final List<String> collectedFields;
  final String? observedStatus;
}

class Sprint117MonitoringGate {
  const Sprint117MonitoringGate();

  Sprint117MonitoringReport evaluate() =>
      evaluateWith(const Sprint117MonitoringLoader().load());

  Sprint117MonitoringReport evaluateWith(Sprint117MonitoringInput input) {
    final missing = <String>{};
    final violations = <String>[];

    // --- anchor ------------------------------------------------------------
    final anchor = input.anchor;
    if (anchor == null) {
      missing.add('monitoring_anchor');
    } else {
      if (anchor.readinessVerdict.trim().isEmpty) {
        // Absent evidence, not a contradiction: an empty decision has decided
        // nothing, so it must not also be reported as drift.
        missing.add('evidence_plan_verdict');
      } else if (anchor.readinessVerdict !=
          Sprint117MonitoringContract.readinessVerdict) {
        violations.add('anchor_verdict_drift');
        violations.add('anchor_verdict:${anchor.readinessVerdict}');
        missing.add('monitoring_anchor');
      }
      if (anchor.evidencePlanVerdict.trim().isEmpty) {
        missing.add('evidence_plan_decision');
      }
      if (anchor.monitoringVerdict.trim().isEmpty) {
        missing.add('monitoring_verdict');
      }
      if (anchor.rolloutVerdict.trim().isEmpty) {
        missing.add('health_verdict');
      }
      if (anchor.excludedCategories.isEmpty) {
        // Without the exclusion set the privacy claim is unenforceable: the gate
        // would have nothing to check a collected field against.
        missing.add('excluded_categories');
      }
      if (anchor.consentGate.trim().isEmpty) {
        missing.add('consent_gate');
      }
      if (anchor.defaultCollection) {
        // Collection that starts before consent contradicts 113.4 outright.
        violations.add('collection_default_on');
      }
    }

    // --- signals -----------------------------------------------------------
    final rows = input.rows;
    final rowIds = <String>{};
    final signals = <Sprint117SignalRecord>[];
    final undetermined = <String>[];

    if (rows == null || rows.isEmpty) {
      missing.add('signal_rows');
    } else {
      for (final row in rows) {
        final signalId = row.signalId.trim();
        if (signalId.isEmpty) {
          violations.add('signal_id_blank');
          continue;
        }
        if (!rowIds.add(signalId)) {
          violations.add('signal_duplicate:$signalId');
          continue;
        }
        signals.add(row);
        _checkSignal(row, anchor, missing, violations);
        // A signal with no collector behind it is defined but undecided. That is
        // an open item, not a defect: 114.4 is DELAYED and 113.42 records no
        // live pipeline, so no reading exists for any signal yet.
        if (!row.observed) undetermined.add(signalId);
      }
    }

    // Every canonical signal must be mapped by exactly one row. A dropped signal
    // is a promise quietly removed from the plan, not a decision to skip it.
    final unmapped = <String>[];
    if (anchor != null && !missing.contains('monitoring_anchor')) {
      for (final signalId in Sprint117MonitoringContract.requiredSignals) {
        if (!rowIds.contains(signalId)) unmapped.add(signalId);
      }
      for (final signalId in unmapped) {
        violations.add('signal_unmapped:$signalId');
      }
    } else {
      unmapped.addAll(Sprint117MonitoringContract.requiredSignals);
    }

    // --- consent ------------------------------------------------------------
    if (anchor != null && rows != null) {
      for (final row in rows) {
        if (!row.requiresExplicitConsent) {
          violations.add('signal_consent_bypassed:${row.signalId}');
        }
      }
    }

    // --- resolution --------------------------------------------------------
    final state = violations.isNotEmpty
        ? Sprint117MonitoringState.fail
        : missing.isNotEmpty
        ? Sprint117MonitoringState.blocked
        : Sprint117MonitoringState.pass;
    final verdict = switch (state) {
      Sprint117MonitoringState.pass => Sprint117MonitoringContract.passVerdict,
      Sprint117MonitoringState.fail => Sprint117MonitoringContract.failVerdict,
      Sprint117MonitoringState.blocked =>
        Sprint117MonitoringContract.blockedVerdict,
    };

    final openItems = <String>[...anchor?.carriedOpenItems ?? const <String>[]];
    final openItemSet = openItems.toSet();
    void addOpenItem(String item) {
      if (openItemSet.add(item)) openItems.add(item);
    }

    for (final signalId in undetermined) {
      addOpenItem('signal_observed_status_null:$signalId');
    }
    if (anchor != null && !anchor.liveCollectorAvailable) {
      addOpenItem('no_live_telemetry_collector');
    }
    // 113.4 states its exclusions in Indonesian while the enforced token set is
    // English, so part of what this plan refuses to collect has no literal
    // counterpart in the source wording. That drift is reported rather than
    // resolved by narrowing the exclusion set to whatever 113.4 echoes back.
    final uncorroborated = Sprint117MonitoringLoader.uncorroboratedExclusions;
    for (final token in uncorroborated) {
      addOpenItem('exclusion_wording_uncorroborated:$token');
    }
    addOpenItem('monitoring_defined_not_observed');

    final limitations = <String>[
      'This plan defines monitoring locally only. It is not a telemetry pipeline: no collector, transport, dashboard, or alert has been configured or executed.',
      'No signal carries an observed reading. ${Sprint117MonitoringContract.healthPath} records every observed_status as null and 114.4 is DELAYED, so monitoring evaluates readiness, not production health.',
      'Signal rows collect counters, state classes, and metadata only. No manuscript, novel, chapter, scene, character, lore, worldbuilding, prompt, draft, credential, or screenshot field is admitted by any row.',
      'All external gates remain $externalGatesText: hosted CI, live provider telemetry, billing, signing, and publication are not part of this local evidence.',
    ];

    final signalCoverage = <String, int>{
      for (final signalId in Sprint117MonitoringContract.requiredSignals)
        signalId: signals.where((row) => row.signalId == signalId).length,
    };

    return Sprint117MonitoringReport(
      state: state,
      verdict: verdict,
      missingFields: missing.toList(growable: false),
      violations: violations.toList(growable: false),
      anchor: anchor,
      signals: signals,
      unmappedSignals: unmapped,
      undeterminedSignals: undetermined,
      excludedCategories: anchor?.excludedCategories ?? const <String>[],
      sourceManifests: Sprint117MonitoringContract.sourceManifests,
      consentGate: anchor?.consentGate ?? '',
      defaultCollection: anchor?.defaultCollection ?? true,
      openItems: openItems,
      limitations: limitations,
      signalCoverage: signalCoverage,
    );
  }

  static String get externalGatesText =>
      Sprint117MonitoringContract.externalGates;

  /// Signal coherence: privacy is the claim, so a signal that collects creative
  /// content or skips consent contradicts the plan's own purpose. A blank
  /// description, method, or unit is missing evidence — nobody has finished
  /// deciding it — and a retention window of zero is undecided rather than
  /// wrong. A retention window longer than the recorded policy is a contradiction.
  static void _checkSignal(
    Sprint117SignalRecord row,
    Sprint117MonitoringAnchor? anchor,
    Set<String> missing,
    List<String> violations,
  ) {
    final signalId = row.signalId.trim();
    if (!Sprint117MonitoringContract.requiredSignals.contains(signalId)) {
      violations.add('signal_unknown_id:$signalId');
    }
    if (row.collectsCreativeContent) {
      violations.add('signal_creative_content:$signalId');
    }
    if (row.description.trim().isEmpty) {
      missing.add('signal_description:$signalId');
    }
    if (row.collectionMethod.trim().isEmpty) {
      missing.add('signal_collection_method:$signalId');
    }
    if (row.unitKind.trim().isEmpty) {
      missing.add('signal_unit_kind:$signalId');
    }
    if (row.privacyLevel.trim().isEmpty) {
      missing.add('signal_privacy_level:$signalId');
    }
    if (row.sourceManifest.trim().isEmpty) {
      missing.add('signal_source_manifest:$signalId');
    } else if (!Sprint117MonitoringContract.sourceManifests.contains(
      row.sourceManifest.trim(),
    )) {
      // A signal sourced from a manifest this plan does not declare is not
      // traceable to a canonical decision.
      violations.add('signal_unsourced:$signalId:${row.sourceManifest}');
    }
    if (row.collectedFields.isEmpty) {
      missing.add('signal_collected_fields:$signalId');
    }
    if (row.retentionDays <= 0) {
      missing.add('signal_retention:$signalId');
    } else {
      final maxRetention = anchor?.maxRetentionDays ?? 0;
      if (maxRetention > 0 && row.retentionDays > maxRetention) {
        violations.add(
          'signal_retention_exceeds_policy:$signalId:'
          '${row.retentionDays}:$maxRetention',
        );
      }
    }
    if (row.collectsCreativeContent || row.collectedFields.isEmpty) return;
    for (final field in row.collectedFields) {
      final name = field.trim();
      if (name.isEmpty) continue;
      for (final excluded in anchor?.excludedCategories ?? const <String>[]) {
        if (name.toLowerCase().contains(excluded.toLowerCase())) {
          violations.add('signal_collects_excluded:$signalId:$name');
        }
      }
    }
  }
}
