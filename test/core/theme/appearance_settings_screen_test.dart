import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:void_scriptor/app/void_app.dart';
import 'package:void_scriptor/core/theme/app_theme_mode.dart';
import 'package:void_scriptor/core/theme/theme_controller.dart';
import 'package:void_scriptor/core/theme/theme_mode_menu.dart';
import 'package:void_scriptor/core/theme/theme_preference_store.dart';

void main() {
  testWidgets('ThemeModeMenu menampilkan 3 opsi tema dan mengganti ke Light',
      (tester) async {
    final store = InMemoryThemePreferenceStore();
    final container = ProviderContainer(
      overrides: [themePreferenceStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: ThemeModeMenu()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Buka menu popup
    await tester.tap(find.byType(PopupMenuButton<AppThemeMode>));
    await tester.pumpAndSettle();

    expect(find.text('System (default)'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    expect(container.read(themeControllerProvider).value, AppThemeMode.light);
    expect(await store.load(), AppThemeMode.light);
  });

  testWidgets('VoidScriptorApp menerapkan light theme saat mode light dipilih',
      (tester) async {
    final store = InMemoryThemePreferenceStore();
    await store.save(AppThemeMode.light);

    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('home')),
      ),
    ]);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [themePreferenceStoreProvider.overrideWithValue(store)],
        child: VoidScriptorApp(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.light);
    expect(materialApp.theme?.brightness, Brightness.light);
  });
}
