import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/wardrobe/domain/wardrobe_model.dart';

void main() {
  test('WardrobeModel preserves identity and garment specifications', () {
    const wardrobe = WardrobeModel(
      assetId: 'wardrobe-1',
      projectId: 'project-1',
      name: 'Void Coat',
      category: 'Outerwear',
      primaryMaterial: 'Technical Synthetic',
      fabric: 'Waterproof Fabric',
      fit: 'Oversized',
      style: 'Futuristic Tactical',
    );

    expect(wardrobe.assetId, 'wardrobe-1');
    expect(wardrobe.projectId, 'project-1');
    expect(wardrobe.name, 'Void Coat');
    expect(wardrobe.primaryMaterial, 'Technical Synthetic');
    expect(wardrobe.fabric, 'Waterproof Fabric');
  });
}
