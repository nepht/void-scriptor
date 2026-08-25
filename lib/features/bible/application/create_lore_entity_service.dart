import 'package:uuid/uuid.dart';

import '../../story/domain/lore_link_suggester.dart';
import '../../../database/project/project_database.dart';
import '../domain/bible_entry.dart' as bible_domain;
import 'bible_repository.dart';

/// Layanan lore-linking untuk editor (Step 109.10).
///
/// Menyatukan tiga kebutuhan autocomplete dari katalog lintas-tabel:
/// memuat entitas lore proyek, mendeteksi nama yang sudah ada (duplicate
/// warning), dan membuat entitas baru sebagai Bible entry.
class CreateLoreEntityService {
  const CreateLoreEntityService();

  /// Memuat seluruh entitas lore proyek dari Species, Technologies,
  /// PowerSystems, dan BibleEntries.
  Future<List<LoreEntityRef>> loadCatalog(
    ProjectDatabase db,
    String projectId,
  ) async {
    final species = await (db.select(
      db.species,
    )..where((row) => row.projectId.equals(projectId))).get();
    final technologies = await (db.select(
      db.technologies,
    )..where((row) => row.projectId.equals(projectId))).get();
    final powerSystems = await (db.select(
      db.powerSystems,
    )..where((row) => row.projectId.equals(projectId))).get();

    final bibleRepo = BibleRepository(db);
    final entries = await bibleRepo.listEntries(projectId);

    return [
      ...species.map(
        (row) => LoreEntityRef(
          id: row.assetId,
          name: row.name,
          kind: 'species',
          detail: row.description.trim(),
        ),
      ),
      ...technologies.map(
        (row) => LoreEntityRef(
          id: row.assetId,
          name: row.name,
          kind: 'technology',
          detail: row.description.trim(),
        ),
      ),
      ...powerSystems.map(
        (row) => LoreEntityRef(
          id: row.assetId,
          name: row.name,
          kind: 'powerSystem',
          detail: row.description.trim(),
        ),
      ),
      ...entries
          .where((entry) => entry.title.trim().isNotEmpty)
          .map(
            (entry) => LoreEntityRef(
              id: entry.id,
              name: entry.title,
              kind: 'bible:${entry.type.name}',
              detail: entry.content.trim(),
            ),
          ),
    ];
  }

  /// Nama eksisting yang cocok dengan [name] secara case-insensitive
  /// dengan spasi dipipihkan, atau null bila tidak ada — sumber duplicate
  /// warning sebelum menawarkan pembuatan entitas.
  Future<String?> findExistingName(
    ProjectDatabase db,
    String projectId,
    String name, {
    List<LoreEntityRef>? catalog,
  }) async {
    final refs = catalog ?? await loadCatalog(db, projectId);
    final match = const LoreLinkSuggester().exactMatchOf(refs, query: name);
    return match?.name;
  }

  /// Membuat entitas lore baru sebagai [bible_domain.BibleEntryType.lore]
  /// dan mengembalikan referensinya. Menolak nama kosong dengan
  /// [ArgumentError] dan nama duplikat (case-insensitive) dengan
  /// [StateError].
  Future<LoreEntityRef> create(
    ProjectDatabase db, {
    required String projectId,
    required String name,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be blank');
    }
    final existing = await findExistingName(db, projectId, trimmed);
    if (existing != null) {
      throw StateError('Lore entity already exists: $existing');
    }

    final now = DateTime.now().toUtc();
    final entry = bible_domain.BibleEntry(
      id: const Uuid().v4(),
      projectId: projectId,
      type: bible_domain.BibleEntryType.lore,
      title: trimmed,
      content: '',
      createdAt: now,
      updatedAt: now,
    );
    await BibleRepository(db).saveEntry(entry);

    return LoreEntityRef(id: entry.id, name: entry.title, kind: 'bible:lore');
  }
}
