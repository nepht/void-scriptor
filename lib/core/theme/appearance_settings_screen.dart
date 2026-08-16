import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_mode.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../design_system/colors/void_colors.dart';
import '../../../design_system/typography/void_typography.dart';

/// Halaman pengaturan tampilan (tema) aplikasi.
class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  static const _options =
      <({AppThemeMode mode, String label, String subtitle})>[
        (
          mode: AppThemeMode.system,
          label: 'System (default)',
          subtitle: 'Ikuti tema sistem operasi',
        ),
        (mode: AppThemeMode.light, label: 'Light', subtitle: 'Tampilan terang'),
        (mode: AppThemeMode.dark, label: 'Dark', subtitle: 'Tampilan gelap'),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeControllerProvider).value;

    return Scaffold(
      backgroundColor: VoidColors.background,
      appBar: AppBar(
        title: const Text('Appearance'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Theme', style: VoidTypography.headingLarge),
              const SizedBox(height: 6),
              const Text(
                'Pilih tampilan aplikasi. Perubahan langsung diterapkan '
                'dan disimpan.',
                style: VoidTypography.body,
              ),
              const SizedBox(height: 20),
              for (final option in _options)
                _ThemeOptionTile(
                  mode: option.mode,
                  label: option.label,
                  subtitle: option.subtitle,
                  selected: current == option.mode,
                  onSelected: () => ref
                      .read(themeControllerProvider.notifier)
                      .setMode(option.mode),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.mode,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onSelected,
  });

  final AppThemeMode mode;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected ? VoidColors.surfaceElevated : VoidColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? VoidColors.primary : VoidColors.borderSoft,
        ),
      ),
      child: ListTile(
        onTap: onSelected,
        leading: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selected ? VoidColors.primary : VoidColors.textMuted,
        ),
        title: Text(label, style: VoidTypography.title),
        subtitle: Text(subtitle, style: VoidTypography.caption),
      ),
    );
  }
}
