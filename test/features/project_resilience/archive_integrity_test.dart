import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/portable_project_service.dart';

void main() {
  late Directory root;
  setUp(
    () async =>
        root = await Directory.systemTemp.createTemp('hermes-s33-archive-'),
  );
  tearDown(() => root.delete(recursive: true));

  test('export writes a real non-empty SHA-256 content checksum', () async {
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Integrity');
    await File(
      '${package.assetsDirectory.path}/images/hero.txt',
    ).writeAsString('asset-bytes');
    final archive = await PortableProjectExporter().exportPortable(package);
    expect(await archive.exists(), isTrue);

    final decoded = ZipDecoder().decodeBytes(
      await archive.readAsBytes(),
      verify: true,
    );
    final metaEntry = decoded.find('voidproject.archive.json')!;
    final meta =
        jsonDecode(utf8.decode(metaEntry.readBytes()!)) as Map<String, dynamic>;
    final declared = meta['checksum'] as String;
    expect(declared, isNotEmpty);
    expect(declared.length, 64);

    final computed = ArchiveIntegrity.computeContentChecksum(decoded);
    expect(computed, declared);
  });

  test('import rejects an archive whose content was tampered', () async {
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Integrity');
    final archive = await PortableProjectExporter().exportPortable(package);
    final decoded = ZipDecoder().decodeBytes(
      await archive.readAsBytes(),
      verify: true,
    );
    final db = decoded.find('database/project.db')!;
    final tampered = [...db.content]..[0] = 0x42;
    decoded.add(ArchiveFile.bytes(db.name, tampered));
    final outDir = await Directory(
      '${root.path}/tampered',
    ).create(recursive: true);
    final tamperedFile = File('${outDir.path}/tampered.voidproject');
    tamperedFile.writeAsBytesSync(ZipEncoder().encode(decoded));
    await expectLater(
      PortableProjectImporter().importArchive(
        tamperedFile,
        destination: Directory('${root.path}/out'),
      ),
      throwsA(anything),
    );
  });

  test('import rejects an archive without a checksum field', () async {
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Integrity');
    final archive = await PortableProjectExporter().exportPortable(package);
    final decoded = ZipDecoder().decodeBytes(
      await archive.readAsBytes(),
      verify: true,
    );
    final metaEntry = decoded.find('voidproject.archive.json')!;
    final meta =
        jsonDecode(utf8.decode(metaEntry.readBytes()!)) as Map<String, dynamic>;
    meta.remove('checksum');
    decoded.add(
      ArchiveFile.bytes(metaEntry.name, utf8.encode(jsonEncode(meta))),
    );
    final outDir = await Directory(
      '${root.path}/no-checksum',
    ).create(recursive: true);
    final legacyFile = File('${outDir.path}/legacy.voidproject');
    legacyFile.writeAsBytesSync(ZipEncoder().encode(decoded));
    await expectLater(
      PortableProjectImporter().importArchive(
        legacyFile,
        destination: Directory('${root.path}/out2'),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('a valid exported archive imports successfully', () async {
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Integrity');
    await File(
      '${package.assetsDirectory.path}/notes.txt',
    ).writeAsString('note');
    final archive = await PortableProjectExporter().exportPortable(package);
    final imported = await PortableProjectImporter().importArchive(
      archive,
      destination: root,
    );
    expect(
      await File('${imported.root.path}/assets/notes.txt').exists(),
      isTrue,
    );
  });
}
