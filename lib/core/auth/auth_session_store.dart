import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_session.dart';
import 'auth_status.dart';

/// JSON (de)serialization for [AuthSession].
///
/// Only the local session state is stored — never credentials. `email` and
/// `userId` are written as explicit JSON nulls so an accidental credential
/// leak would surface as a schema change.
extension AuthSessionJson on AuthSession {
  Map<String, dynamic> toJson() => <String, dynamic>{
    'status': status.name,
    'displayName': displayName,
    'userId': userId,
    'email': email,
  };

  static AuthSession fromMap(Map<String, dynamic> map) {
    final statusName = map['status'];
    if (statusName is! String) {
      throw const FormatException('missing session status');
    }
    final status = AuthStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () => throw const FormatException('unknown session status'),
    );
    return AuthSession(
      status: status,
      displayName: map['displayName'] as String?,
      userId: map['userId'] as String?,
      email: map['email'] as String?,
    );
  }
}

/// Persists the local auth session so Guest/Offline sessions survive restarts
/// without any account or network dependency (Sprint 145.20).
abstract interface class AuthSessionStore {
  Future<void> save(AuthSession session);

  Future<AuthSession?> load();

  Future<void> clear();
}

/// In-memory store: safe default for every target (web, widget tests) and
/// the fallback whenever the composition root has not installed a disk
/// store. `path_provider` must never be touched by this default — a pending
/// platform channel inside a widget test never completes and would hang
/// `pumpAndSettle` forever (verified 2026-08-31).
class InMemoryAuthSessionStore implements AuthSessionStore {
  AuthSession? _session;

  @override
  Future<void> save(AuthSession session) async {
    _session = session;
  }

  @override
  Future<AuthSession?> load() async => _session;

  @override
  Future<void> clear() async {
    _session = null;
  }
}

/// Default composition. Desktop/mobile install the disk-backed store at the
/// composition root (`main.dart`, via `createDiskAuthSessionStore`) with
/// `authSessionStoreProvider.overrideWithValue`; everything else keeps this
/// memory default.
final authSessionStoreProvider = Provider<AuthSessionStore>(
  (ref) => InMemoryAuthSessionStore(),
);
