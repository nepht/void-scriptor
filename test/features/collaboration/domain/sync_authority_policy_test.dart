import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/collaboration/domain/sync_authority_policy.dart';

void main() {
  test('rejects a second live sync authority with a visible warning', () {
    final policy = SingleSyncAuthorityPolicy();

    expect(policy.claim(SyncAuthority.cloud).allowed, isTrue);
    final decision = policy.claim(SyncAuthority.externalFolder);

    expect(decision.allowed, isFalse);
    expect(decision.authority, SyncAuthority.cloud);
    expect(decision.message, contains('cloud'));
    expect(decision.message, contains('external folder'));
  });
}
