import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../../core/persistence/project_paths.dart';
import '../../../database/project/project_database.dart';
import '../../../database/project/tables/audio_assets.dart';
import '../../../database/project/tables/audio_waveform.dart';
import '../domain/audio_import_models.dart';
part 'audio_import_repository.g.dart';

@DriftAccessor(tables: [AudioFiles, AudioWaveformCaches])
class AudioImportRepository extends DatabaseAccessor<ProjectDatabase>
    with _$AudioImportRepositoryMixin {
  AudioImportRepository(super.db);
  Future<AudioImportResult> importFile({
    required String projectId,
    required File source,
    required ProjectPaths paths,
    required String category,
    int waveformSamples = 64,
    double? durationSeconds,
    int? sampleRate,
    int? channels,
  }) async {
    if (!await source.exists()) {
      throw StateError('Audio source does not exist: ${source.path}');
    }
    final bytes = await source.readAsBytes();
    final hash = sha256.convert(bytes).toString();
    final id = const Uuid().v4();
    final fileName = '${id}_${p.basename(source.path)}';
    final project = await paths.project(projectId);
    final target = File(
      p.join(project.path, 'assets', 'audio', category, fileName),
    );
    await target.parent.create(recursive: true);
    await source.copy(target.path);
    final relative = p.relative(target.path, from: project.path);
    final cacheId = '$id-waveform';
    final peaks = List<double>.generate(
      waveformSamples,
      (i) => bytes.isEmpty ? 0 : (bytes[i % bytes.length] / 255).toDouble(),
    );
    await transaction(() async {
      await into(audioFiles).insert(
        AudioFilesCompanion.insert(
          id: id,
          projectId: projectId,
          filePath: relative,
          contentHash: Value(hash),
          durationSeconds: Value(durationSeconds),
          sampleRate: Value(sampleRate),
          channels: Value(channels),
          createdAt: DateTime.now().toUtc(),
        ),
      );
      await into(audioWaveformCaches).insert(
        AudioWaveformCachesCompanion.insert(
          id: cacheId,
          audioFileId: id,
          sampleCount: waveformSamples,
          peaksJson: jsonEncode(peaks),
          createdAt: DateTime.now().toUtc(),
        ),
      );
    });
    return AudioImportResult(
      audioFileId: id,
      projectRelativePath: relative,
      contentHash: hash,
      waveformCacheId: cacheId,
    );
  }

  Future<AudioHealthResult> healthFor(
    String audioFileId, {
    required ProjectPaths paths,
  }) async {
    final row = await (select(
      audioFiles,
    )..where((x) => x.id.equals(audioFileId))).getSingleOrNull();
    if (row == null) {
      return const AudioHealthResult(
        audioFileId: 'missing',
        exists: false,
        hashMatches: false,
      );
    }
    final file = File(
      p.join((await paths.project(row.projectId)).path, row.filePath),
    );
    if (!await file.exists()) {
      return AudioHealthResult(
        audioFileId: audioFileId,
        exists: false,
        hashMatches: false,
      );
    }
    final hash = sha256.convert(await file.readAsBytes()).toString();
    return AudioHealthResult(
      audioFileId: audioFileId,
      exists: true,
      hashMatches: hash == row.contentHash,
    );
  }
}
