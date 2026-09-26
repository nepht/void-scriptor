/// Sprint 115.39 — Quick Actions.
///
/// The shortcut surface the Account & Cloud Center offers next to the
/// account rail: sync now, backup now, API keys, team invite, marketplace,
/// and settings.
///
/// The product spec makes this surface dangerous by design, so the contract
/// encodes the danger structurally instead of by convention:
///
/// * `reference_mock_values_never_reach_production_state` — the surface
///   executes nothing. A run without an injected executor is a *failed*
///   result, never a silent success.
/// * `reauth_before_sensitive_action` — [QuickActionKind.manageApiKeys] maps
///   to `reveal_or_replace_key` in `security_contract.sensitive_actions` and
///   refuses to run before an injected reauthentication broker returns true.
///   A missing broker is fail-closed.
/// * `all provider states have loading_empty_error_and_reauth handling` —
///   every attempt ends in an explicit [QuickActionPhase], never in silence.
///
/// A permission that cannot be proven is not a granted permission: an unknown
/// permission state disables every action, and every disabled action carries a
/// non-blank reason so the UI can explain itself instead of greying out a
/// button silently.
///
/// Live sync, live backup execution, key reveal/replace, invitation delivery,
/// marketplace access, and settings writes are not performed here; the
/// product-spec billing contract stays `PLANNED_NOT_VERIFIED`, reference mock
/// values cannot be produced, and public-trust signing, hosted CI, telemetry,
/// hardware, adoption, and publication stay `DEFERRED-EXTERNAL`.
library;

import 'dart:collection';

/// The quick actions the account rail offers, in the order the product spec
/// lists them.
enum QuickActionKind {
  syncNow,
  backupNow,
  manageApiKeys,
  inviteTeamMember,
  browseMarketplace,
  openSettings,
}

extension QuickActionKindWire on QuickActionKind {
  String get wireName => switch (this) {
    QuickActionKind.syncNow => 'sync_now',
    QuickActionKind.backupNow => 'backup_now',
    QuickActionKind.manageApiKeys => 'manage_api_keys',
    QuickActionKind.inviteTeamMember => 'invite_team_member',
    QuickActionKind.browseMarketplace => 'browse_marketplace',
    QuickActionKind.openSettings => 'open_settings',
  };

  String get label => switch (this) {
    QuickActionKind.syncNow => 'Sync now',
    QuickActionKind.backupNow => 'Back up now',
    QuickActionKind.manageApiKeys => 'Manage API keys',
    QuickActionKind.inviteTeamMember => 'Invite team member',
    QuickActionKind.browseMarketplace => 'Browse marketplace',
    QuickActionKind.openSettings => 'Open settings',
  };

  /// Actions named by `security_contract.sensitive_actions`.
  ///
  /// [manageApiKeys] maps to `reveal_or_replace_key`, the only one of the six
  /// quick actions that can expose or replace a credential.
  bool get isSensitive => this == QuickActionKind.manageApiKeys;

  /// Actions that change remote state and therefore refuse to run on a single
  /// click.
  bool get isConsequential =>
      this == QuickActionKind.backupNow ||
      this == QuickActionKind.inviteTeamMember;
}

/// Whether the action can be pressed right now.
enum QuickActionAvailability { enabled, disabled }

/// Lifecycle of a single run. `idle` is never stored: a run that has not
/// started has no state, which is a different fact from a run that finished.
enum QuickActionPhase { idle, running, succeeded, failed, cancelled }

/// Verdict recorded in the audit trail.
enum QuickActionAuditOutcome { denied, succeeded, failed, cancelled }

/// Thrown when a run is refused: undeclared, not permitted, unconfirmed, or
/// still awaiting reauthentication.
///
/// Extends [StateError] so callers that guard the surface generically keep
/// working, while a caller that wants to tell "refused" apart from an
/// unexpected internal failure can.
final class QuickActionStateError extends StateError {
  QuickActionStateError(super.message);
}

/// Executes a quick action and returns the message to show the user.
///
/// A `null` executor means the surface is not wired to anything yet.
typedef QuickActionExecutor = Future<String> Function(QuickActionKind kind);

/// Reports whether the user completed reauthentication.
typedef QuickActionReauthentication = bool Function();

/// Reports one progress step of a running action.
typedef QuickActionProgressReporter = void Function(QuickActionProgress step);

