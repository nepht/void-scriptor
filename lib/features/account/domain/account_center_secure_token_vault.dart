import 'package:void_scriptor/core/security/credential_store.dart';

enum VaultSecretKind {
  apiKey('api_key'),
  oauthRefreshToken('oauth_refresh_token'),
  accessToken('access_token'),
  paymentMethodToken('payment_method');

  const VaultSecretKind(this.storageName);
  final String storageName;
}

class VaultAuditEvent {
  const VaultAuditEvent({required this.action, required this.accountId});

  final String action;
  final String accountId;
  String? get secret => null;
}

typedef VaultReauthentication = Future<bool> Function();
typedef VaultClipboardWriter = Future<void> Function(String value);
typedef VaultClock = DateTime Function();
typedef VaultAuditSink = void Function(VaultAuditEvent event);

class AccountSecureTokenVault {
  AccountSecureTokenVault({
    required this.store,
    required this.reauthenticate,
    this.clipboardWriter,
    this.clock = _systemClock,
    this.auditSink,
    this.clipboardTimeout = const Duration(seconds: 30),
  });

  final CredentialStore store;
  final VaultReauthentication reauthenticate;
  final VaultClipboardWriter? clipboardWriter;
  final VaultClock clock;
  final VaultAuditSink? auditSink;
  final Duration clipboardTimeout;
  DateTime? _clipboardExpiresAt;

  static DateTime _systemClock() => DateTime.now().toUtc();

  String keyFor(String accountId, VaultSecretKind kind, {String? secretId}) {
    final normalized = accountId.trim();
    if (normalized.isEmpty || normalized.contains('/')) {
      throw ArgumentError.value(accountId, 'accountId');
    }
    final normalizedSecretId = secretId?.trim();
    if (normalizedSecretId != null &&
        (normalizedSecretId.isEmpty || normalizedSecretId.contains('/'))) {
      throw ArgumentError.value(secretId, 'secretId');
    }
    final suffix = normalizedSecretId == null ? '' : '/$normalizedSecretId';
    return 'account/$normalized/${kind.storageName}$suffix';
  }

  Future<void> save({
    required String accountId,
    required String secret,
    required VaultSecretKind kind,
    String? secretId,
  }) async {
    if (secret.isEmpty) throw ArgumentError.value(secret, 'secret');
    await store.write(
      key: keyFor(accountId, kind, secretId: secretId),
      value: secret,
    );
    auditSink?.call(VaultAuditEvent(action: 'save', accountId: accountId));
  }

  Future<String?> read({
    required String accountId,
    required VaultSecretKind kind,
    String? secretId,
  }) async {
    if (!await reauthenticate()) return null;
    final value = await store.read(keyFor(accountId, kind, secretId: secretId));
    auditSink?.call(VaultAuditEvent(action: 'read', accountId: accountId));
    return value;
  }

  Future<void> revoke({
    required String accountId,
    required VaultSecretKind kind,
    String? secretId,
  }) async {
    await store.delete(keyFor(accountId, kind, secretId: secretId));
    auditSink?.call(VaultAuditEvent(action: 'revoke', accountId: accountId));
  }

  Future<bool> copyToClipboard({
    required String accountId,
    required VaultSecretKind kind,
    String? secretId,
  }) async {
    final value = await read(
      accountId: accountId,
      kind: kind,
      secretId: secretId,
    );
    if (value == null || clipboardWriter == null) return false;
    await clipboardWriter!(value);
    _clipboardExpiresAt = clock().add(clipboardTimeout);
    auditSink?.call(VaultAuditEvent(action: 'copy', accountId: accountId));
    return true;
  }

  Future<int> clearExpiredClipboard() async {
    final expiresAt = _clipboardExpiresAt;
    if (expiresAt == null || clock().isBefore(expiresAt)) return 0;
    _clipboardExpiresAt = null;
    if (clipboardWriter != null) await clipboardWriter!('');
    return 1;
  }

  /// Wipes a held clipboard immediately, ignoring the timeout.
  ///
  /// Revoking or replacing secret material must not leave a usable copy
  /// sitting in the clipboard for the remainder of its window: the store copy
  /// is already gone, so the clipboard copy is the only one left and it is
  /// exactly the copy the caller asked to stop trusting. The timeout is a
  /// backstop for the ordinary case, not the mechanism that ends a revoke.
  Future<bool> clearClipboard() async {
    if (_clipboardExpiresAt == null) return false;
    _clipboardExpiresAt = null;
    if (clipboardWriter != null) await clipboardWriter!('');
    return true;
  }

  String maskedDisplay(String secret) => secret.isEmpty ? '' : '••••••••••••';
}
