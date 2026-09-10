import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme_mode.dart';
import 'theme_controller.dart';

/// Menu popup kompak untuk memilih tema (System / Terang / Gelap) dan
/// keluarga warna aksen (polish run184: akses cepat tanpa buka Settings).
///
/// Dipakai langsung dari top bar dan layar login. Ikonnya menampilkan
/// status tema aktif.
class ThemeModeMenu extends ConsumerWidget {
  const ThemeModeMenu({super.key, this.iconSize = 18});

  final double iconSize;

  static const _entries = <({AppThemeMode mode, String label, IconData icon})>[
    (
      mode: AppThemeMode.system,
      label: 'System (default)',
      icon: Icons.brightness_auto_rounded,
    ),
    (mode: AppThemeMode.light, label: 'Light', icon: Icons.light_mode_rounded),
    (mode: AppThemeMode.dark, label: 'Dark', icon: Icons.dark_mode_rounded),
  ];

  static const _accentLabels = <VoidThemeAccent, String>{
    VoidThemeAccent.voidPurple: 'Void Purple',
    VoidThemeAccent.ink: 'Ink',
    VoidThemeAccent.ember: 'Ember',
    VoidThemeAccent.sage: 'Sage',
    VoidThemeAccent.rose: 'Rose',
    VoidThemeAccent.ocean: 'Ocean',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current =
        ref.watch(themeControllerProvider).value ?? AppThemeMode.system;
    final currentAccent =
        ref.watch(themeAccentControllerProvider).value ??
        VoidThemeAccent.voidPurple;
    final accentScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<Object>(
      tooltip: 'Theme',
      icon: Icon(Icons.palette_outlined, size: iconSize),
      onSelected: (value) {
        if (value is AppThemeMode) {
          ref.read(themeControllerProvider.notifier).setMode(value);
        } else if (value is String) {
          final accent = VoidThemeAccent.values.firstWhere(
            (a) => a.name == value,
          );
          ref.read(themeAccentControllerProvider.notifier).setAccent(accent);
        }
      },
      itemBuilder: (context) => [
        for (final entry in _entries)
          PopupMenuItem<AppThemeMode>(
            value: entry.mode,
            child: Row(
              children: [
                Icon(
                  entry.icon,
                  size: 18,
                  color: current == entry.mode ? accentScheme.primary : null,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(entry.label)),
                if (current == entry.mode)
                  Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: accentScheme.primary,
                  ),
              ],
            ),
          ),
        const PopupMenuDivider(),
        // Akses cepat aksen warna: pemilihan langsung menyimpan via
        // ThemeAccentController (persistensi appearance.theme_accent).
        const PopupMenuItem<String>(
          enabled: false,
          child: Text('Accent color'),
        ),
        for (final accent in VoidThemeAccent.values)
          PopupMenuItem<String>(
            value: accent.name,
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.variant.lightPalette.primary,
                    border: Border.all(
                      color: accentScheme.onSurface.withValues(alpha: 0.25),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(_accentLabels[accent]!)),
                if (currentAccent == accent)
                  Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: accentScheme.primary,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
