import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/collaboration/application/comment_repository.dart';

void main() {
  late ProjectDatabase db;
  late CommentRepository repository;

  setUp(() {
    db = ProjectDatabase(NativeDatabase.memory());
    repository = CommentRepository(db);
  });

  tearDown(() async => db.close());

  test('adds and lists comments for a target', () async {
    await repository.add(
      projectId: 'p1',
      authorId: 'u1',
      targetType: 'character',
      targetId: 'c1',
      body: 'Nice design!',
    );
    final comments = await repository.forTarget('p1', 'character', 'c1');
    expect(comments, hasLength(1));
    expect(comments.single.body, 'Nice design!');
    expect(comments.single.authorId, 'u1');
  });

  test('comments are scoped by target', () async {
    await repository.add(
      projectId: 'p1',
      authorId: 'u1',
      targetType: 'character',
      targetId: 'c1',
      body: 'On c1',
    );
    await repository.add(
      projectId: 'p1',
      authorId: 'u1',
      targetType: 'character',
      targetId: 'c2',
      body: 'On c2',
    );
    expect((await repository.forTarget('p1', 'character', 'c1')).length, 1);
    expect((await repository.forTarget('p1', 'character', 'c2')).length, 1);
  });
}
