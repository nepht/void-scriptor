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
  const VaultAuditEvent({
    required this.action,
    required this.accountId,
    this.kind,
    this.secretId,
  });

  final String action;
  final String accountId;

  /// Storage name of the secret kind involved, when the action targets one.
  ///
  /// Without it every save and every revoke produced the byte-identical row
  /// `revoke|<accountId>` (measured), so an audit trail could not tell which of
  /// several keys under one account was destroyed, and `revert` (which never
  /// appears as an action) was impossible to tell apart from `revoke`.
  final String? kind;

  /// Which secret of that kind, when the action targeted a specific one.
  final String? secretId;

  /// Secret material is never carried on an audit row.
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

  /// Store key of the secret currently sitting in the clipboard, or `null`.
  ///
  /// The clipboard holds one value at a time, so a wipe has to know whose value
  /// it is destroying. Without this, cleaning up after one revoke would also
  /// discard an unrelated key the user had just copied — deleting a secret the
  /// caller never named. Recorded at copy time, cleared on every wipe.
  String? _clipboardOwnerKey;

  /// Whether the held clipboard copy belongs to [key].
  ///
  /// Returns `true` when nothing is held, so a caller can treat "nothing to
  /// clean" and "the thing to clean is here" the same way when it only needs
  /// the guarantee that no copy of this secret survives.
  bool clipboardHoldsSecretOf(String key) =>
      _clipboardExpiresAt != null && _clipboardOwnerKey == key;

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
    auditSink?.call(
      VaultAuditEvent(
        action: 'save',
        accountId: accountId,
        kind: kind.storageName,
        secretId: secretId,
      ),
    );
  }

  Future<String?> read({
    required String accountId,
    required VaultSecretKind kind,
    String? secretId,
  }) async {
    if (!await reauthenticate()) return null;
    final value = await store.read(keyFor(accountId, kind, secretId: secretId));
    auditSink?.call(
      VaultAuditEvent(
        action: 'read',
        accountId: accountId,
        kind: kind.storageName,
        secretId: secretId,
      ),
    );
    return value;
  }

  Future<void> revoke({
    required String accountId,
    required VaultSecretKind kind,
    String? secretId,
  }) async {
    final key = keyFor(accountId, kind, secretId: secretId);
    await store.delete(key);
    // Deleting the stored copy leaves any clipboard copy of that same secret as
    // the only remaining copy of material the caller just destroyed. This is the
    // same argument that makes `clearClipboard` a backstop stop rather than a
    // timeout, and callers in `payment_methods.remove` and
    // `sprint_117_provider_rollback_drill` invoke `vault.revoke` directly instead
    // of routing through `AccountCenterApiKeysManager`, so their clipboard copy
    // survived until the timeout expired on its own (measured: the clipboard
    // writer was never called at revoke time). Doing it here makes cleanup a
    // property of the vault rather than of one caller, and `onlyKey` keeps the
    // wipe from discarding an unrelated key the user just copied.
    await clearClipboard(onlyKey: key);
    auditSink?.call(
      VaultAuditEvent(
        action: 'revoke',
        accountId: accountId,
        kind: kind.storageName,
        secretId: secretId,
      ),
    );
  }

  Future<bool> copyToClipboard({
    required String accountId,
    required VaultSecretKind kind,
    String? secretId,
  }) async {
    final key = keyFor(accountId, kind, secretId: secretId);
    final value = await read(
      accountId: accountId,
      kind: kind,
      secretId: secretId,
    );
    if (value == null || clipboardWriter == null) return false;
    await clipboardWriter!(value);
    _clipboardExpiresAt = clock().add(clipboardTimeout);
    _clipboardOwnerKey = key;
    auditSink?.call(
      VaultAuditEvent(
        action: 'copy',
        accountId: accountId,
        kind: kind.storageName,
        secretId: secretId,
      ),
    );
    return true;
  }

  Future<int> clearExpiredClipboard() async {
    final expiresAt = _clipboardExpiresAt;
    if (expiresAt == null || clock().isBefore(expiresAt)) return 0;
    _clipboardExpiresAt = null;
    _clipboardOwnerKey = null;
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
  ///
  /// With [onlyKey] the wipe is restricted to a clipboard holding that one
  /// secret, so cleaning up after a revoke cannot discard an unrelated key the
  /// user copied a moment earlier. Returns whether anything was wiped.
  Future<bool> clearClipboard({String? onlyKey}) async {
    if (_clipboardExpiresAt == null) return false;
    if (onlyKey != null && _clipboardOwnerKey != onlyKey) return false;
    _clipboardExpiresAt = null;
    _clipboardOwnerKey = null;
    if (clipboardWriter != null) await clipboardWriter!('');
    return true;
  }

  String maskedDisplay(String secret) => secret.isEmpty ? '' : '••••••••••••';
}
