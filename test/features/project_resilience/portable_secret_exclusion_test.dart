import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/archive_secret_policy.dart';
import 'package:void_scriptor/features/project_resilience/application/portable_project_service.dart';

void main() {
  late Directory root;
  setUp(
    () async =>
        root = await Directory.systemTemp.createTemp('hermes-s33-secret-'),
  );
  tearDown(() => root.delete(recursive: true));

  group('ArchiveSecretPolicy', () {
    test('flags credential file names, extensions, and folders', () {
      const secrets = [
        '.env',
        '.env.local',
        'assets/.env.production',
        'assets/credentials.json',
        'assets/secrets.json',
        'assets/keys/server.pem',
        'assets/keys/id_rsa',
        'assets/bundle.p12',
        'assets/bundle.pfx',
        'assets/.aws/credentials',
        'assets/.ssh/id_ed25519',
        'assets/vault.kdbx',
      ];
      for (final path in secrets) {
        expect(
          ArchiveSecretPolicy.isSecretPath(path),
          isTrue,
          reason: '$path must be treated as a secret',
        );
      }
    });

    test('keeps ordinary manuscript and example files', () {
      const safe = [
        '.env.example',
        'assets/images/hero.png',
        'assets/notes/env.txt',
        'assets/story/chapter-1.json',
        'assets/keys/readme.md',
        'manifest/project.json',
        'database/project.db',
      ];
      for (final path in safe) {
        expect(
          ArchiveSecretPolicy.isSecretPath(path),
          isFalse,
          reason: '$path must stay in the archive',
        );
      }
    });
  });

  test('export omits secret files from the portable archive', () async {
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Secrets');
    await File(
      '${package.assetsDirectory.path}/images/hero.txt',
    ).writeAsString('asset');
    await File(
      '${package.assetsDirectory.path}/.env',
    ).writeAsString('OPENAI_API_KEY=sk-test-1234567890');
    await File(
      '${package.assetsDirectory.path}/credentials.json',
    ).writeAsString('{"api_key":"sk-test-1234567890"}');
    final keysDir = Directory('${package.assetsDirectory.path}/keys')
      ..createSync(recursive: true);
    await File('${keysDir.path}/server.pem').writeAsString('PRIVATE KEY BLOCK');
    await File('${keysDir.path}/notes.txt').writeAsString('keep me');

    final archive = await PortableProjectExporter().exportPortable(package);
    final decoded = ZipDecoder().decodeBytes(
      await archive.readAsBytes(),
      verify: true,
    );
    final names = decoded
        .where((entry) => entry.isFile)
        .map((entry) => entry.name)
        .toList();
    expect(names, contains('assets/images/hero.txt'));
    expect(names, contains('assets/keys/notes.txt'));
    expect(names.any(ArchiveSecretPolicy.isSecretPath), isFalse);
    expect(
      utf8.decode(
        decoded
            .firstWhere((entry) => entry.name == 'assets/keys/notes.txt')
            .readBytes()!,
      ),
      'keep me',
    );
  });

  test('a secret-free export still imports cleanly', () async {
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Clean');
    await File(
      '${package.assetsDirectory.path}/notes.txt',
    ).writeAsString('note');
    await File(
      '${package.assetsDirectory.path}/.env',
    ).writeAsString('TOKEN=ghp_abcdefghijklmnopqrstuvwxyz123456');
    final archive = await PortableProjectExporter().exportPortable(package);
    final imported = await PortableProjectImporter().importArchive(
      archive,
      destination: Directory('${root.path}/out'),
      asCopy: true,
    );
    expect(
      await File('${imported.root.path}/assets/notes.txt').exists(),
      isTrue,
    );
    expect(await File('${imported.root.path}/assets/.env').exists(), isFalse);
  });

  test('import rejects an archive that carries a secret entry', () async {
    // Checksum-valid archive that still contains a credential file, so the
    // rejection proves the secret policy and not the integrity check.
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Hostile');
    final archive = await PortableProjectExporter().exportPortable(package);
    final decoded = ZipDecoder().decodeBytes(
      await archive.readAsBytes(),
      verify: true,
    );
    final payload = Archive();
    for (final entry in decoded) {
      if (!entry.isFile || entry.name == ArchiveIntegrity.manifestEntryName) {
        continue;
      }
      payload.addFile(ArchiveFile.bytes(entry.name, entry.readBytes()!));
    }
    payload.addFile(ArchiveFile.bytes('.env', utf8.encode('API_KEY=leaked')));
    final checksum = ArchiveIntegrity.computeContentChecksum(payload);
    payload.addFile(
      ArchiveFile.bytes(
        ArchiveIntegrity.manifestEntryName,
        utf8.encode(
          jsonEncode({
            'format': 'voidproject-archive',
            'version': 1,
            'projectId': package.projectId,
            'sourceSchemaVersion': 16,
            'checksum': checksum,
          }),
        ),
      ),
    );
    final hostile = File('${root.path}/hostile.voidproject')
      ..writeAsBytesSync(ZipEncoder().encode(payload));

    await expectLater(
      PortableProjectImporter().importArchive(
        hostile,
        destination: Directory('${root.path}/dest'),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('secret'),
        ),
      ),
    );
    expect(await Directory('${root.path}/dest').exists(), isFalse);
  });
}
