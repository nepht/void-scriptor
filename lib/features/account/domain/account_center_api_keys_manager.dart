import 'dart:collection';

import 'package:void_scriptor/features/account/domain/account_center_secure_token_vault.dart';

enum ApiKeyStatus { active, revoked }

enum ApiKeyValidation { unverified, valid, invalid }

final class ApiKeyValidationRequest {
  const ApiKeyValidationRequest({
    required this.providerId,
    required this.secret,
    required this.scopes,
  });

  final String providerId;
  final String secret;
  final Set<String> scopes;
}

typedef ApiKeyValidator =
    Future<bool> Function(ApiKeyValidationRequest request);
typedef ApiKeyClock = DateTime Function();

final class ApiKeyAuditEvent {
  const ApiKeyAuditEvent({required this.action, required this.keyId});

  final String action;
  final String keyId;
  String? get secret => null;
}

final class ManagedApiKey {
  ManagedApiKey._({
    required this.id,
    required this.providerId,
    required this.label,
    required Set<String> scopes,
    required this.createdAt,
  }) : scopes = UnmodifiableSetView(scopes);

  final String id;
  final String providerId;
  final String label;
  final Set<String> scopes;
  final DateTime createdAt;
  DateTime? replacedAt;
  DateTime? validatedAt;
  DateTime? lastUsedAt;
  ApiKeyValidation validation = ApiKeyValidation.unverified;
  ApiKeyStatus status = ApiKeyStatus.active;

  String get maskedValue => '••••••••••••';

  Map<String, Object?> toPublicJson() => <String, Object?>{
    'id': id,
    'provider_id': providerId,
    'label': label,
    'scopes': scopes.toList(growable: false),
    'created_at': createdAt.toIso8601String(),
    'replaced_at': replacedAt?.toIso8601String(),
    'validated_at': validatedAt?.toIso8601String(),
    'last_used_at': lastUsedAt?.toIso8601String(),
    'validation': validation.name,
    'status': status.name,
    'masked_value': maskedValue,
  };
}

final class AccountCenterApiKeysManager {
  AccountCenterApiKeysManager({
    required String accountId,
    required this.vault,
    required this.validator,
    this.clock = _systemClock,
  }) : accountId = _required(accountId, 'accountId');

  final String accountId;
  final AccountSecureTokenVault vault;
  final ApiKeyValidator validator;
  final ApiKeyClock clock;
  final Map<String, ManagedApiKey> _keys = <String, ManagedApiKey>{};
  final List<ApiKeyAuditEvent> _audit = <ApiKeyAuditEvent>[];

  static DateTime _systemClock() => DateTime.now().toUtc();

  List<ManagedApiKey> get keys =>
      UnmodifiableListView(_keys.values.toList(growable: false));
  List<ApiKeyAuditEvent> get audit => UnmodifiableListView(_audit);

  Future<void> add({
    required String id,
    required String providerId,
    required String label,
    required String secret,
    required Set<String> scopes,
  }) async {
    final normalizedId = _required(id, 'id');
    if (_keys.containsKey(normalizedId)) {
      throw StateError('API key id already exists.');
    }
    final normalizedScopes = _scopes(scopes);
    final key = ManagedApiKey._(
      id: normalizedId,
      providerId: _required(providerId, 'providerId'),
      label: _required(label, 'label'),
      scopes: normalizedScopes,
      createdAt: clock().toUtc(),
    );
    await vault.save(
      accountId: accountId,
      secret: secret,
      kind: VaultSecretKind.apiKey,
      secretId: normalizedId,
    );
    _keys[normalizedId] = key;
    _record('add', normalizedId);
  }

