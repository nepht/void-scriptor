import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/domain/project_model.dart';
import 'package:void_scriptor/core/persistence/project_registry_service.dart';

/// Bug-hunt run94 BUG-04 (Referee REAL BUG, Medium) - 145.42 registry layer.
///
/// Registry korut bukan power-loss window (recoverIfInterrupted hanya
/// menangani target HILANG): isi rusak (bit rot, suntingan manual, tulis
/// parsial lewat jalur lain) membuat load() melempar FormatException/TypeError
/// mentah dan remove() ikut abort - registry/disk divergen. Kontrak slice ini
/// (mengikuti precedent ProjectManifestService.read):
/// 1. registry korut + .bak valid   -> pulihkan .bak ke target, baca berhasil;
/// 2. registry korut tanpa .bak     -> ProjectRegistryUnreadableException
///    (typed, path + cause), berkas korut DIPERTAHANKAN untuk inspeksi;
/// 3. JSON valid tapi bentuk salah  -> typed exception juga (bukan TypeError
///    mentah);
/// 4. remove() pada registry korut  -> typed exception, tidak ada penulisan
///    registry (tidak ada divergensi diam-diam).
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
  test(
    'load() restores the last durable registry copy from .bak when the current registry is corrupt',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'vs-bug04-registry-crc-',
      );
      addTearDown(() => root.delete(recursive: true));
      final service = ProjectRegistryService(rootDirectory: root);
      await service.save([_model('registry-bak-1', 'Sebelum', root)]);
      await service.save([_model('registry-bak-1', 'Sesudah', root)]);

      final file = File('${root.path}${Platform.pathSeparator}projects.json');
      // Korupsi byte-level pada target (bukan hilang): tulis parsial.
      await file.writeAsBytes(
        utf8.encode('{"schemaVersion": 1, "proj'),
        flush: true,
      );

      final projects = await service.load();

      expect(projects.map((p) => p.name), ['Sebelum']);
      expect(await file.exists(), isTrue);
      final healed = await file.readAsString();
      expect(healed, contains('"Sebelum"'));
      // .bak dikonsumsi oleh restore, tidak duplikat tersisa.
      expect(File('${file.path}.bak').existsSync(), isFalse);
    },
  );

  test(
    'load() throws the typed unreadable exception when corruption has no durable backup',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'vs-bug04-registry-crc-',
      );
      addTearDown(() => root.delete(recursive: true));
      final file = File('${root.path}${Platform.pathSeparator}projects.json');
      const garbage = '{"schemaVersion": 1, "proj';
      await file.writeAsString(garbage, flush: true);

      await expectLater(
        ProjectRegistryService(rootDirectory: root).load(),
        throwsA(
          isA<ProjectRegistryUnreadableException>()
              .having((e) => e.registryPath, 'registryPath', file.path)
              .having((e) => e.cause, 'cause', isA<FormatException>()),
        ),
      );
      // Berkas korut dipertahankan untuk inspeksi manual, tidak dihapus diam.
      expect(await file.readAsString(), garbage);
    },
  );

  test(
    'load() reports a wrong-shape registry as the typed unreadable exception',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'vs-bug04-registry-shape-',
      );
      addTearDown(() => root.delete(recursive: true));
      final file = File('${root.path}${Platform.pathSeparator}projects.json');
      const shape = '[{"id": "bukan-object"}]';
      await file.writeAsString(shape, flush: true);

      await expectLater(
        ProjectRegistryService(rootDirectory: root).load(),
        throwsA(
          isA<ProjectRegistryUnreadableException>().having(
            (e) => e.registryPath,
            'registryPath',
            file.path,
          ),
        ),
      );
      expect(await file.readAsString(), shape);
    },
  );

  test(
    'remove() on a corrupt registry fails loudly without writing the registry',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'vs-bug04-registry-remove-',
      );
      addTearDown(() => root.delete(recursive: true));
      final file = File('${root.path}${Platform.pathSeparator}projects.json');
      const garbage = '{"schemaVersion": 1, "projects": [{"id": 1}]}';
      await file.writeAsString(garbage, flush: true);

      await expectLater(
        ProjectRegistryService(rootDirectory: root).remove('gone'),
        throwsA(isA<ProjectRegistryUnreadableException>()),
      );
      expect(await file.readAsString(), garbage);
    },
  );
}
