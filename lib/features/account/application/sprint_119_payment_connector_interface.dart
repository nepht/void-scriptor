/// Local, fail-closed payment connector interface contract for roadmap step
/// 119.17.
///
/// This file defines opaque payment references, checkout and portal gating,
/// validated payment-method summaries, invoice listing, refund reachability,
/// region and currency availability, a closed error vocabulary, and
/// deterministic health.
///
/// Safety rules enforced here: no card number (pan), no cvc, no last-four
/// field, and no payment token secret is accepted, stored, or serialized.
/// Card-like values are refused outright rather than sanitized.
///
/// It does not create a checkout session, open a billing portal, fetch an
/// invoice, move money, or contact a payment provider.
library;

import 'dart:convert';
import 'dart:io';

/// Kind of payment instrument. Only opaque summaries are modelled.
enum PaymentMethodKind {
  card,
  bankTransfer,
  directDebit,
  wallet,
  invoice,
  unknown,
}

/// Lifecycle state of a checkout session.
enum CheckoutState { created, requiresAction, completed, cancelled, failed }

/// Status of an invoice.
enum InvoiceStatus { draft, open, paid, voided, uncollectible }

/// Deterministic availability of payment for a region and currency.
enum PaymentAvailabilityState {
  available,
  regionUnsupported,
  currencyUnsupported,
  providerUnavailable,
}

/// Closed payment error vocabulary. Provider text is never carried through.
enum PaymentErrorCode {
  none,
  invalidRequest,
  authenticationRequired,
  cardDeclined,
  insufficientFunds,
  rateLimited,
  providerUnavailable,
  unknown,
}

/// Deterministic health of a payment connection.
enum PaymentHealth { ok, degraded, unavailable }

/// Result of a gated payment operation.
enum PaymentOperationResult {
  ok,
  deniedUnknownCheckout,
  deniedUnknownInvoice,
  deniedInvalidState,
  deniedUnsupportedRegion,
  deniedUnsupportedCurrency,
  deniedProviderUnavailable,
  deniedAuthenticationRequired,
  deniedNotRefundable,
}

/// Opaque, non-secret payment reference.
///
/// A value containing a 12-or-more digit run (after removing separators) is
/// treated as card-like and refused, so a pan can never enter the model.
final class OpaqueRef {
  const OpaqueRef(this.value);

  static final RegExp _pattern = RegExp(
    r'^(?:payref|chkref|invref):[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}$',
  );

  static final RegExp _panLike = RegExp(r'\d{12,}');

  final String value;

  static bool looksLikePan(String candidate) =>
      _panLike.hasMatch(candidate.replaceAll(RegExp(r'[\s-]'), ''));

  static OpaqueRef? tryParse(String raw) {
    if (looksLikePan(raw)) return null;
    return _pattern.hasMatch(raw) ? OpaqueRef(raw) : null;
  }

  bool get isPaymentMethod => value.startsWith('payref:');
  bool get isCheckout => value.startsWith('chkref:');
  bool get isInvoice => value.startsWith('invref:');

  @override
  bool operator ==(Object other) => other is OpaqueRef && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '[REDACTED]';
}

/// An opaque payment-method summary.
///
/// Deliberately has no pan, no cvc, and no last-four field.
final class PaymentMethodSummary {
  const PaymentMethodSummary({
    required this.ref,
    required this.kind,
    required this.brand,
    required this.expiresAtUtc,
  });

  final OpaqueRef ref;
  final PaymentMethodKind kind;
  final String brand;
  final DateTime? expiresAtUtc;

  Map<String, Object?> toJson() => <String, Object?>{
    'method_ref': '[REDACTED]',
    'kind': kind.name,
    'brand': brand,
    'expires_at': expiresAtUtc?.toUtc().toIso8601String(),
  };
}

/// A checkout session under construction. Amounts are minor units only.
final class CheckoutSession {
  const CheckoutSession({
    required this.amountMinorUnits,
    required this.currency,
    required this.region,
    required this.state,
    this.ref,
  });

  final OpaqueRef? ref;
  final int amountMinorUnits;
  final String currency;
  final String region;
  final CheckoutState state;

  Map<String, Object?> toJson() => <String, Object?>{
    'checkout_ref': '[REDACTED]',
    'amount_minor_units': amountMinorUnits,
    'currency': currency,
    'region': region,
    'state': state.name,
  };
}

/// An invoice. Amounts are minor units only.
final class Invoice {
  const Invoice({
    required this.ref,
    required this.amountMinorUnits,
    required this.currency,
    required this.status,
    required this.paidAtUtc,
  });

