import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/audio_import/application/audio_import_repository.dart';

void main() {
  test(
    'audio import copies, hashes, caches waveform and detects missing file',
    () async {
      final root = await Directory.systemTemp.createTemp('audio-import-');
      addTearDown(() => root.delete(recursive: true));
      final source = File('${root.path}/portal.wav')
        ..writeAsBytesSync(List<int>.generate(128, (i) => i));
      final paths = ProjectPaths(rootDirectory: root);
      await (await paths.project('p')).create(recursive: true);
      final service = ProjectDatabaseService();
      final db = await service.open((await paths.database('p')).path);
      final repo = AudioImportRepository(db);
      final result = await repo.importFile(
        projectId: 'p',
        source: source,
        paths: paths,
        category: 'sfx',
        sampleRate: 48000,
        channels: 2,
      );
      expect(db.schemaVersion, 37);
      expect(result.contentHash, isNotEmpty);
      expect(result.projectRelativePath, contains('assets'));
      expect(
        (await repo.healthFor(result.audioFileId, paths: paths)).healthy,
        isTrue,
      );
      final imported = File(
        '${(await paths.project('p')).path}/${result.projectRelativePath}',
      );
      await imported.delete();
      expect(
        (await repo.healthFor(result.audioFileId, paths: paths)).exists,
        isFalse,
      );
      await db.close();
    },
  );
}
