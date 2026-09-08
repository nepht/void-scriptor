import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/core/persistence/project_recovery_service.dart';

void main() {
  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('core-hunt-20260906-');
  });

  tearDown(() async {
    try {
      await tempRoot.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  Directory packageOf(String id) =>
      Directory('${tempRoot.path}${Platform.pathSeparator}$id.voidproject');

  File markerOf(Directory packageRoot) => File(
    '${packageRoot.path}${Platform.pathSeparator}'
    '${ProjectRecoveryService.creationMarkerName}',
  );

  group('core-hunt-20260906 corrupt creation-marker admission', () {
    test('a syntactically valid marker whose manifest is type-corrupt is '
        'skipped and never bricks the whole admission scan', () async {
      final package = packageOf('type-corrupt');
      await package.create(recursive: true);
      // Valid JSON, but ProjectManifest.fromJson casts fields unchecked:
      // projectId/name/createdAt type failures throw TypeError, not
      // FormatException. The admission catch must not let it escape.
      await markerOf(package).writeAsString(
        jsonEncode(<String, dynamic>{
          'projectId':
              <String>[], // wrong type -> TypeError, not FormatException
          'name': 42,
          'createdAt': 'not-a-date',
        }),
        flush: true,
      );

      final healthy = packageOf('healthy-sibling');
      await healthy.create(recursive: true);
      // BUG-6 contract: admission requires a complete package, so the
      // healthy sibling must carry an on-disk manifest and a real
      // database, not just a marker.
      await Directory(
        '${healthy.path}${Platform.pathSeparator}manifest',
      ).create();
      await File(
        '${healthy.path}${Platform.pathSeparator}manifest'
        '${Platform.pathSeparator}project.json',
      ).writeAsString(
        jsonEncode(<String, dynamic>{
          'projectId': 'healthy-sibling',
          'name': 'Healthy Sibling',
          'createdAt': '2026-09-06T00:00:00.000Z',
          'updatedAt': '2026-09-06T00:00:00.000Z',
        }),
        flush: true,
      );
      await ProjectDatabaseService().create(
        '${healthy.path}${Platform.pathSeparator}database'
        '${Platform.pathSeparator}project.db',
      );
      await markerOf(healthy).writeAsString(
        jsonEncode(<String, dynamic>{
          'projectId': 'healthy-sibling',
          'name': 'Healthy Sibling',
          'createdAt': '2026-09-06T00:00:00.000Z',
          'updatedAt': '2026-09-06T00:00:00.000Z',
        }),
        flush: true,
      );

      const recovery = ProjectRecoveryService();
      final admitted = await recovery.admitMarkedCreations(tempRoot, {});

      expect(admitted.map((project) => project.id), ['healthy-sibling']);
      // The corrupt marker stays on disk for manual inspection.
      expect(await markerOf(package).exists(), isTrue);
    });
  });
}
