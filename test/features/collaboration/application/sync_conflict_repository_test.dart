import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/collaboration/application/sync_conflict_repository.dart';

void main() {
  late ProjectDatabase db;
  late SyncConflictRepository repository;

  setUp(() {
    db = ProjectDatabase(NativeDatabase.memory());
    repository = SyncConflictRepository(db);
  });

  tearDown(() async => db.close());

  test('stores and lists conflicts, then marks resolution', () async {
    await repository.record(
      projectId: 'p1',
      entityKey: 'character:1',
      baseJson: '{"name":"A"}',
      oursJson: '{"name":"Aria"}',
      theirsJson: '{"name":"Arin"}',
    );
    final conflicts = await repository.forProject('p1');
    expect(conflicts, hasLength(1));
    expect(conflicts.single.entityKey, 'character:1');

    await repository.markResolved(conflicts.single.id, 'keepOurs');
    final resolved = await repository.forProject('p1');
    expect(resolved.single.resolution, 'keepOurs');
  });
}
