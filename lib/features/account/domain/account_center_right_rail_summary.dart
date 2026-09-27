/// Sprint 115.38 — Right-Rail Account Summary.
///
/// The persistent summary rail of the Account & Cloud Center: plan,
/// entitlements, credits, remote storage, seats, renewal, and the manage
/// actions that row exposes.
///
/// The product spec makes two rules non-negotiable and both are enforced
/// structurally here rather than by convention:
///
/// * `storage_and_credit_values_are_api_backed_or_explicitly_unavailable` —
///   a credit balance, a storage quota, and a seat count are wrapped in
///   availability types. Reading an unavailable value throws instead of
///   returning zero, so no surface can quietly render "0" for "unknown".
/// * `local_and_remote_storage_are_not_merged_without_labeling` — the rail
///   carries remote storage only, and every label it emits is prefixed with
///   [RightRailStorageLine.scopeLabel].
///
/// Manage actions are permission-aware. An unknown permission state is not a
/// granted permission, and a sensitive action (billing change, account
/// export, account deletion) refuses to run before reauthentication, matching
/// `security_contract.sensitive_actions` /
/// `reauth_before_sensitive_action`.
///
/// Live billing, signed-server entitlement checks, cloud provider quotas,
/// payment providers, public-trust signing, hosted CI, telemetry, hardware,
/// adoption, and publication stay `DEFERRED-EXTERNAL`; no reference mock
/// value can be produced by this contract.
library;

import 'dart:collection';

import 'account_center_localization_formatting.dart';

import 'package:void_scriptor/features/account/domain/account_center_ai_usage_credits_cost_view.dart'
    show ApplicationCreditBalance;
import 'package:void_scriptor/features/account/domain/account_center_cloud_storage_aggregation.dart'
    show CloudStorageAggregation, CloudStorageAggregationStatus;
import 'package:void_scriptor/features/account/domain/account_center_subscription_entitlement_model.dart';
import 'package:void_scriptor/features/account/domain/account_center_team_collaboration_summary.dart'
    show TeamSeatSummary;

/// Canonical right-rail sections, in the order the product spec lists them.
enum RightRailSectionKind { accountSummary, credits, quickActions }

/// Storage scope of a rail row. The rail is remote-only by construction:
/// local workspace storage is a separate, separately labelled surface.
enum RightRailStorageScope { remote }

/// Availability of a value the rail displays.
enum RightRailAvailability { available, unavailable }

/// Derived renewal state of the account.
enum RightRailRenewalState { renews, cancelsOn, cancelled, none, unknown }

/// Verdict of a manage action.
enum RightRailActionAvailability { enabled, disabled, reauthenticationRequired }

/// Manage actions the account rail can offer.
///
/// [viewInvoices] and [manageSeats] are not sensitive. [changeBilling],
/// [exportAccountData], and [deleteAccount] are listed in
/// `security_contract.sensitive_actions` and must reauthenticate first.
enum RightRailManageActionKind {
  viewInvoices,
  manageSeats,
  changeBilling,
  exportAccountData,
  deleteAccount,
}

extension RightRailManageActionKindWire on RightRailManageActionKind {
  String get wireName => switch (this) {
    RightRailManageActionKind.viewInvoices => 'view_invoices',
    RightRailManageActionKind.manageSeats => 'manage_seats',
    RightRailManageActionKind.changeBilling => 'change_billing',
    RightRailManageActionKind.exportAccountData => 'export_account_data',
    RightRailManageActionKind.deleteAccount => 'delete_account',
  };

  /// Actions named by `security_contract.sensitive_actions`.
  bool get isSensitive => switch (this) {
    RightRailManageActionKind.changeBilling ||
    RightRailManageActionKind.exportAccountData ||
    RightRailManageActionKind.deleteAccount => true,
    RightRailManageActionKind.viewInvoices ||
    RightRailManageActionKind.manageSeats => false,
  };
}

/// Plan row of the rail. Mirrors the subscription plan; never a substitute
/// for it.
final class RightRailPlanSummary {
  const RightRailPlanSummary({
    required this.planId,
    required this.displayName,
    required this.tier,
    required this.cycle,
    required this.priceLabel,
  });

  final String planId;
  final String displayName;
  final PlanTier tier;
  final PlanBillingCycle cycle;

  /// `Price unavailable` when the plan exposes no price — a free plan is
  /// not a zero-cost paid plan.
  final String priceLabel;
}

/// Entitlement tally evaluated at an instant.
final class RightRailEntitlementCounts {
  const RightRailEntitlementCounts({
    required this.granted,
    required this.denied,
    required this.expired,
  });

  final int granted;
  final int denied;
  final int expired;

