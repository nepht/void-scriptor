import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/project_resilience/application/portable_project_service.dart';

void main() {
  test(
    'rejects an archive entry with an absolute path and cleans partial output',
    () async {
      final root = await Directory.systemTemp.createTemp(
        's109-archive-security-',
      );
      addTearDown(() => root.delete(recursive: true));
      final archivePath = File('${root.path}/malicious.zip');
      final archive = Archive()
        ..addFile(
          ArchiveFile.string(
            'manifest/project.json',
            '{"schemaVersion":1,"id":"project-1","name":"Unsafe","description":"","projectVersion":"0.1.0","createdAt":"2026-08-22T00:00:00.000Z","updatedAt":"2026-08-22T00:00:00.000Z","appVersion":"0.1.0","tags":[],"databaseFilename":"project.db"}',
          ),
        )
        ..addFile(
          ArchiveFile('/absolute/escape.txt', 0, Uint8List.fromList([1, 2, 3])),
        );
      await archivePath.writeAsBytes(ZipEncoder().encode(archive));

      await expectLater(
        PortableProjectImporter().importArchive(
          archivePath,
          destination: Directory('${root.path}/destination'),
        ),
        throwsA(isA<Object>()),
      );
      expect(
        await Directory(
          '${root.path}/destination/project-1.voidproject',
        ).exists(),
        isFalse,
      );
    },
  );
}
