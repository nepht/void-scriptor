import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/domain/project_model.dart';
import 'package:void_scriptor/core/persistence/project_manifest.dart';
import 'package:void_scriptor/core/persistence/project_registry_service.dart';
import 'package:void_scriptor/features/project_resilience/application/portable_project_service.dart';

/// Sprint 145.33 (Portable Import Export) - destination-collision rollback.
///
/// Data-loss path under repair: importing with `asCopy: false` into a
/// destination that already contains `<projectId>.voidproject` overwrote the
/// existing package file-by-file; any mid-extraction or registry failure left
/// the original destroyed. These tests pin the atomic-ish contract:
/// 1. failure during extraction -> original package restored on disk;
/// 2. registry failure after extraction -> original restored, import removed;
/// 3. full success -> destination replaced, collision backup discarded.
const String _fixedId = 'collision-fixed-1';

Map<String, dynamic> _manifestJson({required String name}) => <String, dynamic>{
  'schemaVersion': 16,
  'projectId': _fixedId,
  'name': name,
  'description': '',
  'projectVersion': '0.1.0',
  'createdAt': '2026-09-04T00:00:00.000Z',
  'updatedAt': '2026-09-04T00:00:00.000Z',
  'appVersion': '0.1.0',
  'tags': <String>[],
  'databaseFilename': 'database/project.db',
};

Archive _archive({required String incomingName, bool pathEscape = false}) {
  final archive = Archive()
    ..addFile(
      ArchiveFile.string(
        'manifest/project.json',
        jsonEncode(_manifestJson(name: incomingName)),
      ),
    )
    ..addFile(
      ArchiveFile.bytes('database/project.db', Uint8List.fromList([1, 2, 3])),
    );
  if (pathEscape) {
    archive.addFile(
      ArchiveFile.bytes('../../escape.txt', Uint8List.fromList([4, 5])),
    );
  }
  archive.addFile(
    ArchiveFile.bytes(
      'voidproject.archive.json',
      utf8.encode(
        jsonEncode(<String, dynamic>{
          'checksum': ArchiveIntegrity.computeContentChecksum(archive),
        }),
      ),
    ),
  );
  return archive;
}

Directory _seedSentinelDestination(Directory root) {
  final existing = Directory('${root.path}/$_fixedId.voidproject');
  File('${existing.path}/manifest/project.json')
    ..createSync(recursive: true)
    ..writeAsStringSync(jsonEncode(_manifestJson(name: 'Sentinel')));
  File('${existing.path}/database/project.db')
    ..createSync(recursive: true)
    ..writeAsBytesSync([9, 9, 9]);
  File(
    '${existing.path}/sentinel.txt',
  ).writeAsStringSync('ORIGINAL-DATA-DO-NOT-LOSE');
  return existing;
}

