import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_file_service.dart';
import 'package:void_scriptor/core/persistence/project_manifest.dart';
import 'package:void_scriptor/core/persistence/project_manifest_service.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';

/// Step 145.42 - Data Safety Failure Matrix (corrupt package layer).
///
/// Manifest yang korut bukan power-loss window (recoverIfInterrupted hanya
/// menangani target HILANG): isi rusak (disk penuh di tengah tulis lewat
/// jalur lain, bit rot, suntingan manual) membuat read() melempar
/// FormatException/TypeError mentah tanpa mencoba salinan durable terakhir.
/// Kontrak slice ini:
/// 1. manifest korut + .bak valid  -> pulihkan .bak ke target, baca berhasil;
/// 2. manifest korut tanpa .bak    -> ProjectManifestUnreadableException
///    (typed, path + cause), berkas korut DIPERTAHANKAN untuk inspeksi;
/// 3. JSON valid tapi bentuk salah -> typed exception juga (TypeError cause);
/// 4. restore dari .bak berisi future schema -> tetap ditolak, restore tetap
///    terjadi (konten .bak masuk ke target, keputusan penolakan eksplisit).
ProjectManifest _manifest(String id, String name) => ProjectManifest(
  schemaVersion: 1,
  id: id,
  name: name,
  description: '',
  projectVersion: '0.1.0',
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 2),
  appVersion: '0.1.0',
);

void main() {
  test(
    'read() restores the last durable manifest copy from .bak when the current manifest is corrupt',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'vs14542-manifest-crc-',
      );
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      const id = 'manifest-corrupt-restore';
      await ProjectFileService(paths: paths).createStructure(id);
      final service = ProjectManifestService(paths: paths);
      await service.write(_manifest(id, 'Sebelum'));
      await service.write(_manifest(id, 'Sesudah'));

      final file = await paths.manifest(id);
      // Korupsi byte-level pada target (bukan hilang): tulis parsial.
      await file.writeAsBytes(
        utf8.encode('{"schemaVersion": 1, "proj'),
        flush: true,
      );

      final restored = await service.read(id);

      expect(restored.name, 'Sebelum');
      expect(await file.exists(), isTrue);
      final healed = await file.readAsString();
      expect(healed, contains('"Sebelum"'));
      // .bak dikonsumsi oleh restore, tidak duplikat tersisa.
      expect(File('${file.path}.bak').existsSync(), isFalse);
    },
  );

  test(
    'read() throws the typed unreadable exception when corruption has no durable backup',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'vs14542-manifest-crc-',
      );
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      const id = 'manifest-corrupt-nobak';
      await ProjectFileService(paths: paths).createStructure(id);
      final file = await paths.manifest(id);
      await file.parent.create(recursive: true);
      const garbage = '{"schemaVersion": 1, "proj';
      await file.writeAsString(garbage, flush: true);

      await expectLater(
        ProjectManifestService(paths: paths).read(id),
        throwsA(
          isA<ProjectManifestUnreadableException>()
              .having((e) => e.manifestPath, 'manifestPath', file.path)
              .having((e) => e.cause, 'cause', isA<FormatException>()),
        ),
      );
      // Berkas korut dipertahankan untuk inspeksi manual, tidak dihapus diam.
      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), garbage);
      expect(File('${file.path}.bak').existsSync(), isFalse);
    },
  );

  test(
    'read() wraps shape-corrupt manifests (valid JSON, missing fields) in the typed exception',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'vs14542-manifest-shape-',
      );
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      const id = 'manifest-corrupt-shape';
      await ProjectFileService(paths: paths).createStructure(id);
      final file = await paths.manifest(id);
      await file.parent.create(recursive: true);
      await file.writeAsString('{}', flush: true);

      await expectLater(
        ProjectManifestService(paths: paths).read(id),
        throwsA(
          isA<ProjectManifestUnreadableException>().having(
            (e) => e.cause,
            'cause',
            isA<TypeError>(),
          ),
        ),
      );
    },
  );

  test(
    // Future schema adalah compatibility rejection, BUKAN korupsi: format
    // raw FormatException dari fromJson dipertahankan. Slice ini hanya
    // menjamin restore tetap terjadi sebelum rejection dilaporkan.
    'read() restores a future-schema .bak and still rejects the unsupported schema',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'vs14542-manifest-future-',
      );
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      const id = 'manifest-corrupt-future';
      await ProjectFileService(paths: paths).createStructure(id);
      final file = await paths.manifest(id);
      await file.parent.create(recursive: true);
      final bak = File('${file.path}.bak');
      await bak.writeAsString(
        jsonEncode({
          'schemaVersion': 99,
          'projectId': id,
          'name': 'Masa Depan',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-01T00:00:00.000Z',
        }),
        flush: true,
      );
      await file.writeAsString('{corrupt', flush: true);

      await expectLater(
        ProjectManifestService(paths: paths).read(id),
        throwsA(isA<FormatException>()),
      );
      // Restore tetap terjadi: target kini memuat konten .bak (future
      // schema) sehingga keputusan penolakan bisa diperiksa manual.
      final healed =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(healed['schemaVersion'], 99);
      expect(healed['name'], 'Masa Depan');
    },
  );
}
