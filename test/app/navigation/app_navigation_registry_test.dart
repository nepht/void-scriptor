import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/navigation/app_navigation_registry.dart';

void main() {
  test(
    'core navigation is unique, ordered, and separated from optional tools',
    () {
      expect(coreNavigationDestinations.map((item) => item.id), [
        AppNavigationId.dashboard,
        AppNavigationId.novels,
        AppNavigationId.characters,
        AppNavigationId.world,
        AppNavigationId.search,
        AppNavigationId.backupExport,
        AppNavigationId.settings,
      ]);
      expect(
        coreNavigationDestinations.map((item) => item.key).toSet().length,
        coreNavigationDestinations.length,
      );
      expect(
        optionalNavigationDestinations
            .map((item) => item.id)
            .toSet()
            .intersection(
              coreNavigationDestinations.map((item) => item.id).toSet(),
            ),
        isEmpty,
      );
      expect(
        [
          ...coreNavigationDestinations,
          ...optionalNavigationDestinations,
        ].every((item) => item.route.isNotEmpty),
        isTrue,
      );
    },
  );

  test('only a small thumb-friendly subset is primary on mobile', () {
    expect(mobilePrimaryDestinations.map((item) => item.id), [
      AppNavigationId.dashboard,
      AppNavigationId.novels,
      AppNavigationId.write,
      AppNavigationId.characters,
    ]);
  });
}