  int get total => granted + denied + expired;

  String get label {
    if (total == 0) return 'No entitlements';
    final parts = <String>[
      if (granted > 0) '$granted granted',
      if (denied > 0) '$denied denied',
      if (expired > 0) '$expired expired',
    ];
    return parts.join(', ');
  }
}

/// Credit balance that cannot be read as zero when it is unknown.
final class RightRailCredits {
  const RightRailCredits({required this.remaining, required this.measuredAt});

  factory RightRailCredits.from(ApplicationCreditBalance balance) =>
      RightRailCredits(
        remaining: balance.remaining,
        measuredAt: balance.measuredAt,
      );

  final double? remaining;
  final DateTime? measuredAt;

  bool get isAvailable => remaining != null;

  /// Reading an unavailable balance is a programming error, not a zero.
  double get value {
    final available = remaining;
    if (available == null) {
      throw StateError(
        'Credit balance is unavailable; check isAvailable before reading.',
      );
    }
    return available;
  }

  double? get valueOrNull => remaining;
}

/// Seat count that cannot be read as zero when there is no team.
final class RightRailSeats {
  const RightRailSeats({required this.summary});

  final TeamSeatSummary? summary;

  bool get isAvailable => summary != null;

  TeamSeatSummary get value {
    final available = summary;
    if (available == null) {
      throw StateError('Seat count is unavailable; check isAvailable first.');
    }
    return available;
  }

  TeamSeatSummary? get valueOrNull => summary;
}

/// Remote storage row, always labelled as remote.
final class RightRailStorageLine {
  const RightRailStorageLine({
    required this.scope,
    required this.aggregationStatus,
    required this.usedBytes,
    required this.quotaBytes,
    required this.lastUpdated,
  });

  factory RightRailStorageLine.from(CloudStorageAggregation aggregation) =>
      RightRailStorageLine(
        scope: RightRailStorageScope.remote,
        aggregationStatus: aggregation.status,
        usedBytes: aggregation.usedBytes,
        quotaBytes: aggregation.quotaBytes,
        lastUpdated: aggregation.lastUpdated,
      );

  final RightRailStorageScope scope;
  final CloudStorageAggregationStatus aggregationStatus;
  final int? usedBytes;
  final int? quotaBytes;
  final DateTime? lastUpdated;

  String get scopeLabel =>
      scope == RightRailStorageScope.remote ? 'Remote cloud' : 'Local';

  bool get isAvailable => usedBytes != null && quotaBytes != null;

  String get usedLabel => usedBytes == null
      ? 'Used unavailable'
      : AccountCenterLocalizationFormatting.storageUnits(usedBytes!);

  String get quotaLabel => quotaBytes == null
      ? 'Quota unavailable'
      : AccountCenterLocalizationFormatting.storageUnits(quotaBytes!);

  String get freshnessLabel => switch (aggregationStatus) {
    CloudStorageAggregationStatus.complete => '',
    CloudStorageAggregationStatus.partial => 'partial',
    CloudStorageAggregationStatus.stale => 'stale',
    CloudStorageAggregationStatus.unavailable => 'unavailable',
  };

  String get label {
    if (!isAvailable) return summaryLabel;
    final freshness = freshnessLabel.isEmpty ? '' : ' ($freshnessLabel)';
    return '$scopeLabel$freshness — $usedLabel used of $quotaLabel';
  }

  String get summaryLabel => '$scopeLabel — unavailable';
}

/// Derived renewal row.
final class RightRailRenewal {
  const RightRailRenewal({
    required this.state,
    required this.renewsAt,
    required this.effectiveAt,
  });

  final RightRailRenewalState state;
  final DateTime? renewsAt;
  final DateTime? effectiveAt;

  String get label => switch (state) {
    RightRailRenewalState.renews =>
      'Renews ${AccountCenterLocalizationFormatting.utcDate(renewsAt!)}',
    RightRailRenewalState.cancelsOn =>
      'Cancels ${AccountCenterLocalizationFormatting.utcDate(effectiveAt!)}',
    RightRailRenewalState.cancelled => 'Subscription cancelled',
    RightRailRenewalState.none => 'No renewal',
    RightRailRenewalState.unknown => 'Renewal unknown',
  };
}

/// Permission state for the manage actions.
///
/// [unavailable] is the fail-closed default: a rail that cannot prove
/// permission disables every action instead of enabling it.
final class RightRailPermissionSnapshot {
  const RightRailPermissionSnapshot._(this.state, this.reason);

  const RightRailPermissionSnapshot.granted()
    : this._(RightRailAvailability.available, null);

  const RightRailPermissionSnapshot.denied(String reason)
    : this._(RightRailAvailability.unavailable, reason);