Future<void> _registerSentinel(Directory root) async {
  final registry = ProjectRegistryService(rootDirectory: root);
  final manifest = ProjectManifest.fromJson(
    jsonDecode(
          File(
            '${root.path}/$_fixedId.voidproject/manifest/project.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>,
  );
  await registry.upsert(
    ProjectModel(
      id: manifest.id,
      name: manifest.name,
      description: manifest.description,
      createdAt: manifest.createdAt,
      updatedAt: manifest.updatedAt,
      lastOpenedAt: manifest.updatedAt,
      localPath: '${root.path}/$_fixedId.voidproject',
      version: manifest.projectVersion,
      tags: manifest.tags,
    ),
  );
}

bool _sentinelIntact(Directory existing) =>
    File('${existing.path}/sentinel.txt').readAsStringSync() ==
    'ORIGINAL-DATA-DO-NOT-LOSE';

List<int> _zipOf(Archive archive) => ZipEncoder().encode(archive);

void main() {
  late Directory root;

  setUp(
    () async =>
        root = await Directory.systemTemp.createTemp('hermes-s33-collision-'),
  );
  tearDown(() => root.delete(recursive: true));

  Matcher noBackupLeft() => predicate<List<dynamic>>(
    (items) => items
        .whereType<Directory>()
        .where((d) => d.path.contains('.import-backup-'))
        .isEmpty,
    'no .import-backup-* directory remains',
  );

  test(
    'asCopy:false import failure during extraction restores the existing destination package',
    () async {
      final existing = _seedSentinelDestination(root);
      await _registerSentinel(root);
      final archive = File('${root.path}/broken.voidproject')
        ..writeAsBytesSync(
          _zipOf(_archive(incomingName: 'Incoming', pathEscape: true)),
        );

      await expectLater(
        PortableProjectImportCoordinator(
          registry: ProjectRegistryService(rootDirectory: root),
        ).importAndRegister(archive, destination: root, asCopy: false),
        throwsA(isA<FormatException>()),
      );

      expect(
        existing.existsSync(),
        isTrue,
        reason:
            'original destination must survive a failed asCopy:false import',
      );
      expect(_sentinelIntact(existing), isTrue);
      expect(
        jsonDecode(
              File('${existing.path}/manifest/project.json').readAsStringSync(),
            )
            as Map<String, dynamic>,
        containsPair('name', 'Sentinel'),
      );
      expect(root.listSync(), noBackupLeft());
      final projects = await ProjectRegistryService(rootDirectory: root).load();
      expect(projects.length, 1);
      expect(projects.single.name, 'Sentinel');
    },
  );

  test(
    'registry failure after asCopy:false extraction removes the import and restores the original',
    () async {
      final existing = _seedSentinelDestination(root);
      await _registerSentinel(root);
      final archive = File('${root.path}/good.voidproject')
        ..writeAsBytesSync(_zipOf(_archive(incomingName: 'Incoming')));

      await expectLater(
        PortableProjectImportCoordinator(
          registry: _FailingUpsertRegistry(
            ProjectRegistryService(rootDirectory: root),
          ),
        ).importAndRegister(archive, destination: root, asCopy: false),
        throwsA(isA<RegistryWriteFailure>()),
      );

      expect(existing.existsSync(), isTrue);
      expect(_sentinelIntact(existing), isTrue);
      expect(
        jsonDecode(
              File('${existing.path}/manifest/project.json').readAsStringSync(),
            )
            as Map<String, dynamic>,
        containsPair('name', 'Sentinel'),
      );
      expect(root.listSync(), noBackupLeft());
    },
  );

  test(
    'successful asCopy:false import replaces the destination and discards the collision backup',
    () async {
      final existing = _seedSentinelDestination(root);
      await _registerSentinel(root);
      final archive = File('${root.path}/good.voidproject')
        ..writeAsBytesSync(_zipOf(_archive(incomingName: 'Incoming')));

      expect(_sentinelIntact(existing), isTrue);
      final imported = await PortableProjectImportCoordinator(
        registry: ProjectRegistryService(rootDirectory: root),
      ).importAndRegister(archive, destination: root, asCopy: false);

      expect(imported.root.path, endsWith('$_fixedId.voidproject'));
      expect(
        jsonDecode(
              File(
                '${imported.root.path}/manifest/project.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>,
        containsPair('name', 'Incoming'),
      );
      expect(File('${imported.root.path}/sentinel.txt').existsSync(), isFalse);
      expect(root.listSync(), noBackupLeft());
      final projects = await ProjectRegistryService(rootDirectory: root).load();
      expect(projects.length, 1);
      expect(projects.single.id, _fixedId);
      expect(projects.single.name, 'Incoming');
    },
  );
}

class RegistryWriteFailure implements Exception {
  const RegistryWriteFailure();
}

class _FailingUpsertRegistry implements ProjectRegistryService {
  _FailingUpsertRegistry(this._inner);

  final ProjectRegistryService _inner;

  @override
  Future<List<ProjectModel>> load() => _inner.load();

  @override
  Future<void> upsert(ProjectModel project) async {
    throw const RegistryWriteFailure();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
