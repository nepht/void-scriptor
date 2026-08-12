import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/assets/domain/asset_relation_type.dart';

void main() {
  test('environment scene relation has a stable serialized value', () {
    expect(AssetRelationType.locatedIn.value, 'located_in');
    expect(AssetRelationType.takesPlaceIn.value, 'takes_place_in');
  });
}
