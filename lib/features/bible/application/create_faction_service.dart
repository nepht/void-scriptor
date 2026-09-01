import 'package:uuid/uuid.dart';

import '../../../database/project/project_database.dart';
import '../domain/faction.dart' as domain;
import 'faction_repository.dart';

/// Layanan pembuatan Faction untuk Core worldbuilding (Step 145.27).
///
/// Core worldbuilding memprioritaskan Characters, Locations, Factions,
/// Timeline, Relationship Map, dan Lore Notes. Faction sebelumnya hanya
/// memiliki persistence mentah tanpa satu pun jalur pembuatan; service ini
/// menyediakan kontrak pembuatan+listing yang dijamin tervalidasi:
/// - nama kosong ditolak dengan [ArgumentError];
/// - nama duplikat (case-insensitive, per proyek) ditolak dengan [StateError];
/// - identitas memakai UUID, bukan nama proyek.
class CreateFactionService {
  const CreateFactionService();

  Future<domain.FactionModel> create(
    ProjectDatabase db, {
    required String projectId,
    required String name,
    String description = '',
    String ideology = '',
    String status = '',
    String headquarters = '',
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be blank');
    }
    final existing = await FactionRepository(db).findByName(projectId, trimmed);
    if (existing != null) {
      throw StateError('Faction already exists: ${existing.name}');
    }

    final faction = domain.FactionModel(
      assetId: const Uuid().v4(),
      projectId: projectId,
      name: trimmed,
      description: description,
      ideology: ideology,
      status: status,
      headquarters: headquarters,
    );
    await FactionRepository(db).save(faction);
    return faction;
  }
}
