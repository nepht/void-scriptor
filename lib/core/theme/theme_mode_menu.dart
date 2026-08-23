import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme_mode.dart';
import 'theme_controller.dart';

/// Menu popup kompak untuk memilih tema (System / Terang / Gelap).
///
/// Dipakai langsung dari top bar dan layar login — tanpa membuka halaman
/// pengaturan penuh. Ikonnya menampilkan status tema aktif.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current =
        ref.watch(themeControllerProvider).value ?? AppThemeMode.system;

    return PopupMenuButton<AppThemeMode>(
      tooltip: 'Theme',
      icon: Icon(Icons.palette_outlined, size: iconSize),
      onSelected: (mode) =>
          ref.read(themeControllerProvider.notifier).setMode(mode),
      itemBuilder: (context) => [
        for (final entry in _entries)
          PopupMenuItem<AppThemeMode>(
            value: entry.mode,
            child: Row(
              children: [
                Icon(
                  entry.icon,
                  size: 18,
                  color: current == entry.mode
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(entry.label)),
                if (current == entry.mode)
                  Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
