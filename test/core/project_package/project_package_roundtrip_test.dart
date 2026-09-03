import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_manifest.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/core/project_package/void_project_format.dart';

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('hermes-s102-roundtrip-');
  });

  tearDown(() async {
    if (await temp.exists()) {
      await temp.delete(recursive: true);
    }
  });

  test('schema-16 package reopens with the current database schema', () async {
    final package = await ProjectPackageService(
      rootDirectory: temp,
    ).create(name: 'Sprint 102 Roundtrip');

    final manifest = ProjectManifest.fromJson(
      jsonDecode(await package.manifestFile.readAsString())
          as Map<String, dynamic>,
    );
    expect(manifest.schemaVersion, VoidProjectFormat.currentSchema);
    expect(manifest.schemaVersion, 16);

    final first = await ProjectDatabaseService().open(
      package.databaseFile.path,
    );
    expect(first.schemaVersion, isNotNull);
    await first.close();

    final second = await ProjectDatabaseService().open(
      package.databaseFile.path,
    );
    addTearDown(second.close);
    expect(second.schemaVersion, 59);
    expect(second.schemaVersion, greaterThan(0));
  });
}
