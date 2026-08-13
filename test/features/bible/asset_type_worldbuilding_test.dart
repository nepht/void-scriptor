import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';

void main() {
  test('AssetType exposes Bible worldbuilding asset families', () {
    expect(AssetType.values, contains(AssetType.faction));
    expect(AssetType.values, contains(AssetType.species));
    expect(AssetType.values, contains(AssetType.technology));
    expect(AssetType.values, contains(AssetType.powerSystem));
  });
}
