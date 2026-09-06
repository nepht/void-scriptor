import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/theme/app_theme_mode.dart';
import 'package:void_scriptor/core/theme/theme_preference_store.dart';
import 'package:void_scriptor/features/platform/presentation/theme_settings_screen.dart';

void main() {
  testWidgets('theme settings loads and persists the selected mode', (
    tester,
  ) async {
    final store = InMemoryThemePreferenceStore();
    await store.save(AppThemeMode.dark);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [themePreferenceStoreProvider.overrideWithValue(store)],
        child: const MaterialApp(home: ThemeSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RadioListTile<String>), findsNWidgets(3));
    expect(
      tester
          .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
          .groupValue,
      'Dark',
    );

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    expect(await store.load(), AppThemeMode.light);
  });
}
