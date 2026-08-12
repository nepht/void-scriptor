import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/environment/domain/environment_model.dart';
import 'package:void_scriptor/features/environment/domain/environment_type.dart';

void main() {
  test('environment model preserves structured overview fields', () {
    const model = EnvironmentModel(
      assetId: 'env-1',
      projectId: 'project-1',
      name: 'Neo Megacity',
      environmentType: 'city',
      location: 'Rooftop District',
      architecture: 'Neo Futuristic',
      terrain: 'Urban',
    );
    expect(model.name, 'Neo Megacity');
    expect(EnvironmentType.city.value, 'city');
    expect(EnvironmentType.fromValue('void_storm'), isNull);
  });
}
