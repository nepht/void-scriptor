import '../domain/sync_authority_policy.dart';
import '../domain/sync_models.dart';
import 'cloud_sync_service.dart';
import 'sync_authority_store.dart';

/// Thrown when a sync write path is denied by the single sync authority rule
/// (Sprint 145.32). The message is user-readable and names both authorities.
class SyncAuthorityDeniedException implements Exception {
  const SyncAuthorityDeniedException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Runtime wiring of the single sync authority rule (Sprint 145.32):
/// decorates a [CloudSyncService] and gates every mutation (`push`, `sync`)
/// through a [PersistedSyncAuthority] claim so cloud and external folder
/// cannot concurrently own one live project. Denied writes never reach the
/// delegate: `push` throws [SyncAuthorityDeniedException] and `sync`
/// surfaces [SyncState.error] with a user-readable warning. `pull` stays
/// read-only so project state remains inspectable while ownership is denied.
class AuthorityGuardedCloudSyncService implements CloudSyncService {
  AuthorityGuardedCloudSyncService({
    required this.delegate,
    required this.authority,
    required this.kind,
  });

  final CloudSyncService delegate;
  final PersistedSyncAuthority authority;
  final SyncAuthority kind;

  @override
  Future<Map<String, Object?>> pull(String projectId) =>
      delegate.pull(projectId);

  @override
  Future<void> push({
    required String projectId,
    required Map<String, Object?> state,
  }) async {
    final decision = await authority.claim(projectId, kind);
    if (!decision.allowed) {
      throw SyncAuthorityDeniedException(decision.message);
    }
    await delegate.push(projectId: projectId, state: state);
  }

  @override
  Future<SyncResult> sync({
    required String projectId,
    required Map<String, Object?> local,
  }) async {
    final decision = await authority.claim(projectId, kind);
    if (!decision.allowed) {
      return SyncResult(
        state: SyncState.error,
        applied: 0,
        total: local.length,
        message: decision.message,
      );
    }
    return delegate.sync(projectId: projectId, local: local);
  }
}