  const RightRailPermissionSnapshot.unavailable()
    : this._(RightRailAvailability.unavailable, 'Permission state unavailable');

  final RightRailAvailability state;
  final String? reason;

  bool get isGranted => state == RightRailAvailability.available;
}

/// A manage action declared by the rail.
final class RightRailManageAction {
  const RightRailManageAction({
    required this.kind,
    bool requiresReauthentication = false,
  }) : _declaredReauth = requiresReauthentication;

  final RightRailManageActionKind kind;

  /// Whether the caller demanded reauthentication. A sensitive action is
  /// gated regardless of what the caller declares.
  final bool _declaredReauth;

  bool get requiresReauthentication => _declaredReauth || kind.isSensitive;
}

/// Result of resolving or invoking a manage action.
final class RightRailActionResolution {
  const RightRailActionResolution({
    required this.kind,
    required this.availability,
    this.reason,
  });

  final RightRailManageActionKind kind;
  final RightRailActionAvailability availability;

  /// `null` only when the action is enabled.
  final String? reason;

  bool get isEnabled => availability == RightRailActionAvailability.enabled;
}

/// An audited invocation.
final class RightRailAuditEvent {
  const RightRailAuditEvent({required this.action, required this.at});

  final RightRailManageActionKind action;
  final DateTime at;
}

final class AccountCenterRightRailSummary {
  /// Product-spec `billing_contract.status`; this step never claims a live
  /// billing integration.
  static const String billingContractStatus = 'PLANNED_NOT_VERIFIED';

  /// `storage_usage_contract.reference_mock_values.production_use_allowed`.
  static const bool referenceMockValuesAllowed = false;

  static const canonicalAcceptance = <String>[
    'plan',
    'entitlements',
    'credits',
    'remote_storage',
    'seats',
    'renewal',
    'manage_actions',
  ];

  static const canonicalSprintPath =
      'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/sprint_115.json';
  static const canonicalSprintSha256 =
      'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba';

  /// Canonical section order from the product spec
  /// `information_architecture.right_summary_sections`, restricted to the
  /// sections this contract owns.
  static const sectionOrder = <RightRailSectionKind>[
    RightRailSectionKind.accountSummary,
    RightRailSectionKind.credits,
    RightRailSectionKind.quickActions,
  ];

  AccountCenterRightRailSummary({
    required this.subscription,
    required ApplicationCreditBalance credits,
    required CloudStorageAggregation storage,
    TeamSeatSummary? seats,
    this.permissions = const RightRailPermissionSnapshot.unavailable(),
    required Iterable<RightRailManageAction> actions,
    DateTime Function()? now,
  }) : credits = RightRailCredits.from(credits),
       remoteStorage = RightRailStorageLine.from(storage),
       seats = RightRailSeats(summary: seats),
       _now = now ?? _systemClock,
       _actions = List<RightRailManageAction>.of(actions) {
    _requireUniqueActionKinds(_actions);
  }

  static DateTime _systemClock() => DateTime.now().toUtc();

  final AccountCenterSubscriptionEntitlementModel subscription;
  final RightRailCredits credits;
  final RightRailStorageLine remoteStorage;
  final RightRailSeats seats;
  final RightRailPermissionSnapshot permissions;
  final DateTime Function() _now;
  final List<RightRailManageAction> _actions;
  final List<RightRailAuditEvent> _audit = <RightRailAuditEvent>[];

  static void _requireUniqueActionKinds(List<RightRailManageAction> actions) {
    final seen = <RightRailManageActionKind>{};
    for (final action in actions) {
      if (!seen.add(action.kind)) {
        throw ArgumentError.value(
          action.kind,
          'actions',
          'A manage action may be declared only once.',
        );
      }
    }
  }

  List<RightRailSectionKind> get sections => UnmodifiableListView(sectionOrder);

  List<RightRailManageAction> get manageActions =>
      UnmodifiableListView(_actions);

  List<RightRailAuditEvent> get audit => UnmodifiableListView(_audit);

  RightRailPlanSummary get plan {
    final source = subscription.plan;
    final price = source.price;
    return RightRailPlanSummary(
      planId: source.planId,
      displayName: source.displayName,
      tier: source.tier,
      cycle: source.cycle,
      priceLabel: price == null
          ? 'Price unavailable'
          : '${price.currency.toUpperCase()} ${price.amount.toStringAsFixed(2)}',
    );
  }

  List<String> get entitlementKeys => List<String>.unmodifiable(
    subscription.entitlements.map((grant) => grant.key),
  );

