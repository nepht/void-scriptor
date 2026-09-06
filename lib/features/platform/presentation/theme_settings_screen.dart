import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_scriptor/core/theme/app_theme_mode.dart';
import 'package:void_scriptor/core/theme/theme_controller.dart';
import 'package:void_scriptor/features/platform/application/platform_controller.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 50.34 — Theme.
///
/// Opsi: Dark, Light, System + accent color.
class ThemeSettingsScreen extends ConsumerStatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  ConsumerState<ThemeSettingsScreen> createState() =>
      _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends ConsumerState<ThemeSettingsScreen> {
  static const _themes = <String>['Dark', 'Light', 'System'];
  @override
  Widget build(BuildContext context) {
    ref.watch(platformProvider);
    final theme = ref.watch(themeControllerProvider);
    final selected = theme.valueOrNull ?? AppThemeMode.system;
    final selectedLabel = switch (selected) {
      AppThemeMode.dark => 'Dark',
      AppThemeMode.light => 'Light',
      AppThemeMode.system => 'System',
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VoidSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Appearance',
                style: VoidTypography.headingMedium.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: VoidSpacing.md),
              RadioGroup<String>(
                groupValue: selectedLabel,
                onChanged: (value) {
                  if (value == null) return;
                  final mode = switch (value) {
                    'Dark' => AppThemeMode.dark,
                    'Light' => AppThemeMode.light,
                    _ => AppThemeMode.system,
                  };
                  ref.read(themeControllerProvider.notifier).setMode(mode);
                },
                child: Column(
                  children: [
                    for (final t in _themes)
                      RadioListTile<String>(title: Text(t), value: t),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