/// Permission state of the quick actions.
///
/// The default is grant-all; the *surface* holds the fail-closed `null`
/// state, because an absent permission source is not an empty denial list.
final class QuickActionPermissionSet {
  const QuickActionPermissionSet({
    this.denied = const <QuickActionKind>{},
    this.denialReasons = const <QuickActionKind, String>{},
  });

  const QuickActionPermissionSet.grantedAll()
    : this(denied: const <QuickActionKind>{});

  final Set<QuickActionKind> denied;
  final Map<QuickActionKind, String> denialReasons;

  bool isGranted(QuickActionKind kind) => !denied.contains(kind);

  /// The caller-supplied reason for a denial, or `null` when none was given.
  String? reasonFor(QuickActionKind kind) {
    final reason = denialReasons[kind];
    if (reason == null) return null;
    final trimmed = reason.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// What pressing the action would do right now.
final class QuickActionResolution {
  const QuickActionResolution({
    required this.kind,
    required this.isGranted,
    required this.availability,
    this.disabledReason,
  });

  final QuickActionKind kind;

  /// Whether the permission source says this action is allowed at all.
  final bool isGranted;

  final QuickActionAvailability availability;

  /// `null` only when the action is enabled.
  final String? disabledReason;

  bool get isEnabled => availability == QuickActionAvailability.enabled;

  bool get requiresConfirmation => kind.isConsequential;

  bool get requiresReauthentication => kind.isSensitive;
}

/// One reported progress step.
final class QuickActionProgress {
  QuickActionProgress({required num fraction}) : fraction = _clamp(fraction);

  final double fraction;

  /// Progress is never NaN and never leaves `0..1`; a caller that reports a
  /// broken value gets a bounded one instead of a nonsense bar.
  static double _clamp(num value) {
    if (value.isNaN) return 0;
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value.toDouble();
  }
}

/// Terminal outcome of a run.
final class QuickActionResult {
  const QuickActionResult({
    required this.action,
    required this.phase,
    required this.message,
    required this.startedAt,
    required this.completedAt,
  });

  final QuickActionKind action;
  final QuickActionPhase phase;
  final String? message;
  final DateTime startedAt;
  final DateTime completedAt;

  bool get isSuccess => phase == QuickActionPhase.succeeded;

  bool get isCancelled => phase == QuickActionPhase.cancelled;

  Map<String, Object?> toPublicJson() => <String, Object?>{
    'action': action.wireName,
    'phase': phase.name,
    'message': message,
    'started_at': startedAt.toIso8601String(),
    'completed_at': completedAt.toIso8601String(),
  };
}

/// Current state of one action.
final class QuickActionRunState {
  QuickActionRunState({
    required this.action,
    required this.phase,
    required this.startedAt,
  }) : progress = <QuickActionProgress>[];

  final QuickActionKind action;
  QuickActionPhase phase;
  final DateTime startedAt;
  final List<QuickActionProgress> progress;
}

/// One audited attempt. Carries a verdict, never a payload.
final class QuickActionAuditEvent {
  const QuickActionAuditEvent({
    required this.action,
    required this.outcome,
    required this.at,
    this.reason,
  });

  final QuickActionKind action;
  final QuickActionAuditOutcome outcome;
  final DateTime at;

  /// Why the attempt failed or was refused. Never the executor's return
  /// value, which may carry provider payload.
  final String? reason;

  Map<String, Object?> toPublicJson() => <String, Object?>{
    'action': action.wireName,
    'outcome': outcome.name,
    'at': at.toIso8601String(),
    'reason': reason,
  };
}

final class AccountCenterQuickActions {
  /// Product-spec `billing_contract.status`; this step never claims a live
  /// billing integration.
  static const String billingContractStatus = 'PLANNED_NOT_VERIFIED';

  /// `reference_mock_values.production_use_allowed`.
  static const bool referenceMockValuesAllowed = false;

  /// Signing, hosted CI, telemetry, hardware, adoption, and publication.
  static const String externalGateStatus = 'DEFERRED-EXTERNAL';

  static const canonicalAcceptance = <String>[
    'permission_aware',
    'disabled_reason',
    'confirmation',
    'progress',
    'result',
    'audit',
  ];

  static const canonicalSprintPath =
      'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/sprint_115.json';
  static const canonicalSprintSha256 =
      'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba';

  /// Canonical quick actions named by the step objective.
  static const canonicalActionKinds = <QuickActionKind>[
    QuickActionKind.syncNow,
    QuickActionKind.backupNow,
    QuickActionKind.manageApiKeys,
    QuickActionKind.inviteTeamMember,
    QuickActionKind.browseMarketplace,
    QuickActionKind.openSettings,
  ];

  static const String unknownPermissionReason = 'Permission state unavailable';
  static const String unknownDenialReason = 'Not permitted';

  AccountCenterQuickActions({
    required Set<QuickActionKind> actions,
    this.permissions,
    this.executor,
    this.reauthenticate,
    DateTime Function()? now,
  }) : _actions = Set<QuickActionKind>.of(actions),
       _now = now ?? _systemClock;

  static DateTime _systemClock() => DateTime.now().toUtc();

  /// `null` means the permission source is unavailable, which is not the same
  /// as "nothing is denied".
  final QuickActionPermissionSet? permissions;

  final QuickActionExecutor? executor;
  final QuickActionReauthentication? reauthenticate;
  final DateTime Function() _now;
  final Set<QuickActionKind> _actions;
  final Map<QuickActionKind, QuickActionRunState> _states =
      <QuickActionKind, QuickActionRunState>{};
  final List<QuickActionResult> _results = <QuickActionResult>[];
  final List<QuickActionAuditEvent> _audit = <QuickActionAuditEvent>[];
  final Set<QuickActionKind> _running = <QuickActionKind>{};
  final Set<QuickActionKind> _cancelRequested = <QuickActionKind>{};

  List<QuickActionKind> get actions =>
      UnmodifiableListView(QuickActionKind.values.where(_actions.contains));

  List<QuickActionResult> get results => UnmodifiableListView(_results);

  List<QuickActionAuditEvent> get audit => UnmodifiableListView(_audit);

  QuickActionRunState? stateOf(QuickActionKind kind) => _states[kind];

  List<QuickActionProgress> progressOf(QuickActionKind kind) =>
      UnmodifiableListView(_states[kind]?.progress ?? const []);

  /// Requests cancellation of the next or running [kind] run.
  void cancel(QuickActionKind kind) {
    _cancelRequested.add(kind);
  }

  /// What the surface would do if the user pressed [kind] right now.
  ///
  /// Throws [StateError] for an action the surface does not declare — an
  /// undeclared action is a wiring defect, not a hidden permission.
  QuickActionResolution resolve(
    QuickActionKind kind, {
    bool confirmed = false,
  }) {
    _requireDeclared(kind);
    if (!isPermissionGranted(kind)) {
      return _disabled(
        kind,
        isGranted: false,
        reason: denialReasonFor(kind) ?? unknownPermissionReason,
      );
    }
    if (kind.isConsequential && !confirmed) {
      return _disabled(
        kind,
        isGranted: true,
        reason: '${kind.label} must be confirmed before it runs',
      );
    }
    if (kind.isSensitive) {
      return _disabled(
        kind,
        isGranted: true,
        reason: 'Reauthentication is required for ${kind.label}',
      );
    }
    return QuickActionResolution(
      kind: kind,
      isGranted: true,
      availability: QuickActionAvailability.enabled,
    );
  }

  bool isPermissionGranted(QuickActionKind kind) =>
      permissions?.isGranted(kind) ?? false;

  /// The reason a denial carries: the caller's text when supplied, an
  /// explicit generic reason otherwise, and the fail-closed unknown reason
  /// when the permission source itself is missing.
  String? denialReasonFor(QuickActionKind kind) {
    final set = permissions;
    if (set == null) return unknownPermissionReason;
    if (!set.isGranted(kind)) {
      return set.reasonFor(kind) ?? unknownDenialReason;
    }
    return null;
  }

  /// Runs [kind].
  ///
  /// Preconditions are checked synchronously and a refusal throws
  /// [QuickActionStateError] before any state, result, or executor is
  /// touched, so a refused attempt is auditable and nothing else.
  Future<QuickActionResult> run(
    QuickActionKind kind, {
    bool confirmed = false,
    QuickActionProgressReporter? onProgress,
  }) {
    _requireDeclared(kind);
    if (_running.contains(kind)) {
      throw QuickActionStateError('${kind.wireName} is already running.');
    }
    if (!isPermissionGranted(kind)) {
      _deny(kind, denialReasonFor(kind) ?? unknownPermissionReason);
    }
    if (kind.isConsequential && !confirmed) {
      _deny(kind, '${kind.label} must be confirmed before it runs');
    }
    if (kind.isSensitive) {
      final broker = reauthenticate;
      // A missing broker cannot be treated as a successful reauthentication.
      if (broker == null || !broker()) {
        _deny(kind, 'Reauthentication is required for ${kind.label}');
      }
    }
    return _execute(kind, onProgress);
  }

  Future<QuickActionResult> _execute(
    QuickActionKind kind,
    QuickActionProgressReporter? onProgress,
  ) async {
    final startedAt = _now().toUtc();
    final state = QuickActionRunState(
      action: kind,
      phase: QuickActionPhase.running,
      startedAt: startedAt,
    );
    _states[kind] = state;
    _running.add(kind);

    void report(num fraction) {
      final step = QuickActionProgress(fraction: fraction);
      state.progress.add(step);
      onProgress?.call(step);
    }

    report(0);
    if (_cancelRequested.remove(kind)) {
      return _finish(
        kind,
        state,
        startedAt,
        QuickActionPhase.cancelled,
        '${kind.label} cancelled before it started',
      );
    }

    report(0.5);
    final executor = this.executor;
    if (executor == null) {
      return _finish(
        kind,
        state,
        startedAt,
        QuickActionPhase.failed,
        '${kind.label} has no executor; nothing was run',
      );
    }

    try {
      final message = await executor(kind);
      if (_cancelRequested.remove(kind)) {
        return _finish(
          kind,
          state,
          startedAt,
          QuickActionPhase.cancelled,
          '${kind.label} cancelled',
        );
      }
      // A finished run reports a complete bar. Leaving it at the last partial
      // value would show a spinner that never resolves.
      report(1);
      return _finish(
        kind,
        state,
        startedAt,
        QuickActionPhase.succeeded,
        _messageOrFallback(message, kind),
      );
    } on Object catch (error) {
      if (_cancelRequested.remove(kind)) {
        return _finish(
          kind,
          state,
          startedAt,
          QuickActionPhase.cancelled,
          '${kind.label} cancelled',
        );
      }
      return _finish(
        kind,
        state,
        startedAt,
        QuickActionPhase.failed,
        '${kind.label} failed: ${_describe(error)}',
      );
    }
  }

  QuickActionResult _finish(
    QuickActionKind kind,
    QuickActionRunState state,
    DateTime startedAt,
    QuickActionPhase phase,
    String message,
  ) {
    _running.remove(kind);
    state.phase = phase;
    final result = QuickActionResult(
      action: kind,
      phase: phase,
      message: message,
      startedAt: startedAt,
      completedAt: _now().toUtc(),
    );
    _results.add(result);
    _audit.add(
      QuickActionAuditEvent(
        action: kind,
        outcome: switch (phase) {
          QuickActionPhase.succeeded => QuickActionAuditOutcome.succeeded,
          QuickActionPhase.failed => QuickActionAuditOutcome.failed,
          QuickActionPhase.cancelled => QuickActionAuditOutcome.cancelled,
          QuickActionPhase.idle ||
          QuickActionPhase.running => QuickActionAuditOutcome.denied,
        },
        at: result.completedAt,
        // The reason is a failure diagnosis only. A successful run's message
        // is the executor's own output and never reaches the audit trail.
        reason: phase == QuickActionPhase.succeeded ? null : message,
      ),
    );
    return result;
  }

  Never _deny(QuickActionKind kind, String reason) {
    _audit.add(
      QuickActionAuditEvent(
        action: kind,
        outcome: QuickActionAuditOutcome.denied,
        at: _now().toUtc(),
        reason: reason,
      ),
    );
    throw QuickActionStateError('${kind.wireName} was refused: $reason');
  }

  QuickActionResolution _disabled(
    QuickActionKind kind, {
    required bool isGranted,
    required String reason,
  }) => QuickActionResolution(
    kind: kind,
    isGranted: isGranted,
    availability: QuickActionAvailability.disabled,
    disabledReason: reason,
  );

  void _requireDeclared(QuickActionKind kind) {
    if (!_actions.contains(kind)) {
      throw StateError('Undeclared quick action: ${kind.wireName}');
    }
  }

  String _messageOrFallback(String message, QuickActionKind kind) =>
      message.trim().isEmpty ? '${kind.label} finished' : message.trim();

  String _describe(Object error) {
    final text = error.toString().trim();
    return text.isEmpty ? error.runtimeType.toString() : text;
  }
}