  /// Rotates the secret behind an existing key.
  ///
  /// Requires reauthentication, because the product spec lists
  /// `reveal_or_replace_key` under `security_contract.sensitive_actions`.
  /// The vault's READ path already gated on reauthentication, so a user who
  /// could not reveal a key could still silently replace it — the audit
  /// recorded a `replace` and the previous material was gone. A refused
  /// reauthentication now leaves the stored secret untouched and is audited
  /// as `denied_replace` rather than `replace`.
  Future<void> replace({required String id, required String secret}) async {
    final key = _active(id);
    if (!await vault.reauthenticate()) {
      _record('denied_replace', key.id);
      throw StateError('Reauthentication is required to replace an API key.');
    }
    await vault.save(
      accountId: accountId,
      secret: secret,
      kind: VaultSecretKind.apiKey,
      secretId: key.id,
    );
    // Rotation invalidates the old material. A clipboard still holding it is a
    // live copy of a secret the user believes they just replaced, so it goes
    // with the rotation instead of surviving on the timeout.
    await vault.clearClipboard();
    key
      ..replacedAt = clock().toUtc()
      ..validation = ApiKeyValidation.unverified
      ..validatedAt = null;
    _record('replace', key.id);
  }

  Future<bool> validate(String id) {
    final key = _active(id);
    return _validate(key);
  }

  Future<bool> _validate(ManagedApiKey key) async {
    final secret = await vault.read(
      accountId: accountId,
      kind: VaultSecretKind.apiKey,
      secretId: key.id,
    );
    if (secret == null) {
      // A refused reauthentication is a decided answer — the key could not be
      // proven good — not an absence of one. Returning early here left the key
      // `unverified` with no timestamp and no audit row, so a key nobody could
      // ever validate looked identical to a key nobody had validated yet, and
      // the refusal itself left no trace.
      key
        ..validation = ApiKeyValidation.invalid
        ..validatedAt = clock().toUtc();
      _record('denied_validate', key.id);
      return false;
    }
    final valid = await validator(
      ApiKeyValidationRequest(
        providerId: key.providerId,
        secret: secret,
        scopes: key.scopes,
      ),
    );
    key
      ..validation = valid ? ApiKeyValidation.valid : ApiKeyValidation.invalid
      ..validatedAt = clock().toUtc();
    _record('validate', key.id);
    return valid;
  }

  void markUsed(String id) {
    final key = _active(id);
    key.lastUsedAt = clock().toUtc();
    _record('use', key.id);
  }

  Future<void> revoke(String id) async {
    final key = _active(id);
    await vault.revoke(
      accountId: accountId,
      kind: VaultSecretKind.apiKey,
      secretId: key.id,
    );
    // Deleting the stored copy leaves any clipboard copy as the only remaining
    // copy of a key the caller just destroyed. Wipe it here instead of leaving
    // it usable until the timeout expires on its own.
    await vault.clearClipboard();
    key.status = ApiKeyStatus.revoked;
    _record('revoke', key.id);
  }

  Future<bool> secureCopy(String id) async {
    final key = _active(id);
    final copied = await vault.copyToClipboard(
      accountId: accountId,
      kind: VaultSecretKind.apiKey,
      secretId: key.id,
    );
    // Copying is the one action that puts readable key material somewhere new,
    // so it is the one action whose absence from the trail hides a real
    // exfiltration. The vault audits its own copy; the managed key's trail did
    // not record one at all.
    _record(copied ? 'copy' : 'denied_copy', key.id);
    return copied;
  }

  Future<int> clearExpiredClipboard() => vault.clearExpiredClipboard();

  ManagedApiKey _active(String id) {
    final key = _keys[_required(id, 'id')];
    if (key == null) throw StateError('Unknown API key.');
    if (key.status != ApiKeyStatus.active) {
      throw StateError('API key is revoked.');
    }
    return key;
  }

  void _record(String action, String id) {
    _audit.add(ApiKeyAuditEvent(action: action, keyId: id));
  }
}

Set<String> _scopes(Set<String> values) {
  if (values.isEmpty) throw ArgumentError.value(values, 'scopes');
  final normalized = values.map((value) => _required(value, 'scope')).toSet();
  if (normalized.length != values.length) {
    throw ArgumentError.value(values, 'scopes');
  }
  return normalized;
}

String _required(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized.contains('/')) {
    throw ArgumentError.value(value, field);
  }
  return normalized;
}