  /// Tally evaluated at [at]; expiry is derived, never stored twice.
  RightRailEntitlementCounts entitlementsAt(DateTime at) {
    _requireUtc(at, 'at');
    var granted = 0;
    var denied = 0;
    var expired = 0;
    for (final grant in subscription.entitlements) {
      switch (subscription.entitlementStateAt(grant.key, at)) {
        case EntitlementState.granted:
          granted++;
        case EntitlementState.denied:
          denied++;
        case EntitlementState.expired:
          expired++;
      }
    }
    return RightRailEntitlementCounts(
      granted: granted,
      denied: denied,
      expired: expired,
    );
  }

  String get creditsLabel {
    final remaining = credits.remaining;
    if (remaining == null) return 'Credits unavailable';
    final rendered = remaining == remaining.roundToDouble()
        ? remaining.toStringAsFixed(0)
        : remaining.toStringAsFixed(2);
    return '$rendered credits';
  }

  String get seatsLabel {
    final summary = seats.summary;
    if (summary == null) return 'Seats unavailable';
    return '${summary.assigned} of ${summary.total} seats used';
  }

  /// Derived from cancellation first: a scheduled cancellation outranks the
  /// renewal it replaces.
  RightRailRenewal get renewal {
    final cancellation = subscription.cancellation;
    if (cancellation.state == CancellationState.cancelled) {
      return RightRailRenewal(
        state: RightRailRenewalState.cancelled,
        renewsAt: null,
        effectiveAt: cancellation.effectiveAt,
      );
    }
    if (cancellation.state == CancellationState.scheduled) {
      return RightRailRenewal(
        state: RightRailRenewalState.cancelsOn,
        renewsAt: null,
        effectiveAt: cancellation.effectiveAt,
      );
    }
    final info = subscription.renewal;
    switch (info.mode) {
      case RenewalMode.auto:
      case RenewalMode.manual:
        if (info.renewsAt == null) {
          return const RightRailRenewal(
            state: RightRailRenewalState.unknown,
            renewsAt: null,
            effectiveAt: null,
          );
        }
        return RightRailRenewal(
          state: RightRailRenewalState.renews,
          renewsAt: info.renewsAt,
          effectiveAt: null,
        );
      case RenewalMode.none:
        return const RightRailRenewal(
          state: RightRailRenewalState.none,
          renewsAt: null,
          effectiveAt: null,
        );
      case RenewalMode.unknown:
        return const RightRailRenewal(
          state: RightRailRenewalState.unknown,
          renewsAt: null,
          effectiveAt: null,
        );
    }
  }

  String get renewalLabel => renewal.label;

  /// What the rail would do if the user pressed [kind] right now.
  ///
  /// Throws [StateError] for an action the rail does not declare — an
  /// undeclared action is a wiring defect, not a hidden permission.
  RightRailActionResolution resolveAction(
    RightRailManageActionKind kind, {
    bool reauthenticated = false,
  }) {
    final action = _declaredAction(kind);
    if (!permissions.isGranted) {
      return RightRailActionResolution(
        kind: kind,
        availability: RightRailActionAvailability.disabled,
        reason: permissions.reason ?? 'Permission state unavailable',
      );
    }
    if (action.requiresReauthentication && !reauthenticated) {
      return RightRailActionResolution(
        kind: kind,
        availability: RightRailActionAvailability.reauthenticationRequired,
      );
    }
    return RightRailActionResolution(
      kind: kind,
      availability: RightRailActionAvailability.enabled,
    );
  }

  /// Runs [kind] and records the audit event.
  ///
  /// Throws [StateError] when the action is disabled or still needs
  /// reauthentication, and records nothing in that case.
  RightRailActionResolution invokeAction(
    RightRailManageActionKind kind, {
    bool reauthenticated = false,
  }) {
    final resolution = resolveAction(kind, reauthenticated: reauthenticated);
    if (!resolution.isEnabled) {
      throw StateError(
        'Action ${kind.wireName} is not runnable: '
        '${resolution.availability.name}'
        '${resolution.reason == null ? '' : ' (${resolution.reason})'}',
      );
    }
    _audit.add(RightRailAuditEvent(action: kind, at: _now().toUtc()));
    return resolution;
  }

  RightRailManageAction _declaredAction(RightRailManageActionKind kind) {
    for (final action in _actions) {
      if (action.kind == kind) return action;
    }
    throw StateError('Undeclared manage action: ${kind.wireName}');
  }
}

void _requireUtc(DateTime value, String field) {
  if (!value.isUtc) {
    throw ArgumentError.value(value, field, 'Must be UTC.');
  }
}

// 115.49: date and byte formatting live in AccountCenterLocalizationFormatting
// (dates + storage_units evidence); this file no longer owns private formatters.
