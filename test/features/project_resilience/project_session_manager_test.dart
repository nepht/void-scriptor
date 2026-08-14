import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';

void main() {
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('hermes-s24-session-');
  });
  tearDown(() => root.delete(recursive: true));

  test('open acquires lock and close releases it', () async {
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Session Project');
    final manager = ProjectSessionManager();

    final session = await manager.open(package);
    expect(session.mode, ProjectOpenMode.readWrite);
    expect(await package.lockFile.exists(), isTrue);

    await manager.close(session);
    expect(await package.lockFile.exists(), isFalse);
    expect(await package.sessionFile.exists(), isFalse);
  });

  test('read-only session does not mutate lock or save', () async {
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Read Only');
    final manager = ProjectSessionManager();

    final session = await manager.open(package, mode: ProjectOpenMode.readOnly);
    expect(session.mode, ProjectOpenMode.readOnly);
    expect(await package.lockFile.exists(), isFalse);

    await expectLater(session.save(), throwsA(isA<StateError>()));
    await manager.close(session);
  });
}
