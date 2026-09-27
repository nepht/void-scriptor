/// Sprint 115.34 — Subscription & Entitlement Model.
///
/// Local metadata-only separation of `plan`, `entitlements`, `limits`,
/// `renewal`, `cancellation`, `trial`, `grace_period`, and `license_state`.
/// Live billing, signed-server entitlement checks, payment-provider
/// redirects, and public-trust signing stay injected/external
/// (`DEFERRED-EXTERNAL`); the product-spec billing contract remains
/// `PLANNED_NOT_VERIFIED` and `entitlement_authority` is
/// `SIGNED_SERVER_OR_EXPLICIT_OFFLINE_LICENSE`.
library;

import 'dart:collection';

enum PlanTier { free, standard, premium, custom }

enum PlanBillingCycle { none, monthly, yearly }

/// State of an entitlement at an explicit instant.
///
/// [notYetIssued] exists because a grant is a signed statement with an
/// issuance time, not a boolean. Before this value existed the model compared
/// only `expiresAt`, so a grant signed for 1 October evaluated on 1 January
/// returned [granted] — a skewed clock, or a replayed evaluation time taken
/// from a cached entitlement, unlocked a feature the server had not issued
/// yet. [AccountCenterSubscriptionEntitlementModel.entitlementStateAt] now
/// applies both ends of the window.
enum EntitlementState { granted, denied, expired, notYetIssued }

enum EntitlementSource { signedServer, offlineLicense, trial, manualGrant }

enum RenewalMode { auto, manual, none, unknown }

enum CancellationState { none, scheduled, cancelled }

enum TrialPhase { none, active, expired }

enum GracePhase { none, active, expired }

enum OfflineLicenseState { unlicensed, active, expired, unknown }

enum LicenseAuthority { signedServer, offlineLicense }

final class PlanPrice {
  PlanPrice({required double amount, required String currency})
    : amount = _amount(amount),
      currency = _currency(currency);

  final double amount;

  /// Normalized ISO 4217 code.
  final String currency;
}

final class SubscriptionPlan {
  SubscriptionPlan({
    required String planId,
    required String displayName,
    required this.tier,
    required this.cycle,
    this.price,
  }) : planId = _required(planId, 'planId'),
       displayName = _required(displayName, 'displayName') {
    if (tier == PlanTier.free) {
      if (cycle != PlanBillingCycle.none) {
        throw ArgumentError('A free plan has no billing cycle.');
      }
      if (price != null) {
        throw ArgumentError('A free plan has no price.');
      }
    } else if (tier != PlanTier.custom && cycle == PlanBillingCycle.none) {
      throw ArgumentError('A paid plan requires a billing cycle.');
    }
  }

  final String planId;
  final String displayName;
  final PlanTier tier;
  final PlanBillingCycle cycle;

  /// `null` means pricing is explicitly unavailable — never a guess.
  final PlanPrice? price;
}

final class EntitlementGrant {
  EntitlementGrant({
    required String key,
    required this.state,
    required this.source,
    required this.grantedAt,
    this.expiresAt,
  }) : key = _required(key, 'key') {
    _requireUtc(grantedAt, 'grantedAt');
    if (expiresAt != null) {
      _requireUtc(expiresAt!, 'expiresAt');
      if (!expiresAt!.isAfter(grantedAt)) {
        throw ArgumentError.value(
          expiresAt,
          'expiresAt',
          'Must be after grantedAt.',
        );
      }
    }
    if (source == EntitlementSource.trial && expiresAt == null) {
      throw ArgumentError('A trial-sourced grant must declare expiresAt.');
    }
  }

  final String key;
  final EntitlementState state;
  final EntitlementSource source;
  final DateTime grantedAt;
  final DateTime? expiresAt;
}

final class EntitlementLimit {
  EntitlementLimit({required String key, required String unit, this.limit})
    : key = _required(key, 'key'),
      unit = _required(unit, 'unit') {
    if (limit != null && (!limit!.isFinite || limit! < 0)) {
      throw ArgumentError.value(limit, 'limit', 'Must be finite and >= 0.');
    }
  }

  final String key;
  final String unit;

  /// `null` means explicitly unavailable — never a fabricated zero.
  final double? limit;
}

final class RenewalInfo {
  RenewalInfo({required this.mode, this.renewsAt}) {
    if (renewsAt != null) {
      _requireUtc(renewsAt!, 'renewsAt');
    }
    if (mode == RenewalMode.auto && renewsAt == null) {
      throw ArgumentError('Auto renewal requires renewsAt.');
    }
    if ((mode == RenewalMode.none || mode == RenewalMode.unknown) &&
        renewsAt != null) {
      throw ArgumentError('Renewal mode ${mode.name} carries no renewsAt.');
    }
  }

