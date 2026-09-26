/// Sprint 115.36 — Payment Method Abstraction.
///
/// Local, provider-token-only payment method management. Raw card data
/// (PAN, CVC, expiry secrets) is rejected at the boundary, so the Account
/// Center never stores card data: only the provider-issued token and the
/// display metadata the provider returns for it live here. The token itself
/// is kept in the account secure vault and is only reachable through an
/// injected reauthentication callback (product spec
/// `security_contract.secrets.reauth_before_sensitive_action`).
///
/// Live payment-provider redirects, checkout sessions, PCI certification,
/// hosted CI, and public-trust signing stay `DEFERRED-EXTERNAL`; the
/// product-spec billing contract remains
/// [AccountCenterPaymentMethods.billingContractStatus].
library;

import 'dart:collection';

import 'package:void_scriptor/features/account/domain/account_center_secure_token_vault.dart';

/// Rejected input that looks like raw card data rather than a provider
/// token. Distinct from [ArgumentError] so the UI layer can distinguish
/// "this is card data and we refuse it" from "this field is malformed".
/// `dart:core`'s `ArgumentError` exposes no three-positional constructor,
/// so the rejected value is carried as a named field and the message/name
/// map onto the real super parameters.
final class PaymentMethodInputError extends ArgumentError {
  PaymentMethodInputError._(super.message, [super.name, this.offendingValue]);

  factory PaymentMethodInputError(Object? value, String name, String message) =>
      PaymentMethodInputError._(message, name, value);

  /// The rejected input, for diagnostics only. It is never logged or
  /// serialized, because by construction it may be card-shaped data.
  final Object? offendingValue;
}

/// Lifecycle of a stored payment method.
enum PaymentMethodStatus { active, removed }

/// Immutable input for creating a payment method.
///
/// The presence of [cardNumber] or [securityCode] is itself the error: a
/// provider-token abstraction must never be handed a PAN or a CVC. They
/// exist as named parameters only so the rejection is explicit and
/// testable rather than a silent omission.
final class PaymentMethodDraft {
  PaymentMethodDraft({
    required String id,
    required String providerId,
    required String providerToken,
    required String brand,
    required String last4,
    required this.expiryMonth,
    required this.expiryYear,
    this.cardholderName,
    this.regions = const <String>{},
    String? cardNumber,
    String? securityCode,
  }) : id = _required(id, 'id'),
       providerId = _required(providerId, 'providerId'),
       providerToken = _providerToken(providerToken),
       brand = _required(brand, 'brand'),
       last4 = _last4(last4) {
    if (cardNumber != null) {
      throw PaymentMethodInputError(
        cardNumber,
        'cardNumber',
        'Raw card numbers are never accepted; the provider token is the '
            'only instrument identifier this contract stores.',
      );
    }
    if (securityCode != null) {
      throw PaymentMethodInputError(
        securityCode,
        'securityCode',
        'Card security codes are never accepted or stored.',
      );
    }
    _expiry(expiryMonth, expiryYear);
  }

  /// Local opaque handle. This is deliberately NOT the provider token: the
  /// id travels through public serialization, the token does not.
  final String id;
  final String providerId;
  final String providerToken;
  final String brand;

  /// Exactly the last four characters the provider exposes for display.
  final String last4;
  final int expiryMonth;
  final int expiryYear;

  /// `null` means the provider returned no cardholder name — never a
  /// fabricated one.
  final String? cardholderName;

  /// Regions this instrument is confirmed for. Empty means "not declared",
  /// which is never treated as worldwide availability.
  final Set<String> regions;

  bool isAvailableIn(String regionCode) {
    final normalized = _required(regionCode, 'regionCode').toUpperCase();
    for (final region in regions) {
      if (region.toUpperCase() == normalized) return true;
    }
    return false;
  }
}

/// A managed payment method. The provider token is deliberately absent —
/// it lives in the vault and must be reauthenticated to retrieve.
final class ManagedPaymentMethod {
  ManagedPaymentMethod._({
    required this.id,
    required this.providerId,
    required String brand,
    required String last4,
    required int expiryMonth,
    required int expiryYear,
    required this.createdAt,
    this.cardholderName,
    Set<String> regions = const <String>{},
  }) : brand = _required(brand, 'brand'),
       last4 = _last4(last4),
       expiryMonth = expiryMonth,
       expiryYear = expiryYear,
       regions = UnmodifiableSetView(regions) {
    _expiry(expiryMonth, expiryYear);
  }

  final String id;
  final String providerId;
  final String? cardholderName;
  final Set<String> regions;
  final DateTime createdAt;

  // Mutable display metadata: rotating an instrument updates what the user
  // sees without minting a new identity.
  String brand;
  String last4;
  int expiryMonth;
  int expiryYear;

  /// `null` until the instrument is rotated through [AccountCenterPaymentMethods.replace].
  DateTime? replacedAt;

  bool isDefault = false;
  PaymentMethodStatus status = PaymentMethodStatus.active;

