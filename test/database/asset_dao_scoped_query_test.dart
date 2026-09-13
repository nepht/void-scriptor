// Kontrak DAO ter-scope: provider explorer tidak boleh menarik seluruh
// tabel assets lalu menyaring di sisi klien (hunt-run171 BUG-10 —
// "full-table fetch + client-side filter per family instance").
//
// Mekanisme yang dibuktikan test ini: listByProjectAndType harus membatasi
// SEBELINKAT di SQL (projectId + type), sehingga baris proyek lain, tipe
// lain, dan sampah lama tidak pernah meninggalkan database.

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/dashboard/data/dashboard_repository.dart';

void main() {
  late ProjectDatabase db;

  setUp(() {
    db = ProjectDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seed({
    required String id,
    required String projectId,
    required String type,
    required String name,
  }) async {
    final now = DateTime.utc(2026, 9, 10);
    await db
        .into(db.assets)
        .insert(
          AssetsCompanion.insert(
            id: id,
            projectId: projectId,
            name: name,
            type: type,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  test(
    'listByProjectAndType returns only matching project+type, name-sorted',
    () async {
      await seed(
        id: 'a1',
        projectId: 'p1',
        type: 'wardrobe',
        name: 'Zeta Coat',
      );
      await seed(
        id: 'a2',
        projectId: 'p1',
        type: 'wardrobe',
        name: 'alpha Cloak',
      );
      await seed(id: 'a3', projectId: 'p1', type: 'weapon', name: 'Bone Spear');
      await seed(
        id: 'a4',
        projectId: 'p2',
        type: 'wardrobe',
        name: 'Other Project Robe',
      );
      await seed(id: 'a5', projectId: 'p1', type: 'creature', name: 'Ash Moth');

      final rows = await db.assetDao.listByProjectAndType('p1', 'wardrobe');

      // Hanya p1+wardrobe; urut nama case-insensitive.
      expect(rows.map((r) => r.id), ['a2', 'a1']);
    },
  );

  test('empty result for a type with no rows in the project', () async {
    await seed(id: 'b1', projectId: 'p1', type: 'story', name: 'Chapter One');
    expect(await db.assetDao.listByProjectAndType('p1', 'armor'), isEmpty);
    expect(await db.assetDao.listByProjectAndType('p9', 'story'), isEmpty);
  });

  // vs-hunt-20260913-dashboard DB-BUG-01 (Referee REAL, Medium):
  // countByProject menghitung di sisi SQL, bukan full-table fetch.
  test('countByProject counts only the project rows, in SQL', () async {
    final root = await Directory.systemTemp.createTemp('dbbug01-count-');
    addTearDown(() => root.delete(recursive: true));
    final dbPath = '${root.path}${Platform.pathSeparator}project.db';
    await ProjectDatabaseService().create(dbPath);

    final fullTableFetches = <int>[];
    final database = ProjectDatabase(
      NativeDatabase(
        File(dbPath),
      ).interceptWith(_CountSelectInterceptor(fullTableFetches)),
    );
    await database.initialize();
    addTearDown(database.close);

    await database.assetDao.createStandaloneAsset(
      id: 'x1',
      projectId: 'p1',
      name: 'Void Coat',
      type: 'wardrobe',
      now: DateTime.utc(2026, 9, 13),
    );
    await database.assetDao.createStandaloneAsset(
      id: 'x2',
      projectId: 'p1',
      name: 'Bone Spear',
      type: 'weapon',
      now: DateTime.utc(2026, 9, 13),
    );
    await database.assetDao.createStandaloneAsset(
      id: 'x3',
      projectId: 'p2',
      name: 'Other Robe',
      type: 'wardrobe',
      now: DateTime.utc(2026, 9, 13),
    );

    fullTableFetches.clear();
    expect(await database.assetDao.countByProject('p1'), 2);
    expect(await database.assetDao.countByProject('p2'), 1);
    expect(await database.assetDao.countByProject('p9'), 0);

    // Kontrak utama: counting tidak boleh menarik tabel penuh sama sekali.
    expect(
      fullTableFetches,
      isEmpty,
      reason:
          'DB-BUG-01: countByProject harus COUNT di SQL; SELECT * FROM '
          '"assets" tanpa WHERE tidak boleh muncul (ditemukan '
          '${fullTableFetches.length} full-table fetch)',
    );
  });

  // Regression sisi konsumen: snapshot dashboard memakai count ter-scope
  // dan tetap menghasilkan angka yang benar untuk proyek aktif.
  test(
    'DashboardRepository snapshot reports project-scoped asset count',
    () async {
      await seed(id: 'd1', projectId: 'p1', type: 'wardrobe', name: 'Coat A');
      await seed(id: 'd2', projectId: 'p1', type: 'weapon', name: 'Spear B');
      await seed(id: 'd3', projectId: 'p2', type: 'wardrobe', name: 'Robe C');
      await seed(id: 'd4', projectId: 'p2', type: 'story', name: 'Tale D');
      await seed(id: 'd5', projectId: 'p2', type: 'story', name: 'Tale E');

      final snapshot = await const DashboardRepository().loadProjectSnapshot(
        db,
        'p1',
      );
      expect(
        snapshot.assets,
        2,
        reason: 'hanya aset milik p1 yang dihitung, bukan seluruh DB',
      );

      final other = await const DashboardRepository().loadProjectSnapshot(
        db,
        'p2',
      );
      expect(other.assets, 3);
    },
  );
}

class _CountSelectInterceptor extends QueryInterceptor {
  _CountSelectInterceptor(this._fullTableFetches);

  /// Mencatat posisi baris statement full-table SELECT (tanpa WHERE) yang
  /// dieksekusi terhadap tabel assets.
  final List<int> _fullTableFetches;

  int _seq = 0;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _seq++;
    final normalized = statement.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.startsWith('SELECT * FROM "assets"') &&
        !normalized.contains('WHERE')) {
      _fullTableFetches.add(_seq);
    }
    return super.runSelect(executor, statement, args);
  }
}
