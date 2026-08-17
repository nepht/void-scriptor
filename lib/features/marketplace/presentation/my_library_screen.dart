import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 44.52 — My Library.
///
/// Workspace library: Installed, Updates.
class MyLibraryScreen extends StatelessWidget {
  const MyLibraryScreen({super.key});

  static const _tabs = <String>['Installed', 'Updates'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Library'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: DefaultTabController(
          length: _tabs.length,
          child: Column(
            children: [
              TabBar(tabs: [for (final t in _tabs) Tab(text: t)]),
              Expanded(
                child: TabBarView(
                  children: [const _InstalledTab(), const _UpdatesTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstalledTab extends StatelessWidget {
  const _InstalledTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(VoidSpacing.md),
      children: const [
        _LibraryTile(name: 'AI Writer Pro', version: 'v1.2.0'),
        _LibraryTile(name: 'World Builder Kit', version: 'v0.9.1'),
      ],
    );
  }
}

class _UpdatesTab extends StatelessWidget {
  const _UpdatesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(VoidSpacing.md),
      children: const [
        _LibraryTile(name: 'AI Writer Pro', version: 'v1.3.0 available'),
      ],
    );
  }
}

class _LibraryTile extends StatelessWidget {
  const _LibraryTile({required this.name, required this.version});

  final String name;
  final String version;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.palette.surface,
      margin: const EdgeInsets.only(bottom: VoidSpacing.sm),
      child: ListTile(
        leading: const Icon(Icons.inventory_2_outlined),
        title: Text(name),
        subtitle: Text(version),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
