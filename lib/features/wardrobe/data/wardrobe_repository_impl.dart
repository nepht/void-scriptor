import '../../../database/project/project_database.dart';
import '../domain/wardrobe_model.dart';
import '../domain/wardrobe_repository.dart';

class WardrobeRepositoryImpl implements WardrobeRepository {
  WardrobeRepositoryImpl({required this.database, required this.projectId});

  final ProjectDatabase database;
  final String projectId;

  @override
  Future<List<WardrobeModel>> getWardrobes() async =>
      (await database.wardrobeDao.getWardrobes(projectId)).map(_map).toList();

  @override
  Future<WardrobeModel?> getWardrobe(String assetId) async {
    final row = await database.wardrobeDao.getWardrobe(assetId);
    return row == null ? null : _map(row);
  }

  WardrobeModel _map(Wardrobe row) => WardrobeModel(
    assetId: row.assetId,
    projectId: row.projectId,
    name: row.name,
    category: row.category,
    description: row.description,
    primaryMaterial: row.primaryMaterial,
    fabric: row.fabric,
    fit: row.fit,
    style: row.style,
    notes: row.notes,
  );
}