  final RenewalMode mode;
  final DateTime? renewsAt;
}

final class CancellationInfo {
  CancellationInfo({
    required this.state,
    this.requestedAt,
    this.effectiveAt,
    String? reason,
  }) : reason = _optional(reason, 'reason') {
    if (requestedAt != null) {
      _requireUtc(requestedAt!, 'requestedAt');
    }
    if (effectiveAt != null) {
      _requireUtc(effectiveAt!, 'effectiveAt');
    }
    if (state == CancellationState.none) {
      if (requestedAt != null || effectiveAt != null) {
        throw ArgumentError('A none cancellation carries no timestamps.');
      }
      if (this.reason != null) {
        throw ArgumentError('A none cancellation carries no reason.');
      }
      return;
    }
    if (requestedAt == null || effectiveAt == null) {
      throw ArgumentError(
        'A ${state.name} cancellation requires requestedAt and effectiveAt.',
      );
    }
    if (effectiveAt!.isBefore(requestedAt!)) {
      throw ArgumentError.value(
        effectiveAt,
        'effectiveAt',
        'Must not precede requestedAt.',
      );
    }
  }

  final CancellationState state;
  final DateTime? requestedAt;
  final DateTime? effectiveAt;
  final String? reason;
}

final class TrialInfo {
  TrialInfo({this.startedAt, this.endsAt}) {
    _validateWindow(startedAt, endsAt, 'trial');
  }

  final DateTime? startedAt;
  final DateTime? endsAt;

  TrialPhase phaseAt(DateTime at) {
    _requireUtc(at, 'at');
    if (startedAt == null || endsAt == null) return TrialPhase.none;
    if (at.isBefore(startedAt!)) return TrialPhase.none;
    if (at.isBefore(endsAt!)) return TrialPhase.active;
    return TrialPhase.expired;
  }
}

final class GracePeriodInfo {
  GracePeriodInfo({this.startedAt, this.endsAt}) {
    _validateWindow(startedAt, endsAt, 'grace period');
  }

  final DateTime? startedAt;
  final DateTime? endsAt;

  GracePhase phaseAt(DateTime at) {
    _requireUtc(at, 'at');
    if (startedAt == null || endsAt == null) return GracePhase.none;
    if (at.isBefore(startedAt!)) return GracePhase.none;
    if (at.isBefore(endsAt!)) return GracePhase.active;
    return GracePhase.expired;
  }
}

final class OfflineLicenseInfo {
  OfflineLicenseInfo({
    required this.state,
    required this.authority,
    String? licensedTo,
    this.expiresAt,
    this.lastCheckedAt,
  }) : licensedTo = _optional(licensedTo, 'licensedTo') {
    if (expiresAt != null) {
      _requireUtc(expiresAt!, 'expiresAt');
    }
    if (lastCheckedAt != null) {
      _requireUtc(lastCheckedAt!, 'lastCheckedAt');
    }
    if (state == OfflineLicenseState.active ||
        state == OfflineLicenseState.expired) {
      if (this.licensedTo == null) {
        throw ArgumentError('A ${state.name} license requires licensedTo.');
      }
      if (expiresAt == null) {
        throw ArgumentError('A ${state.name} license requires expiresAt.');
      }
    }
    if (state == OfflineLicenseState.unlicensed &&
        (this.licensedTo != null || expiresAt != null)) {
      throw ArgumentError('An unlicensed state carries no licensee or expiry.');
    }
    if (state == OfflineLicenseState.active &&
        lastCheckedAt != null &&
        !expiresAt!.isAfter(lastCheckedAt!)) {
      throw ArgumentError.value(
        expiresAt,
        'expiresAt',
        'A license already past its expiry cannot report active.',
      );
    }
  }

  final OfflineLicenseState state;
  final LicenseAuthority authority;
  final String? licensedTo;
  final DateTime? expiresAt;
  final DateTime? lastCheckedAt;
}

final class AccountCenterSubscriptionEntitlementModel {
  AccountCenterSubscriptionEntitlementModel({
    required this.plan,
    required Iterable<EntitlementGrant> entitlements,
    required Iterable<EntitlementLimit> limits,
    required this.renewal,
    required this.cancellation,
    required this.trial,
    required this.gracePeriod,
    required this.license,
  }) : _entitlements = List<EntitlementGrant>.of(entitlements),
       _limits = List<EntitlementLimit>.of(limits) {
    _requireUnique(_entitlements.map((grant) => grant.key), 'entitlement.key');
    _requireUnique(_limits.map((limit) => limit.key), 'limit.key');
    final known = _entitlements.map((grant) => grant.key).toSet();
    for (final limit in _limits) {
      if (!known.contains(limit.key)) {
        throw ArgumentError.value(limit.key, 'limits', 'Unknown entitlement.');
      }
    }
  }

