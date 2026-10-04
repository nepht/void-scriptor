import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/app_diagnostics.dart';
import '../../../app/routing/app_routes.dart';
import '../../../core/project_package/void_project_format.dart';
import '../../../features/explorer/presentation/explorer_panel.dart';
import '../../../features/projects/presentation/project_persistence_providers.dart';

/// Settings Hub minimum (queue Choi 5b6e11a, Frontier 1).
///
/// Destination fungsional saja: General (status bahasa UI), Appearance
/// (ThemeSettings nyata), Sidebar & Workspace (status preferensi per proyek),
/// About & Diagnostics (versi + storage nyata). Tanpa kontrol palsu.
class SettingsHubScreen extends ConsumerWidget {
  const SettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(projectSessionProvider).value;
    final palette = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: palette.surface,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const ExpansionTile(
              key: ValueKey('settings-hub-general'),
              title: Text('General'),
              children: [
                ListTile(
                  leading: Icon(Icons.language_outlined),
                  title: Text('Bahasa UI'),
                  subtitle: Text(
                    'Indonesia (beta). Paket lokalisasi bahasa lain masih '
                    'direncanakan; pengaturan bahasa akan aktif ketika '
                    'lokalisasi tersedia.',
                  ),
                ),
              ],
            ),
            ExpansionTile(
              key: const ValueKey('settings-hub-appearance'),
              title: const Text('Appearance'),
              children: [
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Theme'),
                  subtitle: const Text('Dark, Light, dan System.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/theme-settings'),
                ),
              ],
            ),
            ExpansionTile(
              key: const ValueKey('settings-hub-sidebar'),
              title: const Text('Sidebar & Workspace'),
              children: [
                if (session == null)
                  ListTile(
                    leading: const Icon(Icons.folder_open_outlined),
                    title: const Text(
                      'Buka proyek untuk mengatur modul sidebar',
                    ),
                    subtitle: const Text(
                      'Preferensi modul Explorer (Wardrobe, Weapons, Story '
                      'Items) tersimpan per proyek di manifest/sidebar_modules.json. '
                      'Buka proyek lewat halaman Projects, lalu atur dari '
                      '"Configure sidebar modules" di Explorer.',
                    ),
                    onTap: () => context.push(AppRoutes.projects),
                  )
                else
                  _SidebarModulesStatus(projectId: session.manifest.id),
              ],
            ),
            ExpansionTile(
              key: const ValueKey('settings-hub-about'),
              title: const Text('About & Diagnostics'),
              initiallyExpanded: true,
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Versi'),
                  subtitle: Text(VoidProjectFormat.applicationVersion),
                ),
                ListTile(
                  leading: const Icon(Icons.devices_outlined),
                  title: const Text('Platform'),
                  subtitle: Text(defaultTargetPlatform.name),
                ),
                const _StorageDiagnosticsRow(),
                ListTile(
                  leading: const Icon(Icons.folder_copy_outlined),
                  title: const Text('Lokasi penyimpanan kustom'),
                  subtitle: const Text(
                    'Set, relink, dan uji lokasi penyimpanan proyek.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.storageLocations),
                ),
                if (session != null)
                  ListTile(
                    leading: const Icon(Icons.monitor_heart_outlined),
                    title: const Text('Diagnostik proyek'),
                    subtitle: const Text('Buka kesehatan proyek aktif.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.projectDiagnostics),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarModulesStatus extends ConsumerWidget {
  const _SidebarModulesStatus({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(projectSidebarModulePreferencesProvider(projectId));
    return prefs.when(
      loading: () => const ListTile(
        leading: Icon(Icons.tune),
        title: Text('Memuat preferensi modul...'),
      ),
      error: (error, stackTrace) => const ListTile(
        leading: Icon(Icons.tune),
        title: Text('Preferensi modul tidak dapat dibaca'),
        subtitle: Text(
          'Atur ulang dari "Configure sidebar modules" di Explorer.',
        ),
      ),
      data: (value) => ListTile(
        leading: const Icon(Icons.tune),
        title: const Text('Modul sidebar proyek ini'),
        subtitle: Text(
          'Wardrobe: ${value.wardrobe ? "Aktif" : "Nonaktif"}, '
          'Weapons: ${value.weapons ? "Aktif" : "Nonaktif"}, '
          'Story Items: ${value.storyItems ? "Aktif" : "Nonaktif"}. '
          'Ubah dari "Configure sidebar modules" di Explorer.',
        ),
      ),
    );
  }
}

class _StorageDiagnosticsRow extends StatefulWidget {
  const _StorageDiagnosticsRow();

  @override
  State<_StorageDiagnosticsRow> createState() => _StorageDiagnosticsRowState();
}

class _StorageDiagnosticsRowState extends State<_StorageDiagnosticsRow> {
  Future<BootstrapDirectories>? _resolved;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolved ??= BootstrapDirectories.resolve();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BootstrapDirectories>(
      future: _resolved,
      builder: (context, snapshot) {
        final dirs = snapshot.data;
        return ListTile(
          leading: const Icon(Icons.storage_outlined),
          title: const Text('Storage diagnostik'),
          subtitle: Text(
            dirs == null ? 'Memuat lokasi storage...' : dirs.state.path,
            softWrap: true,
          ),
        );
      },
    );
  }
}
