import '../domain/wardrobe_model.dart';

abstract interface class WardrobeRepository {
  Future<List<WardrobeModel>> getWardrobes();
  Future<WardrobeModel?> getWardrobe(String assetId);
}
