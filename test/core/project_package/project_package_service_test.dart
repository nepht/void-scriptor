import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/core/persistence/project_manifest.dart';

void main() {
  late Directory temp;
  setUp(
    () => temp = Directory.systemTemp.createTempSync('hermes-s24-package-'),
  );
  tearDown(() => temp.delete(recursive: true));

  test('creates canonical package, manifest, and database', () async {
    final package = await ProjectPackageService(
      rootDirectory: temp,
    ).create(name: 'Void Universe');
    addTearDown(() => package.root.delete(recursive: true));
    expect(await package.manifestFile.exists(), isTrue);
    expect(await package.databaseFile.exists(), isTrue);
    expect(
      await Directory('${package.assetsDirectory.path}/audio').exists(),
      isTrue,
    );
    final manifest = ProjectManifest.fromJson(
      jsonDecode(await package.manifestFile.readAsString())
          as Map<String, dynamic>,
    );
    expect(manifest.schemaVersion, 16);
    expect(manifest.databaseFilename, 'database/project.db');
  });
}
