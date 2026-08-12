import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/assets/domain/asset_relation_type.dart';
import 'package:void_scriptor/features/relations/application/relation_display_service.dart';

void main() {
  test('relation display labels inverse uses and wears relations', () {
    expect(
      relationDisplayLabel(type: AssetRelationType.uses, incoming: true),
      'used by',
    );
    expect(
      relationDisplayLabel(type: AssetRelationType.wears, incoming: true),
      'worn by',
    );
    expect(
      relationDisplayLabel(type: AssetRelationType.uses, incoming: false),
      'uses',
    );
  });
}
