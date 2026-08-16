import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/collaboration/application/sync_log_repository.dart';

void main() {
  late ProjectDatabase db;
  late SyncLogRepository repository;

  setUp(() {
    db = ProjectDatabase(NativeDatabase.memory());
    repository = SyncLogRepository(db);
  });

  tearDown(() async => db.close());

  test('records and lists sync logs', () async {
    await repository.record(
      projectId: 'p1',
      kind: 'sync',
      status: 'synced',
      message: 'ok',
    );
    final logs = await repository.forProject('p1');
    expect(logs, hasLength(1));
    expect(logs.single.status, 'synced');
    expect(logs.single.message, 'ok');
  });

  test('schema version is 46', () {
    expect(ProjectDatabase.currentSchemaVersion, 46);
  });
}
