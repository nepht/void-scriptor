import 'package:void_scriptor/core/security/credential_store.dart';

enum VaultSecretKind {
  apiKey('api_key'),
  oauthRefreshToken('oauth_refresh_token'),
  accessToken('access_token');

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

  String keyFor(String accountId, VaultSecretKind kind) {
    final normalized = accountId.trim();
    if (normalized.isEmpty || normalized.contains('/')) {
      throw ArgumentError.value(accountId, 'accountId');
    }
    return 'account/$normalized/${kind.storageName}';
  }

  Future<void> save({
    required String accountId,
    required String secret,
    required VaultSecretKind kind,
  }) async {
    if (secret.isEmpty) throw ArgumentError.value(secret, 'secret');
    await store.write(key: keyFor(accountId, kind), value: secret);
    auditSink?.call(VaultAuditEvent(action: 'save', accountId: accountId));
  }

  Future<String?> read({
    required String accountId,
    required VaultSecretKind kind,
  }) async {
    if (!await reauthenticate()) return null;
    final value = await store.read(keyFor(accountId, kind));
    auditSink?.call(VaultAuditEvent(action: 'read', accountId: accountId));
    return value;
  }

  Future<void> revoke({
    required String accountId,
    required VaultSecretKind kind,
  }) async {
    await store.delete(keyFor(accountId, kind));
    auditSink?.call(VaultAuditEvent(action: 'revoke', accountId: accountId));
  }

  Future<bool> copyToClipboard({
    required String accountId,
    required VaultSecretKind kind,
  }) async {
    final value = await read(accountId: accountId, kind: kind);
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

  String maskedDisplay(String secret) => secret.isEmpty ? '' : '••••••••••••';
}
