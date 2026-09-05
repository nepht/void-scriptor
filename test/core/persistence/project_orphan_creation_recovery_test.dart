import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_recovery_service.dart';
import 'package:void_scriptor/core/persistence/project_registry_service.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';

void main() {
  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('hermes-14542-orphan-');
  });

  tearDown(() async {
    try {
      await tempRoot.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  File markerOf(Directory packageRoot) => File(
    '${packageRoot.path}${Platform.pathSeparator}'
    '${ProjectRecoveryService.creationMarkerName}',
  );

  group('145.42 interrupted package-creation recovery', () {
    test(
      'process death before registry registration is admitted on next load',
      () async {
        final package = await ProjectPackageService(
          rootDirectory: tempRoot,
        ).create(name: 'Orphan Journey', description: 'crash window probe');

        // Production create() must stage an explicit creation marker before
        // the crash window opens; it is the only safe admission signal.
        expect(markerOf(package.root).existsSync(), isTrue);

        // Simulated process kill: the registry was never written.
        final registry = ProjectRegistryService(rootDirectory: tempRoot);
        final projects = await registry.load();

        expect(projects, hasLength(1));
        expect(projects.single.id, package.projectId);
        expect(projects.single.name, 'Orphan Journey');
        expect(projects.single.description, 'crash window probe');
        expect(projects.single.localPath, package.root.path);

        // Admission is durable: the marker is consumed only after the
        // registry write succeeded, and reloading never duplicates.
        expect(markerOf(package.root).existsSync(), isFalse);
        expect(await registry.load(), hasLength(1));
      },
    );

    test('a completed create leaves no duplicate admission', () async {
      final package = await ProjectPackageService(
        rootDirectory: tempRoot,
      ).create(name: 'Registered Project');

      final registry = ProjectRegistryService(rootDirectory: tempRoot);
      await registry.upsert(
        await registry.load().then((projects) => projects.first),
      );

      final projects = await registry.load();
      expect(projects, hasLength(1));
      expect(projects.single.id, package.projectId);
      expect(markerOf(package.root).existsSync(), isFalse);
    });

    test('packages without a valid marker are never admitted', () async {
      final foreign = Directory(
        '${tempRoot.path}${Platform.pathSeparator}unregistered.voidproject',
      );
      await foreign.create(recursive: true);

      final partial = Directory(
        '${tempRoot.path}${Platform.pathSeparator}partial.voidproject',
      );
      await partial.create(recursive: true);
      await File(
        '${partial.path}${Platform.pathSeparator}'
        '${ProjectRecoveryService.creationMarkerName}',
      ).writeAsString('not-json{');

      final future = Directory(
        '${tempRoot.path}${Platform.pathSeparator}future.voidproject',
      );
      await future.create(recursive: true);
      await File(
        '${future.path}${Platform.pathSeparator}'
        '${ProjectRecoveryService.creationMarkerName}',
      ).writeAsString(
        jsonEncode({
          'schemaVersion': 999999,
          'projectId': 'future-1',
          'name': 'From the future',
        }),
      );

      final projects = await ProjectRegistryService(
        rootDirectory: tempRoot,
      ).load();

      expect(projects, isEmpty);
      expect(foreign.existsSync(), isTrue);
      expect(partial.existsSync(), isTrue);
      expect(
        File(
          '${partial.path}${Platform.pathSeparator}'
          '${ProjectRecoveryService.creationMarkerName}',
        ).existsSync(),
        isTrue,
      );
      expect(future.existsSync(), isTrue);
    });
  });
}