  final SubscriptionPlan plan;
  final RenewalInfo renewal;
  final CancellationInfo cancellation;
  final TrialInfo trial;
  final GracePeriodInfo gracePeriod;
  final OfflineLicenseInfo license;
  final List<EntitlementGrant> _entitlements;
  final List<EntitlementLimit> _limits;

  List<EntitlementGrant> get entitlements =>
      UnmodifiableListView(_entitlements);

  List<EntitlementLimit> get limits => UnmodifiableListView(_limits);

  EntitlementGrant entitlementByKey(String key) {
    final normalized = key.trim();
    for (final grant in _entitlements) {
      if (grant.key == normalized) return grant;
    }
    throw StateError('Unknown entitlement: $key');
  }

  EntitlementLimit limitByKey(String key) {
    final normalized = key.trim();
    for (final limit in _limits) {
      if (limit.key == normalized) return limit;
    }
    throw StateError('Unknown limit: $key');
  }

  /// Resolves the entitlement at [at], applying BOTH ends of its window.
  ///
  /// A grant is not live before `grantedAt`. This used to compare only
  /// `expiresAt`, so an evaluation time earlier than the grant's issuance
  /// silently reported [EntitlementState.granted]; a caller with a skewed
  /// clock, or one replaying a cached evaluation instant, could therefore
  /// unlock a feature the server had not issued. The window check is
  /// fail-closed on both ends.
  EntitlementState entitlementStateAt(String key, DateTime at) {
    _requireUtc(at, 'at');
    final grant = entitlementByKey(key);
    if (at.isBefore(grant.grantedAt)) {
      return EntitlementState.notYetIssued;
    }
    if (grant.state != EntitlementState.granted) return grant.state;
    final expiresAt = grant.expiresAt;
    if (expiresAt != null && !at.isBefore(expiresAt)) {
      return EntitlementState.expired;
    }
    return EntitlementState.granted;
  }

  bool hasEntitlement(String key, DateTime at) =>
      entitlementStateAt(key, at) == EntitlementState.granted;

  TrialPhase trialPhaseAt(DateTime at) => trial.phaseAt(at);

  GracePhase gracePhaseAt(DateTime at) => gracePeriod.phaseAt(at);

  AccountCenterSubscriptionEntitlementModel startTrial({
    required DateTime at,
    required DateTime endsAt,
  }) {
    _requireUtc(at, 'at');
    _requireUtc(endsAt, 'endsAt');
    if (!endsAt.isAfter(at)) {
      throw ArgumentError.value(endsAt, 'endsAt', 'Must be after at.');
    }
    final currentEndsAt = trial.endsAt;
    if (currentEndsAt != null && currentEndsAt.isAfter(at)) {
      throw ArgumentError('A trial is already running.');
    }
    return _copy(
      trial: TrialInfo(startedAt: at, endsAt: endsAt),
    );
  }

  AccountCenterSubscriptionEntitlementModel scheduleCancellation({
    required DateTime at,
    required DateTime effectiveAt,
    String? reason,
  }) {
    _requireUtc(at, 'at');
    _requireUtc(effectiveAt, 'effectiveAt');
    if (effectiveAt.isBefore(at)) {
      throw ArgumentError.value(
        effectiveAt,
        'effectiveAt',
        'Must not precede at.',
      );
    }
    if (cancellation.state != CancellationState.none) {
      throw ArgumentError('A cancellation is already recorded.');
    }
    if (renewal.mode != RenewalMode.auto &&
        renewal.mode != RenewalMode.manual) {
      throw ArgumentError(
        'Renewal mode ${renewal.mode.name} has nothing to cancel.',
      );
    }
    return _copy(
      cancellation: CancellationInfo(
        state: CancellationState.scheduled,
        requestedAt: at,
        effectiveAt: effectiveAt,
        reason: reason,
      ),
    );
  }

  AccountCenterSubscriptionEntitlementModel confirmCancellation({
    required DateTime at,
  }) {
    _requireUtc(at, 'at');
    if (cancellation.state == CancellationState.none) {
      throw ArgumentError('There is no cancellation to confirm.');
    }
    if (cancellation.state == CancellationState.cancelled) {
      throw ArgumentError('The cancellation is already effective.');
    }
    if (at.isBefore(cancellation.effectiveAt!)) {
      throw ArgumentError.value(
        at,
        'at',
        'The cancellation is not yet effective.',
      );
    }
    return _copy(
      cancellation: CancellationInfo(
        state: CancellationState.cancelled,
        requestedAt: cancellation.requestedAt,
        effectiveAt: cancellation.effectiveAt,
        reason: cancellation.reason,
      ),
    );
  }

