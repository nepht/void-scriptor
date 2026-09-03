import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/collaboration/application/sync_authority_store.dart';
import 'package:void_scriptor/features/collaboration/domain/sync_authority_policy.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('s14532-auth-');
  });

  tearDown(() async {
    try {
      root.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('store persists claimed authority across instances', () async {
    final store = SyncAuthorityStore(rootDirectory: root);
    await store.save('proj-a', SyncAuthority.cloud);

    final fresh = SyncAuthorityStore(rootDirectory: root);
    expect(await fresh.load('proj-a'), SyncAuthority.cloud);
  });

  test('store returns null for missing or corrupt file', () async {
    final store = SyncAuthorityStore(rootDirectory: root);
    expect(await store.load('proj-b'), isNull);

    final corrupt = File('${root.path}/sync_authority_proj-b.json');
    await corrupt.writeAsString('not json');
    expect(await store.load('proj-b'), isNull);
  });

  test('store rejects empty projectId and path separators', () async {
    final store = SyncAuthorityStore(rootDirectory: root);
    await expectLater(store.load(''), throwsArgumentError);
    await expectLater(
      store.save('  ', SyncAuthority.cloud),
      throwsArgumentError,
    );
    await expectLater(store.load('a/b'), throwsArgumentError);
  });

  test('store clear removes persisted authority', () async {
    final store = SyncAuthorityStore(rootDirectory: root);
    await store.save('proj-c', SyncAuthority.externalFolder);
    await store.clear('proj-c');
    expect(await store.load('proj-c'), isNull);
  });

  test('persisted authority denies concurrent owner after restore', () async {
    final store = SyncAuthorityStore(rootDirectory: root);
    final first = PersistedSyncAuthority(store: store);
    expect((await first.claim('proj-d', SyncAuthority.cloud)).allowed, isTrue);

    final second = PersistedSyncAuthority(store: store);
    await second.restore('proj-d');
    final decision = await second.claim('proj-d', SyncAuthority.externalFolder);
    expect(decision.allowed, isFalse);
    expect(decision.message, contains('cloud'));
    expect(decision.message, contains('external folder'));
  });

  test('release clears ownership and allows the other authority', () async {
    final store = SyncAuthorityStore(rootDirectory: root);
    final owner = PersistedSyncAuthority(store: store);
    await owner.claim('proj-e', SyncAuthority.cloud);
    await owner.release('proj-e');
    expect(await store.load('proj-e'), isNull);

    final next = PersistedSyncAuthority(store: store);
    expect(
      (await next.claim('proj-e', SyncAuthority.externalFolder)).allowed,
      isTrue,
    );
  });
}
