import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/domain/project_model.dart';
import 'package:void_scriptor/core/persistence/project_recovery_service.dart';
import 'package:void_scriptor/core/persistence/project_registry_service.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';

/// Bug-hunt run94 BUG-02 + BUG-05 (Referee REAL BUG, Medium) - 145.42
/// registry durability layer.
///
/// Registry read-modify-write (load/upsert/remove) dan atomicWrite yang
/// dituju tidak punya serialisasi: dua operasi yang tumpang-tindih di
/// titik await menghasilkan (a) spurious FileSystemException saat penulis
/// kedua kehilangan .tmp bersama, dan (b) lost update / lost admission
/// karena save terakhir menimpa isi penulis lain. Kontrak slice ini:
/// 1. upsert paralel       -> SEMUA entri durable, tidak ada yang hilang;
/// 2. atomicWrite paralel  -> tanpa exception, target akhir persis salah
///    satu payload utuh (tidak ada konten campuran/truncated);
/// 3. admission crash-window vs upsert bersamaan -> keduanya masuk
///    registry (proyek lengkap tidak boleh jadi tak terlihat).
ProjectModel _model(String id, String name, Directory root) => ProjectModel(
  id: id,
  name: name,
  description: '',
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 2),
  lastOpenedAt: DateTime.utc(2026, 1, 2),
  localPath: root.path,
  version: '0.1.0',
);

void main() {
  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('hermes-bug0205-');
  });

  tearDown(() async {
    try {
      await tempRoot.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  test('concurrent upserts keep every registration durable', () async {
    final service = ProjectRegistryService(rootDirectory: tempRoot);
    final projects = List.generate(
      3,
      (i) => _model('concurrent-$i', 'C$i', tempRoot),
    );

    await Future.wait(projects.map(service.upsert));

    final loaded = await service.load();
    expect(loaded, hasLength(3));
    expect(loaded.map((p) => p.id).toSet(), {
      'concurrent-0',
      'concurrent-1',
      'concurrent-2',
    });
  });

  test(
    'concurrent atomicWrite calls on one target never fail or mix',
    () async {
      const recovery = ProjectRecoveryService();
      final file = File(
        '${tempRoot.path}${Platform.pathSeparator}concurrent-target.json',
      );
      await recovery.atomicWrite(target: file, content: 'seed\n');

      for (var round = 0; round < 10; round++) {
        await Future.wait([
          recovery.atomicWrite(target: file, content: 'A' * 2048),
          recovery.atomicWrite(target: file, content: 'B' * 2048),
        ]);
        final content = await file.readAsString();
        expect(
          content == 'A' * 2048 || content == 'B' * 2048,
          isTrue,
          reason:
              'round $round left mixed/truncated content: '
              '${content.length} chars',
        );
      }
    },
  );

  test('admission survives a concurrent upsert (no lost admission)', () async {
    // Crash-window state: package complete on disk + creation marker,
    // registry empty (the exact state BUG-05's admission logic protects).
    final orphan = await ProjectPackageService(
      rootDirectory: tempRoot,
    ).create(name: 'Admitted Orphan');

    final service = ProjectRegistryService(rootDirectory: tempRoot);
    final incoming = _model('incoming-project', 'Incoming', tempRoot);

    await Future.wait([service.load(), service.upsert(incoming)]);

    final loaded = await service.load();
    expect(loaded.map((p) => p.id).toSet(), contains(orphan.projectId));
    expect(loaded.map((p) => p.id).toSet(), contains('incoming-project'));
  });
}
