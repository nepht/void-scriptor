// Product contract (Choirudin, 2026-09-06): Armor and Accessory are
// stand-alone project assets. They must exist as first-class AssetType
// values so type-based UIs (asset browser, search, pickers) can see them.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/domain/asset_type.dart';

void main() {
  test('AssetType covers stand-alone armor and accessory', () {
    final names = AssetType.values.map((type) => type.name);
    expect(names, containsAll(<String>['armor', 'accessory']));
  });
}