  final OpaqueRef ref;
  final int amountMinorUnits;
  final String currency;
  final InvoiceStatus status;
  final DateTime? paidAtUtc;

  Map<String, Object?> toJson() => <String, Object?>{
    'invoice_ref': '[REDACTED]',
    'amount_minor_units': amountMinorUnits,
    'currency': currency,
    'status': status.name,
    'paid_at': paidAtUtc?.toUtc().toIso8601String(),
  };
}

/// Deterministic availability result for a region and currency.
final class PaymentAvailability {
  const PaymentAvailability({
    required this.state,
    required this.region,
    required this.currency,
  });

  final PaymentAvailabilityState state;
  final String region;
  final String currency;

  Map<String, Object?> toJson() => <String, Object?>{
    'state': state.name,
    'region': region,
    'currency': currency,
  };
}

/// Reachability of a refund, never an executed refund.
final class RefundPath {
  const RefundPath({
    required this.allowed,
    required this.windowDays,
    required this.requiresReason,
  });

  final bool allowed;
  final int windowDays;
  final bool requiresReason;

  Map<String, Object?> toJson() => <String, Object?>{
    'allowed': allowed,
    'window_days': windowDays,
    'requires_reason': requiresReason,
  };
}

/// A closed-vocabulary payment error. Provider text is never carried through.
final class PaymentError {
  const PaymentError({required this.code});

  final PaymentErrorCode code;

  bool get isRetryable => switch (code) {
    PaymentErrorCode.rateLimited ||
    PaymentErrorCode.providerUnavailable => true,
    _ => false,
  };

  String get userMessageKey => 'payment.error.${code.name}';

  Map<String, Object?> toJson() => <String, Object?>{
    'code': code.name,
    'retryable': isRetryable,
    'message_key': userMessageKey,
  };
}

/// Manifest validation and fail-closed helpers for the 119.17 contract.
abstract final class PaymentConnectorInterface {
  static const String canonicalStep = '119.17';
  static const String manifestPath =
      'docs/planning/v1.3/sprint_119_payment_connector_interface.json';

  static const List<String> requiredMethods = <String>[
    'checkout',
    'customer_portal',
    'payment_methods',
    'invoices',
    'refund_path',
    'availability',
    'health',
  ];

  static const List<String> requiredAcceptance = requiredMethods;

  /// Refund reachability window in days.
  static const int refundWindowDays = 30;

  /// A refund at or above this amount in minor units requires a recorded
  /// reason.
  static const int refundReasonThresholdMinorUnits = 10000;

  static final RegExp _opaqueReference = RegExp(
    r'\b(?:payref|chkref|invref|assetref|orgref|resref|modelref|storageref|jobref|credref):[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}',
  );

  static final RegExp _iso4217 = RegExp(r'^[A-Z]{3}$');

  /// Reports invalid payment-method summaries. An empty list means valid.
  static List<String> validatePaymentMethod(
    PaymentMethodSummary method, {
    required DateTime now,
  }) {
    final diagnostics = <String>[];
    if (method.kind == PaymentMethodKind.unknown) {
      diagnostics.add('method_kind_unknown');
    }
    if (method.brand.trim().isEmpty) {
      diagnostics.add('brand_missing');
    }
    if (OpaqueRef.looksLikePan(method.brand)) {
      diagnostics.add('raw_card_data_present');
    }
    final expiry = method.expiresAtUtc?.toUtc();
    if (expiry != null && !expiry.isAfter(now.toUtc())) {
      diagnostics.add('method_expired');
    }
    return diagnostics;
  }

  /// Validated payment-method summaries in deterministic reference order.
  static List<PaymentMethodSummary> listPaymentMethods(
    Iterable<PaymentMethodSummary> methods, {
    required DateTime now,
  }) {
    final valid = methods
        .where((method) => validatePaymentMethod(method, now: now).isEmpty)
        .toList();
    valid.sort((a, b) => a.ref.value.compareTo(b.ref.value));
    return List<PaymentMethodSummary>.unmodifiable(valid);
  }

  /// Checkout requires an explicit availability verdict, a supported region
  /// and currency, a reachable provider, and a newly created session.
  static PaymentOperationResult checkout({
    required CheckoutSession? session,
    required PaymentAvailability availability,
  }) {
    if (session == null) return PaymentOperationResult.deniedUnknownCheckout;
    switch (availability.state) {
      case PaymentAvailabilityState.providerUnavailable:
        return PaymentOperationResult.deniedProviderUnavailable;
      case PaymentAvailabilityState.regionUnsupported:
        return PaymentOperationResult.deniedUnsupportedRegion;
      case PaymentAvailabilityState.currencyUnsupported:
        return PaymentOperationResult.deniedUnsupportedCurrency;
      case PaymentAvailabilityState.available:
        break;
    }
    if (session.state != CheckoutState.created) {
      return PaymentOperationResult.deniedInvalidState;
    }
    return PaymentOperationResult.ok;
  }