  /// Display string safe for any surface: brand plus masked digits only.
  String get maskedLabel => '$brand •••• $last4';

  bool isAvailableIn(String regionCode) {
    final normalized = _required(regionCode, 'regionCode').toUpperCase();
    for (final region in regions) {
      if (region.toUpperCase() == normalized) return true;
    }
    return false;
  }

  /// Public serialization: masked metadata only, never the token and never
  /// a full card reference.
  Map<String, Object?> toPublicJson() => <String, Object?>{
    'id': id,
    'provider_id': providerId,
    'brand': brand,
    'last4': last4,
    'expiry_month': expiryMonth,
    'expiry_year': expiryYear,
    'cardholder_name': cardholderName,
    'regions': regions.toList(growable: false)..sort(),
    'created_at': createdAt.toIso8601String(),
    'replaced_at': replacedAt?.toIso8601String(),
    'is_default': isDefault,
    'status': status.name,
    'masked_label': maskedLabel,
  };
}

/// Audit record. A payment audit event never carries an instrument
/// identifier, token, or card data.
final class PaymentMethodAuditEvent {
  const PaymentMethodAuditEvent({required this.action, required this.methodId});

  final String action;
  final String methodId;
  String? get providerToken => null;
}

typedef PaymentMethodClock = DateTime Function();
typedef PaymentMethodReauthentication = Future<bool> Function();

/// Account-scoped payment method manager.
///
/// Every sensitive mutation (`setDefault`, `replace`, `remove`, token
/// reveal) requires successful reauthentication first, and the default
/// invariant is exactly one default while methods exist.
final class AccountCenterPaymentMethods {
  /// Product-spec `billing_contract.status` — this step never claims a
  /// live, PCI-certified payment integration.
  static const String billingContractStatus = 'PLANNED_NOT_VERIFIED';

  AccountCenterPaymentMethods({
    required String accountId,
    required this.vault,
    PaymentMethodReauthentication? reauthenticate,
    this.clock = _systemClock,
  }) : accountId = _required(accountId, 'accountId'),
       _reauthenticate = reauthenticate ?? vault.reauthenticate;

  final String accountId;
  final AccountSecureTokenVault vault;
  final PaymentMethodReauthentication _reauthenticate;
  final PaymentMethodClock clock;
  final Map<String, ManagedPaymentMethod> _methods =
      <String, ManagedPaymentMethod>{};
  final List<PaymentMethodAuditEvent> _audit = <PaymentMethodAuditEvent>[];

  static DateTime _systemClock() => DateTime.now().toUtc();

  List<ManagedPaymentMethod> get methods =>
      UnmodifiableListView(_methods.values.toList(growable: false));

  List<PaymentMethodAuditEvent> get audit => UnmodifiableListView(_audit);

  String? get defaultMethodId {
    for (final method in _methods.values) {
      if (method.isDefault) return method.id;
    }
    return null;
  }

  ManagedPaymentMethod method(String id) {
    final found = _methods[_required(id, 'id')];
    if (found == null) throw StateError('Unknown payment method.');
    return found;
  }

  /// Adds a provider-tokenized method. The first method added becomes the
  /// default so a checkout always has an instrument without a second step.
  Future<ManagedPaymentMethod> add({
    required String id,
    required String providerId,
    required String providerToken,
    required String brand,
    required String last4,
    required int expiryMonth,
    required int expiryYear,
    String? cardholderName,
    Iterable<String> regions = const <String>[],
    String? cardNumber,
    String? securityCode,
  }) async {
    final draft = PaymentMethodDraft(
      id: id,
      providerId: providerId,
      providerToken: providerToken,
      brand: brand,
      last4: last4,
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      cardholderName: cardholderName,
      regions: _regions(regions),
      cardNumber: cardNumber,
      securityCode: securityCode,
    );
    if (_methods.containsKey(draft.id)) {
      throw StateError('Payment method already exists.');
    }

    final method = ManagedPaymentMethod._(
      id: draft.id,
      providerId: draft.providerId,
      brand: draft.brand,
      last4: draft.last4,
      expiryMonth: draft.expiryMonth,
      expiryYear: draft.expiryYear,
      createdAt: clock().toUtc(),
      cardholderName: draft.cardholderName,
      regions: draft.regions,
    );
    await vault.save(
      accountId: accountId,
      secret: draft.providerToken,
      kind: VaultSecretKind.paymentMethodToken,
      secretId: method.id,
    );
    _methods[method.id] = method;
    if (defaultMethodId == null) method.isDefault = true;
    _record('add', method.id);
    return method;
  }

