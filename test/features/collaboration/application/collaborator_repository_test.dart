import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/collaboration/domain/collaborator.dart';
import 'package:void_scriptor/features/collaboration/application/collaborator_repository.dart';

void main() {
  late ProjectDatabase db;
  late CollaboratorRepository repository;

  setUp(() {
    db = ProjectDatabase(NativeDatabase.memory());
    repository = CollaboratorRepository(db);
  });

  tearDown(() async => db.close());

  test('adds a collaborator with a role and lists them', () async {
    await repository.add(
      projectId: 'p1',
      userId: 'u1',
      role: CollaboratorRole.editor,
    );
    final collabs = await repository.forProject('p1');
    expect(collabs, hasLength(1));
    expect(collabs.single.userId, 'u1');
    expect(collabs.single.role, CollaboratorRole.editor);
  });

  test('acceptInvite sets acceptedAt', () async {
    await repository.add(
      projectId: 'p1',
      userId: 'u1',
      role: CollaboratorRole.viewer,
    );
    final before = (await repository.forProject('p1')).single;
    expect(before.acceptedAt, isNull);

    await repository.acceptInvite('p1', 'u1');
    final after = (await repository.forProject('p1')).single;
    expect(after.acceptedAt, isNotNull);
  });

  test('role permission helpers', () {
    expect(CollaboratorRole.owner.canEdit, isTrue);
    expect(CollaboratorRole.editor.canEdit, isTrue);
    expect(CollaboratorRole.viewer.canEdit, isFalse);
  });
}
