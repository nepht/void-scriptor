import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../navigation/app_navigation_registry.dart';
import '../../../design_system/widgets/branding/void_logo.dart';
import '../../../features/assets/domain/asset_type.dart';
import '../../../features/explorer/presentation/explorer_panel.dart';
import '../../../features/workspace/presentation/workspace_panel.dart';
import '../../routing/app_routes.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class VoidMobileShell extends ConsumerStatefulWidget {
  const VoidMobileShell({
    super.key,
    this.content,
    this.onLogout,
    this.projectId,
  });

  final Widget? content;
  final VoidCallback? onLogout;
  final String? projectId;

  @override
  ConsumerState<VoidMobileShell> createState() => _VoidMobileShellState();
}

class _VoidMobileShellState extends ConsumerState<VoidMobileShell> {
  int _selectedIndex = 0;

  void _selectDestination(int index) {
    if (index == mobilePrimaryDestinations.length) {
      _showMoreActions();
      return;
    }
    setState(() => _selectedIndex = index);
    _goToDestination(mobilePrimaryDestinations[index]);
  }

  Future<void> _showMoreActions() {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.palette.panel,
      builder: (sheetContext) => Theme(
        data: Theme.of(sheetContext).copyWith(
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
                  child: Text('Navigate'),
                ),
                for (final destination in coreNavigationDestinations.skip(3))
                  _MoreDestination(
                    icon: destination.icon,
                    label: destination.label,
                    onTap: () => _goFromSheet(sheetContext, destination),
                  ),
                for (final destination in optionalNavigationDestinations)
                  if (destination.id == AppNavigationId.aiStudio)
                    _MoreDestination(
                      icon: destination.icon,
                      label: destination.label,
                      onTap: () => _goFromSheet(sheetContext, destination),
                    ),
                const Divider(),
                ExpansionTile(
                  leading: const Icon(Icons.extension_outlined),
                  title: const Text('Optional tools'),
                  children: [
                    for (final destination in optionalNavigationDestinations)
                      if (destination.id != AppNavigationId.aiStudio)
                        _MoreDestination(
                          icon: destination.icon,
                          label: destination.label,
                          onTap: () => _goFromSheet(sheetContext, destination),
                        ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goFromSheet(
    BuildContext sheetContext,
    AppNavigationDestination destination,
  ) {
    Navigator.of(sheetContext).pop();
    _goToDestination(destination);
  }

  void _goToDestination(AppNavigationDestination destination) {
    if (destination.requiresProject && widget.projectId == null) {
      context.push(AppRoutes.projects);
      return;
    }
    if (destination.id == AppNavigationId.characters) {
      focusExplorerAsset(ref, AssetType.character);
    } else if (destination.id == AppNavigationId.world) {
      focusExplorerAsset(ref, AssetType.environment);
    }
    final route =
        destination.id == AppNavigationId.write && widget.projectId != null
        ? AppRoutes.studioProject.replaceFirst(':projectId', widget.projectId!)
        : destination.route;
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        backgroundColor: context.palette.panel,
        titleSpacing: 12,
        title: const VoidLogo(),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Account menu',
            onSelected: (value) {
              if (value == 'account') {
                context.push(AppRoutes.accountCloud);
              } else {
                widget.onLogout?.call();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'account', child: Text('Account & Cloud')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'logout', child: Text('Log out')),
            ],
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: context.palette.panel,
        child: const SafeArea(child: ExplorerPanel()),
      ),
      body: widget.content ?? const WorkspacePanel(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectDestination,
        destinations: [
          for (final destination in mobilePrimaryDestinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              label: destination.label,
            ),
          const NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

class _MoreDestination extends StatelessWidget {
  const _MoreDestination({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final density = Theme.of(context).visualDensity;
    return ListTile(
      visualDensity: density,
      leading: Icon(icon, color: context.palette.textSecondary),
      title: Text(label, style: TextStyle(color: context.palette.textPrimary)),
      onTap: onTap,
    );
  }
}
