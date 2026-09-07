import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/portable_project_service.dart';

/// Sprint 145.33 (Portable Import Export) - corrupted-input matrix.
///
/// PASS-first evidence slice: the importer already rejected every corrupted
/// shape probed live before this test existed. This file pins that behavior
/// with precise FormatException assertions so regressions fail loudly, and
/// adds a positive control proving the checksum harness itself is correct
/// (a valid archive with a computed checksum imports successfully).
Archive _base({required String manifestText}) {
  final archive = Archive()
    ..addFile(ArchiveFile.string('manifest/project.json', manifestText))
    ..addFile(
      ArchiveFile.bytes('database/project.db', Uint8List.fromList([1, 2, 3])),
    );
  return archive;
}

List<int> _zip(Archive archive, {String? checksum}) {
  if (checksum != null) {
    archive.addFile(
      ArchiveFile.bytes(
        'voidproject.archive.json',
        utf8.encode(jsonEncode(<String, dynamic>{'checksum': checksum})),
      ),
    );
  }
  return ZipEncoder().encode(archive);
}

const String _validManifest =
    '{"schemaVersion":16,"projectId":"corrupt-matrix-1","name":"CorruptMatrix",'
    '"description":"","projectVersion":"0.1.0",'
    '"createdAt":"2026-09-03T00:00:00.000Z",'
    '"updatedAt":"2026-09-03T00:00:00.000Z","appVersion":"0.1.0","tags":[],'
    '"databaseFilename":"database/project.db"}';

void main() {
  late Directory root;
  setUp(
    () async =>
        root = await Directory.systemTemp.createTemp('hermes-s33-corrupt-'),
  );
  tearDown(() => root.delete(recursive: true));

  test('import rejects an archive missing the manifest entry', () async {
    final archive = Archive()
      ..addFile(
        ArchiveFile.bytes('database/project.db', Uint8List.fromList([1])),
      );
    final file = File('${root.path}/missing-manifest.voidproject')
      ..writeAsBytesSync(_zip(archive));
    await expectLater(
      PortableProjectImporter().importArchive(
        file,
        destination: Directory('${root.path}/out-1'),
      ),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          'Invalid voidproject archive',
        ),
      ),
    );
  });

  test('import rejects an archive missing the database entry', () async {
    final archive = Archive()
      ..addFile(ArchiveFile.string('manifest/project.json', _validManifest));
    final file = File('${root.path}/missing-db.voidproject')
      ..writeAsBytesSync(_zip(archive));
    await expectLater(
      PortableProjectImporter().importArchive(
        file,
        destination: Directory('${root.path}/out-2'),
      ),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          'Invalid voidproject archive',
        ),
      ),
    );
  });

  test('import rejects a truncated zip container', () async {
    final archive = _base(manifestText: _validManifest);
    final bytes = _zip(
      archive,
      checksum: ArchiveIntegrity.computeContentChecksum(archive),
    );
    final truncated = bytes.sublist(0, bytes.length * 3 ~/ 5);
    final file = File('${root.path}/truncated.voidproject')
      ..writeAsBytesSync(truncated);
    await expectLater(
      PortableProjectImporter().importArchive(
        file,
        destination: Directory('${root.path}/out-3'),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('import rejects input that is not a zip container at all', () async {
    final file = File('${root.path}/not-a-zip.voidproject')
      ..writeAsBytesSync(utf8.encode('this is definitely not a zip archive'));
    await expectLater(
      PortableProjectImporter().importArchive(
        file,
        destination: Directory('${root.path}/out-4'),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'import rejects a malformed manifest whose checksum matches its content',
    () async {
      final archive = _base(manifestText: 'not-json{');
      final file = File('${root.path}/bad-manifest.voidproject')
        ..writeAsBytesSync(
          _zip(
            archive,
            checksum: ArchiveIntegrity.computeContentChecksum(archive),
          ),
        );
      await expectLater(
        PortableProjectImporter().importArchive(
          file,
          destination: Directory('${root.path}/out-5'),
        ),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test('import rejects a manifest from an unsupported future schema', () async {
    final futureManifest = _validManifest.replaceFirst(
      '"schemaVersion":16',
      '"schemaVersion":99',
    );
    final archive = _base(manifestText: futureManifest);
    final file = File('${root.path}/future-schema.voidproject')
      ..writeAsBytesSync(
        _zip(
          archive,
          checksum: ArchiveIntegrity.computeContentChecksum(archive),
        ),
      );
    await expectLater(
      PortableProjectImporter().importArchive(
        file,
        destination: Directory('${root.path}/out-6'),
      ),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          'Unsupported project manifest schema version: 99',
        ),
      ),
    );
  });

  test(
    'positive control: archive with valid computed checksum imports cleanly',
    () async {
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'CorruptMatrixControl');
      await File(
        '${package.assetsDirectory.path}/notes.txt',
      ).writeAsString('control');
      final archive = await PortableProjectExporter().exportPortable(package);
      final imported = await PortableProjectImporter().importArchive(
        archive,
        destination: root,
      );
      expect(
        await File('${imported.root.path}/assets/notes.txt').exists(),
        isTrue,
      );
    },
  );
}