  AccountCenterSubscriptionEntitlementModel enterGrace({
    required DateTime at,
    required DateTime endsAt,
  }) {
    _requireUtc(at, 'at');
    _requireUtc(endsAt, 'endsAt');
    if (!endsAt.isAfter(at)) {
      throw ArgumentError.value(endsAt, 'endsAt', 'Must be after at.');
    }
    final currentEndsAt = gracePeriod.endsAt;
    if (currentEndsAt != null && currentEndsAt.isAfter(at)) {
      throw ArgumentError('A grace period is already running.');
    }
    if (renewal.mode != RenewalMode.auto) {
      throw ArgumentError('A grace period applies to auto renewal only.');
    }
    if (cancellation.state != CancellationState.none) {
      throw ArgumentError(
        'A scheduled or completed cancellation cannot enter grace.',
      );
    }
    return _copy(
      gracePeriod: GracePeriodInfo(startedAt: at, endsAt: endsAt),
    );
  }

  AccountCenterSubscriptionEntitlementModel resolveGraceWithPayment({
    required DateTime at,
    required DateTime nextRenewalAt,
  }) {
    _requireUtc(at, 'at');
    _requireUtc(nextRenewalAt, 'nextRenewalAt');
    if (!nextRenewalAt.isAfter(at)) {
      throw ArgumentError.value(
        nextRenewalAt,
        'nextRenewalAt',
        'Must be after at.',
      );
    }
    if (gracePeriod.phaseAt(at) != GracePhase.active) {
      throw ArgumentError('No active grace period at the given time.');
    }
    if (renewal.mode != RenewalMode.auto) {
      throw ArgumentError('A grace period applies to auto renewal only.');
    }
    if (cancellation.state != CancellationState.none) {
      throw ArgumentError('A cancellation blocks renewal resolution.');
    }
    return _copy(
      gracePeriod: GracePeriodInfo(),
      renewal: RenewalInfo(mode: RenewalMode.auto, renewsAt: nextRenewalAt),
    );
  }

  AccountCenterSubscriptionEntitlementModel _copy({
    SubscriptionPlan? plan,
    List<EntitlementGrant>? entitlements,
    List<EntitlementLimit>? limits,
    RenewalInfo? renewal,
    CancellationInfo? cancellation,
    TrialInfo? trial,
    GracePeriodInfo? gracePeriod,
    OfflineLicenseInfo? license,
  }) => AccountCenterSubscriptionEntitlementModel(
    plan: plan ?? this.plan,
    entitlements: entitlements ?? _entitlements,
    limits: limits ?? _limits,
    renewal: renewal ?? this.renewal,
    cancellation: cancellation ?? this.cancellation,
    trial: trial ?? this.trial,
    gracePeriod: gracePeriod ?? this.gracePeriod,
    license: license ?? this.license,
  );
}

double _amount(double value) {
  if (!value.isFinite || value < 0) {
    throw ArgumentError.value(value, 'amount', 'Must be finite and >= 0.');
  }
  return value;
}

String _currency(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.length != 3 || normalized.contains(RegExp('[^a-z]'))) {
    throw ArgumentError.value(value, 'currency', 'ISO 4217 code required.');
  }
  return normalized;
}

void _validateWindow(DateTime? startedAt, DateTime? endsAt, String field) {
  if ((startedAt == null) != (endsAt == null)) {
    throw ArgumentError('$field requires both timestamps or neither.');
  }
  if (startedAt == null) return;
  _requireUtc(startedAt, '$field.startedAt');
  _requireUtc(endsAt!, '$field.endsAt');
  if (!endsAt.isAfter(startedAt)) {
    throw ArgumentError.value(endsAt, '$field.endsAt', 'Must be after start.');
  }
}

void _requireUtc(DateTime value, String field) {
  if (!value.isUtc) {
    throw ArgumentError.value(value, field, 'Must be UTC.');
  }
}

String _required(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError.value(value, field);
  return normalized;
}

String? _optional(String? value, String field) {
  if (value == null) return null;
  return _required(value, field);
}

void _requireUnique(Iterable<String> values, String field) {
  final seen = <String>{};
  for (final value in values) {
    if (!seen.add(value)) {
      throw ArgumentError.value(value, field, 'Must be unique.');
    }
  }
}
