// Kontrak DAO ter-scope: provider explorer tidak boleh menarik seluruh
// tabel assets lalu menyaring di sisi klien (hunt-run171 BUG-10 —
// "full-table fetch + client-side filter per family instance").
//
// Mekanisme yang dibuktikan test ini: listByProjectAndType harus membatasi
// SEBELINKAT di SQL (projectId + type), sehingga baris proyek lain, tipe
// lain, dan sampah lama tidak pernah meninggalkan database.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';

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
}
