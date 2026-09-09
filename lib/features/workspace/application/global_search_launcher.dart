// Step 145.27 Core Worldbuilding Reduction: satu pintu search global lintas
// domain Core (Characters, Locations/Environments, Stories, Factions).
// Sumber data: baris universal `Assets` untuk karakter/environment/story
// (filter sisi Dart, tanpa query Drift khusus) + tabel `Factions` untuk
// faksi (tidak punya baris Assets). Ranking deterministik: exact > prefix >
// substring, lalu abjad.
import '../../../core/domain/asset_type.dart';
import '../../../database/project/project_database.dart';
import '../../bible/application/faction_repository.dart';

class GlobalSearchHit {
  const GlobalSearchHit({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.score,
    this.assetType,
  });

  final String id;
  final String title;
  final String subtitle;
  final double score;

  /// Null for faction hits (no universal Assets row exists for them).
  final AssetType? assetType;
}

class GlobalSearchLauncher {
  GlobalSearchLauncher({required this.database, FactionRepository? factions})
    : factions = factions ?? FactionRepository(database);

  final ProjectDatabase database;
  final FactionRepository factions;

  Future<List<GlobalSearchHit>> search(
    String query, {
    required String projectId,
    int limit = 20,
    Set<AssetType> types = const {},
  }) async {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return const [];

    final hits = <GlobalSearchHit>[];

    for (final row in await database.assetDao.getAllAssets()) {
      if (row.projectId != projectId) continue;
      final type = _typeFromStorage(row.type);
      if (type == null) {
        // Storage rows whose type cannot map to AssetType (e.g. legacy
        // hair_variant rows) have no typed selection route; listing them
        // would dead-end on a no-op callback (BUG-02).
        continue;
      }
      if (types.isNotEmpty && !types.contains(type)) {
        continue;
      }
      final title = row.name;
      final score = _score(title, needle);
      if (score == null) continue;
      hits.add(
        GlobalSearchHit(
          id: row.id,
          title: title,
          subtitle: type.name,
          score: score,
          assetType: type,
        ),
      );
    }

    if (types.isEmpty || types.contains(AssetType.faction)) {
      for (final faction in await factions.listForProject(projectId)) {
        final score = _score(faction.name, needle);
        if (score == null) continue;
        hits.add(
          GlobalSearchHit(
            id: faction.assetId,
            title: faction.name,
            subtitle: 'faction',
            score: score,
          ),
        );
      }
    }

    hits.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return hits.take(limit).toList(growable: false);
  }

  double? _score(String title, String needle) {
    final lower = title.toLowerCase();
    if (lower == needle) return 100;
    if (lower.startsWith(needle)) return 80;
    if (lower.contains(needle)) return 60;
    return null;
  }

  AssetType? _typeFromStorage(String value) {
    for (final type in AssetType.values) {
      if (type.name == value) return type;
    }
    return null;
  }
}