  /// The billing portal fails closed without explicit reauthentication.
  static PaymentOperationResult customerPortal({
    required bool portalAvailable,
    required bool reauthenticated,
  }) {
    if (!reauthenticated) {
      return PaymentOperationResult.deniedAuthenticationRequired;
    }
    if (!portalAvailable) {
      return PaymentOperationResult.deniedProviderUnavailable;
    }
    return PaymentOperationResult.ok;
  }

  /// Invoices with [status] in deterministic reference order.
  static List<Invoice> invoices(
    Iterable<Invoice> invoices, {
    required InvoiceStatus status,
  }) {
    final matched = invoices
        .where((invoice) => invoice.status == status)
        .toList();
    matched.sort((a, b) => a.ref.value.compareTo(b.ref.value));
    return List<Invoice>.unmodifiable(matched);
  }

  /// Refund reachability: paid invoices only, inside the window, and a reason
  /// is required at or above the threshold.
  static RefundPath refundPath({
    required Invoice? invoice,
    required int daysSincePaid,
  }) {
    if (invoice == null || invoice.status != InvoiceStatus.paid) {
      return const RefundPath(
        allowed: false,
        windowDays: refundWindowDays,
        requiresReason: false,
      );
    }
    final inWindow = daysSincePaid >= 0 && daysSincePaid <= refundWindowDays;
    return RefundPath(
      allowed: inWindow,
      windowDays: refundWindowDays,
      requiresReason:
          inWindow &&
          invoice.amountMinorUnits >= refundReasonThresholdMinorUnits,
    );
  }

  /// Region and currency availability. Never guesses when a value is unknown.
  static PaymentAvailability availability({
    required String region,
    required String currency,
    required bool providerReachable,
  }) {
    if (!providerReachable) {
      return PaymentAvailability(
        state: PaymentAvailabilityState.providerUnavailable,
        region: region,
        currency: currency,
      );
    }
    if (region.trim().isEmpty) {
      return PaymentAvailability(
        state: PaymentAvailabilityState.regionUnsupported,
        region: region,
        currency: currency,
      );
    }
    if (!_iso4217.hasMatch(currency)) {
      return PaymentAvailability(
        state: PaymentAvailabilityState.currencyUnsupported,
        region: region,
        currency: currency,
      );
    }
    return PaymentAvailability(
      state: PaymentAvailabilityState.available,
      region: region,
      currency: currency,
    );
  }

  /// Maps a closed error code to a stable, non-leaking description.
  static PaymentError describeError(PaymentErrorCode code) =>
      PaymentError(code: code);

  /// Deterministic health from caller-supplied local signals.
  static PaymentHealth health({
    required bool providerReachable,
    required bool configured,
    required bool regionSupported,
  }) {
    if (!providerReachable) return PaymentHealth.unavailable;
    if (!configured || !regionSupported) return PaymentHealth.degraded;
    return PaymentHealth.ok;
  }

  /// Redacts opaque references from diagnostics.
  static String redact(String message) =>
      message.replaceAll(_opaqueReference, '[REDACTED]');

  static List<String> validateManifest(Map<String, dynamic> manifest) {
    final diagnostics = <String>[];
    if (manifest['canonical_step'] != canonicalStep) {
      diagnostics.add('canonical_step_invalid');
    }
    if (manifest['unknown_field_policy'] != 'REJECT') {
      diagnostics.add('unknown_field_policy_invalid');
    }

    final declared = manifest['required_methods'];
    final declaredSet = declared is List
        ? declared.whereType<String>().toSet()
        : <String>{};
    for (final method in requiredMethods) {
      if (!declaredSet.contains(method)) {
        diagnostics.add('method_missing:$method');
      }
    }

    final acceptance = manifest['acceptance'];
    if (acceptance is! Map<String, dynamic>) {
      for (final key in requiredAcceptance) {
        diagnostics.add('acceptance_missing:$key');
      }
      return diagnostics;
    }
    for (final key in requiredAcceptance) {
      if (!acceptance.containsKey(key)) {
        diagnostics.add('acceptance_missing:$key');
      }
    }
    return diagnostics;
  }

  static List<String> validateCanonicalManifest() {
    final file = File(manifestPath);
    if (!file.existsSync()) return <String>['manifest_missing'];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, dynamic>
          ? validateManifest(decoded)
          : <String>['manifest_root_invalid'];
    } on Object {
      return <String>['manifest_unreadable'];
    }
  }
}
