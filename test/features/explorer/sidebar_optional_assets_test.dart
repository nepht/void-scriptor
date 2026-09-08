import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/explorer/application/project_sidebar_module_preferences.dart';

void main() {
  test('optional asset visibility round trips independently', () {
    const preferences = ProjectSidebarModulePreferences(
      factions: false,
      relationshipMap: false,
      creatures: false,
      armor: false,
      accessories: true,
    );
    expect(
      ProjectSidebarModulePreferences.tryFromJson(preferences.toJson()),
      preferences,
    );
    expect(preferences.copyWith(armor: true).creatures, isFalse);
  });
  test('legacy preferences preserve previously visible modules', () {
    final preferences = ProjectSidebarModulePreferences.tryFromJson({
      'version': 4,
      'factions': false,
      'relationshipMap': false,
      'weapons': false,
      'storyItems': false,
      'wardrobe': false,
    })!;
    expect(preferences.creatures, isTrue);
    expect(preferences.armor, isTrue);
    expect(preferences.accessories, isTrue);
    expect(preferences.wardrobe, isFalse);
  });
  test('malformed new visibility flags are rejected', () {
    const preferences = ProjectSidebarModulePreferences(
      factions: false,
      relationshipMap: false,
    );
    expect(
      ProjectSidebarModulePreferences.tryFromJson({
        ...preferences.toJson(),
        'armor': 'false',
      }),
      isNull,
    );
  });
}
