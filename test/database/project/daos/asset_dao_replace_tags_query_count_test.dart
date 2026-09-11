import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';

/// BUG-22 (hunt-run197) — AssetDao.replaceTags hoists the loop-invariant
/// `getById(assetId)` above the tag-insert loop: exactly one asset-row
/// resolution per call, not one SELECT per tag.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('replaceTags resolves the asset row once, not once per tag', () async {
    final root = await Directory.systemTemp.createTemp('bug22-replacetags-');
    addTearDown(() => root.delete(recursive: true));
    final dbPath = '${root.path}${Platform.pathSeparator}project.db';
    await ProjectDatabaseService().create(dbPath);

    final counts = <String, int>{'asset-select': 0};
    final database = ProjectDatabase(
      NativeDatabase(File(dbPath)).interceptWith(_CountingInterceptor(counts)),
    );
    await database.initialize();
    addTearDown(database.close);

    await database.assetDao.createStandaloneAsset(
      id: 'weapon',
      projectId: 'p',
      name: 'Void Sword',
      type: AssetType.weapon.name,
      now: DateTime.utc(2026, 3, 4),
    );

    counts['asset-select'] = 0;
    await database.assetDao.replaceTags('weapon', [
      'void',
      'combat',
      'legendary',
    ]);

    expect(
      counts['asset-select'],
      1,
      reason:
          'BUG-22: getById(assetId) must be hoisted out of the per-tag loop '
          '(one resolution per call, not one per tag)',
    );
    final tags = await database.assetDao.getTags('weapon');
    expect(tags.toSet(), {'void', 'combat', 'legendary'});
  });
}

class _CountingInterceptor extends QueryInterceptor {
  _CountingInterceptor(this._counts);

  final Map<String, int> _counts;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (statement.startsWith('SELECT * FROM "assets" WHERE')) {
      _counts['asset-select'] = _counts['asset-select']! + 1;
    }
    return super.runSelect(executor, statement, args);
  }
}
