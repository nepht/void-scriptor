import 'dart:convert';
import 'dart:io';

final class IdentityLinkingContract {
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_identity_linking_collision.json';
  static const List<String> acceptance = <String>[
    'collision_detection',
    'safe_merge',
    'last_method_protection',
    'takeover_prevention',
    'unlink',
    'recovery',
  ];
}

final class IdentityCredential {
  const IdentityCredential(this.providerId, this.subject);

  final String providerId;
  final String subject;

  @override
  bool operator ==(Object other) =>
      other is IdentityCredential &&
      other.providerId == providerId &&
      other.subject == subject;

  @override
  int get hashCode => Object.hash(providerId, subject);
}

final class IdentityAccount {
  IdentityAccount({
    required this.accountId,
    required this.email,
    required Iterable<IdentityCredential> identities,
    required this.recoveryEmail,
  }) : identities = Set<IdentityCredential>.unmodifiable(identities);

  final String accountId;
  final String email;
  final Set<IdentityCredential> identities;
  final String? recoveryEmail;

  IdentityAccount copyWith({
    Iterable<IdentityCredential>? identities,
    String? recoveryEmail,
  }) => IdentityAccount(
    accountId: accountId,
    email: email,
    identities: identities ?? this.identities,
    recoveryEmail: recoveryEmail ?? this.recoveryEmail,
  );
}

class IdentityCollisionException implements Exception {
  const IdentityCollisionException(this.message);
  final String message;
}

class IdentityMergeConfirmationException implements Exception {
  const IdentityMergeConfirmationException();
}

class LastLoginMethodException implements Exception {
  const LastLoginMethodException();
}

class IdentityTakeoverException implements Exception {
  const IdentityTakeoverException();
}

final class IdentityLinkingService {
  IdentityLinkingService(Iterable<IdentityAccount> accounts) {
    for (final account in accounts) {
      if (_accounts.containsKey(account.accountId)) {
        throw ArgumentError.value(account.accountId, 'accountId');
      }
      _accounts[account.accountId] = account;
    }
  }

  final Map<String, IdentityAccount> _accounts = <String, IdentityAccount>{};

  List<IdentityAccount> get accounts =>
      List<IdentityAccount>.unmodifiable(_accounts.values);

  IdentityAccount? find(String accountId) => _accounts[accountId];

  IdentityAccount link({
    required String targetAccountId,
    required IdentityCredential candidate,
    required String candidateEmail,
    required bool confirmedSafeMerge,
  }) {
    final target = _require(targetAccountId);
    final owner = _ownerOf(candidate);
    if (owner != null && owner.accountId != target.accountId) {
      throw const IdentityTakeoverException();
    }
    final normalizedEmail = candidateEmail.trim().toLowerCase();
    final emailOwner = _accounts.values.where(
      (account) => account.email.trim().toLowerCase() == normalizedEmail,
    );
    if (emailOwner.isNotEmpty) {
      throw const IdentityCollisionException(
        'Email belongs to another account.',
      );
    }
    if (target.identities.contains(candidate)) {
      throw const IdentityCollisionException('Identity is already linked.');
    }
    if (!confirmedSafeMerge && owner != null) {
      throw const IdentityMergeConfirmationException();
    }
    final updated = target.copyWith(
      identities: <IdentityCredential>{...target.identities, candidate},
    );
    _accounts[target.accountId] = updated;
    return updated;
  }

  IdentityAccount merge({
    required String primaryAccountId,
    required String secondaryAccountId,
    required bool confirmedSafeMerge,
  }) {
    if (!confirmedSafeMerge) {
      throw const IdentityMergeConfirmationException();
    }
    final primary = _require(primaryAccountId);
    final secondary = _require(secondaryAccountId);
    if (primary.accountId == secondary.accountId) return primary;
    final overlap = primary.identities.intersection(secondary.identities);
    if (overlap.isNotEmpty) {
      throw const IdentityCollisionException(
        'Identity exists in both accounts.',
      );
    }
    final merged = primary.copyWith(
      identities: <IdentityCredential>{
        ...primary.identities,
        ...secondary.identities,
      },
    );
    _accounts[primary.accountId] = merged;
    _accounts.remove(secondary.accountId);
    return merged;
  }

  IdentityAccount recover({
    required String accountId,
    required String recoveryEmail,
  }) {
    final normalized = recoveryEmail.trim();
    if (!normalized.contains('@')) {
      throw ArgumentError.value(recoveryEmail, 'recoveryEmail');
    }
    final recovered = _require(accountId).copyWith(recoveryEmail: normalized);
    _accounts[accountId] = recovered;
    return recovered;
  }

  bool unlink({
    required String accountId,
    required IdentityCredential credential,
  }) {
    final account = _require(accountId);
    if (!account.identities.contains(credential)) {
      throw const IdentityCollisionException('Identity is not linked.');
    }
    if (account.identities.length <= 1 && account.recoveryEmail == null) {
      throw const LastLoginMethodException();
    }
    _accounts[accountId] = account.copyWith(
      identities: account.identities.where((item) => item != credential),
    );
    return true;
  }

  IdentityAccount _require(String accountId) {
    final account = _accounts[accountId];
    if (account == null) {
      throw StateError('Unknown account: $accountId');
    }
    return account;
  }

  IdentityAccount? _ownerOf(IdentityCredential credential) {
    for (final account in _accounts.values) {
      if (account.identities.contains(credential)) return account;
    }
    return null;
  }
}

void validateIdentityLinkingManifest() {
  final decoded = jsonDecode(
    File(IdentityLinkingContract.manifestPath).readAsStringSync(),
  );
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Manifest must be an object.');
  }
}
