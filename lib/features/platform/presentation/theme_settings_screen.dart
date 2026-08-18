import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  String _selected = 'Dark';

  @override
  Widget build(BuildContext context) {
    ref.watch(platformProvider);
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
                groupValue: _selected,
                onChanged: (v) => setState(() => _selected = v!),
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
