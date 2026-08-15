import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/collaboration/domain/presence.dart';
import 'package:void_scriptor/features/collaboration/application/presence_tracker.dart';
import 'package:void_scriptor/features/collaboration/application/activity_repository.dart';

void main() {
  group('PresenceTracker', () {
    test('sets and lists presence', () {
      final tracker = PresenceTracker();
      tracker.set('p1', 'u1', PresenceState.online);
      tracker.set('p1', 'u2', PresenceState.idle);
      expect(tracker.forProject('p1').length, 2);
      expect(
        tracker.forProject('p1').firstWhere((p) => p.userId == 'u1').state,
        PresenceState.online,
      );
    });

    test('removes a user when away', () {
      final tracker = PresenceTracker();
      tracker.set('p1', 'u1', PresenceState.online);
      tracker.set('p1', 'u1', PresenceState.offline);
      expect(
        tracker
            .forProject('p1')
            .where((p) => p.state != PresenceState.offline)
            .length,
        0,
      );
    });
  });

  group('ActivityRepository', () {
    late ProjectDatabase db;
    late ActivityRepository repository;

    setUp(() {
      db = ProjectDatabase(NativeDatabase.memory());
      repository = ActivityRepository(db);
    });

    tearDown(() async => db.close());

    test('records and lists activity events', () async {
      await repository.record(
        projectId: 'p1',
        actorId: 'u1',
        kind: 'character.created',
        payload: '{"id":"c1"}',
      );
      final events = await repository.forProject('p1');
      expect(events, hasLength(1));
      expect(events.single.kind, 'character.created');
    });
  });
}