  /// Rotates the stored provider token behind the SAME local method id, so
  /// references, default status, and region data survive an instrument
  /// replacement.
  Future<ManagedPaymentMethod> replace({
    required String id,
    required String providerToken,
    String? brand,
    String? last4,
    int? expiryMonth,
    int? expiryYear,
  }) async {
    final method = _active(id);
    if (!await _requireReauth('replace', method.id)) {
      throw StateError(
        'Reauthentication is required to replace a payment method.',
      );
    }
    final rotated = _providerToken(providerToken);
    if (rotated == method.id) {
      throw PaymentMethodInputError(
        providerToken,
        'providerToken',
        'The provider token must differ from the local method id.',
      );
    }
    method
      ..brand = brand ?? method.brand
      ..last4 = last4 ?? method.last4
      ..expiryMonth = expiryMonth ?? method.expiryMonth
      ..expiryYear = expiryYear ?? method.expiryYear
      ..replacedAt = clock().toUtc();

    await vault.save(
      accountId: accountId,
      secret: rotated,
      kind: VaultSecretKind.paymentMethodToken,
      secretId: method.id,
    );
    _record('replace', method.id);
    return method;
  }

  /// Promotes a method to default. Requires reauthentication.
  Future<void> setDefault(String id) async {
    final method = _active(id);
    if (!await _requireReauth('set_default', method.id)) {
      throw StateError(
        'Reauthentication is required to change the default method.',
      );
    }
    for (final other in _methods.values) {
      other.isDefault = false;
    }
    method.isDefault = true;
    _record('set_default', method.id);
  }

  /// Removes a method and revokes its vault token. Removing the default
  /// promotes another active method when one remains, otherwise the
  /// default is cleared. Requires reauthentication.
  Future<void> remove(String id) async {
    final method = _active(id);
    if (!await _requireReauth('remove', method.id)) {
      throw StateError(
        'Reauthentication is required to remove a payment method.',
      );
    }
    await vault.revoke(
      accountId: accountId,
      kind: VaultSecretKind.paymentMethodToken,
      secretId: method.id,
    );
    final wasDefault = method.isDefault;
    _methods.remove(method.id);
    method.status = PaymentMethodStatus.removed;
    if (wasDefault) {
      final promoted = _methods.values.firstOrNull;
      if (promoted != null) promoted.isDefault = true;
    }
    _record('remove', method.id);
  }

  /// Reauth-gated token retrieval for the payment provider. Returns `null`
  /// when reauthentication is refused; the token never appears in any
  /// display or serialization path.
  Future<String?> revealProviderToken(String id) async {
    final method = _active(id);
    if (!await _requireReauth('reveal_token', method.id)) return null;
    final token = await vault.read(
      accountId: accountId,
      kind: VaultSecretKind.paymentMethodToken,
      secretId: method.id,
    );
    _record('reveal_token', method.id);
    return token;
  }

  /// Fails closed when the method is not confirmed for [regionCode];
  /// a region the provider never declared is never assumed available.
  ManagedPaymentMethod requireAvailableForCheckout(
    String id,
    String regionCode,
  ) {
    final method = _active(id);
    if (!method.isAvailableIn(regionCode)) {
      throw StateError(
        'Payment method ${method.maskedLabel} is not available in $regionCode.',
      );
    }
    return method;
  }

  Map<String, Object?> toPublicJson() => <String, Object?>{
    'default_method_id': defaultMethodId,
    'methods': methods
        .map((method) => method.toPublicJson())
        .toList(growable: false),
  };

  ManagedPaymentMethod _active(String id) {
    final found = method(id);
    if (found.status != PaymentMethodStatus.active) {
      throw StateError('Payment method is removed.');
    }
    return found;
  }

  Future<bool> _requireReauth(String action, String methodId) async {
    final allowed = await _reauthenticate();
    if (!allowed) _record('denied_$action', methodId);
    return allowed;
  }

  void _record(String action, String id) {
    _audit.add(PaymentMethodAuditEvent(action: action, methodId: id));
  }
}

Set<String> _regions(Iterable<String> values) {
  final normalized = <String>{};
  for (final value in values) {
    normalized.add(_required(value, 'region').toUpperCase());
  }
  return normalized;
}

void _expiry(int month, int year) {
  if (month < 1 || month > 12) {
    throw ArgumentError.value(month, 'expiryMonth', 'Must be 1..12.');
  }
  if (year < 2000 || year > 2200) {
    throw ArgumentError.value(year, 'expiryYear', 'Out of range.');
  }
}

String _required(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized.contains('/')) {
    throw ArgumentError.value(value, field);
  }
  return normalized;
}

/// A provider token is an opaque handle (`pm_...`, `seti_...`, or the
/// provider's own scheme), never a card number. Anything that looks like a
/// 13-19 digit PAN, or that carries card-shaped whitespace/dashes, is
/// rejected before it can reach the vault.
String _providerToken(String value) {
  final token = _required(value, 'providerToken');
  if (RegExp(r'\d{12,}').hasMatch(token) || RegExp(r'[\s-]').hasMatch(token)) {
    throw PaymentMethodInputError(
      value,
      'providerToken',
      'Raw card data is not accepted; supply the provider-issued token.',
    );
  }
  return token;
}

String _last4(String value) {
  final normalized = value.trim();
  if (!RegExp(r'^\d{4}$').hasMatch(normalized)) {
    throw PaymentMethodInputError(
      value,
      'last4',
      'Exactly four display digits are required.',
    );
  }
  return normalized;
}
