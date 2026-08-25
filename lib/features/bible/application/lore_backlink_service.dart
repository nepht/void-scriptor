import 'package:drift/drift.dart' hide isNull;

import '../../story/domain/inline_lore_links.dart';
import '../../story/domain/lore_backlinks.dart';
import '../../story/domain/lore_link_suggester.dart';
import '../../../database/project/project_database.dart';
import 'create_lore_entity_service.dart';

/// Layanan integritas lore-link tingkat proyek (Step 109.11).
///
/// Menjembatani domain murni [LoreLinkClassifier]/[ProjectLoreLinkEditor]
/// dengan database Drift: memindai seluruh draft scene dan beat cerita,
/// mengklasifikasi setiap target `[[Entity]]` terhadap katalog lore, dan
/// menyediakan aksi perbaikan retarget.
class LoreBacklinkService {
  const LoreBacklinkService();

  /// Daftar pasangan (sumberId → target mentah) dari semua teks proyek.
  ///
  /// Sumber mencakup draft scene (`beatType='draft'`) dan beat biasa; judul
  /// scene dipakai sebagai label manusiawi laporan.
  Future<Map<String, ({String title, List<String> targets})>> collectSources(
    ProjectDatabase db,
    String projectId,
  ) async {
    final storyRows = await (db.select(
      db.stories,
    )..where((row) => row.projectId.equals(projectId))).get();
    if (storyRows.isEmpty) return const {};

    final scenes = await (db.select(
      db.storyScenes,
    )..where((row) => row.storyId.isIn(storyRows.map((s) => s.assetId)))).get();
    final titles = {for (final scene in scenes) scene.id: scene.title};

    final beats = await (db.select(db.sceneBeats)).get();
    const parser = InlineLoreLinkParser();
    final sources = <String, ({String title, List<String> targets})>{};

    for (final beat in beats) {
      final segments = parser.parse(beat.content);
      final targets = <String>[];
      for (final segment in segments) {
        if (segment is! LoreLinkSegment) continue;
        if (!titles.containsKey(beat.sceneId)) continue;
        targets.add(segment.displayName);
      }
      if (targets.isEmpty) continue;
      final existing = sources[beat.sceneId];
      sources[beat.sceneId] = (
        title: titles[beat.sceneId] ?? beat.sceneId,
        targets: [...?existing?.targets, ...targets],
      );
    }
    return sources;
  }

  /// Query backlink: semua kemunculan tautan ke [entityName] lintas sumber.
  ///
  /// Pencocokan case-sensitive pada display name (isi kurung setelah trim),
  /// selaras dengan semantik [InlineLoreLinkEditor.renameTarget]; teks polos
  /// dan escape literal tidak pernah masuk hasil.
  Future<List<LoreLinkFinding>> backlinks(
    ProjectDatabase db, {
    required String projectId,
    required String entityName,
    List<LoreEntityRef>? catalog,
  }) async {
    final sources = await collectSources(db, projectId);
    final needle = entityName.trim();
    final results = <LoreLinkFinding>[];
    for (final finding in sources.entries) {
      var occurrences = 0;
      for (final rawTarget in finding.value.targets) {
        if (rawTarget.trim() == needle) occurrences++;
      }
      if (occurrences == 0) continue;
      results.add(
        LoreLinkFinding(
          sourceId: finding.key,
          sourceTitle: finding.value.title,
          target: needle,
          occurrences: occurrences,
        ),
      );
    }
    return results;
  }

  /// Laporan integritas lengkap: broken + ambiguous + resolved per sumber.
  ///
  /// Bila [catalog] tak diberikan, katalog live proyek dimuat via
  /// [CreateLoreEntityService.loadCatalog].
  Future<LoreLinkIntegrityReport> scanIntegrity(
    ProjectDatabase db, {
    required String projectId,
    List<LoreEntityRef>? catalog,
  }) async {
    final refs =
        catalog ??
        await const CreateLoreEntityService().loadCatalog(db, projectId);
    final sources = await collectSources(db, projectId);
    return LoreLinkIntegrityReport(
      const LoreLinkClassifier().classify(sources, catalog: refs),
    );
  }

  /// Aksi perbaikan: ganti nama target [from] menjadi [to] di SEMUA sumber
  /// proyek dan tulis kembali konten yang benar-benar berubah.
  ///
  /// Mengembalikan jumlah sumber yang ditulis ulang; konten tanpa segmen
  /// link yang cocok tidak disentuh sama sekali.
  Future<int> retargetOccurrences(
    ProjectDatabase db, {
    required String projectId,
    required String from,
    required String to,
  }) async {
    final beats = await (db.select(db.sceneBeats)).get();
    const editor = ProjectLoreLinkEditor();
    var changed = 0;

    for (final beat in beats) {
      final next = editor.retarget(beat.content, from: from, to: to);
      if (identical(next, beat.content)) continue;
      await (db.update(db.sceneBeats)..where((row) => row.id.equals(beat.id)))
          .write(SceneBeatsCompanion(content: Value(next)));
      changed++;
    }
    return changed;
  }
}
