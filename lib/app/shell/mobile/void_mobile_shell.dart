import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/widgets/branding/void_logo.dart';
import '../../../features/explorer/presentation/explorer_panel.dart';
import '../../../features/workspace/presentation/workspace_panel.dart';
import '../../routing/app_routes.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class VoidMobileShell extends StatefulWidget {
  const VoidMobileShell({super.key, this.onLogout, this.projectId});

  final VoidCallback? onLogout;
  final String? projectId;

  @override
  State<VoidMobileShell> createState() => _VoidMobileShellState();
}

class _VoidMobileShellState extends State<VoidMobileShell> {
  int _selectedIndex = 0;

  void _selectDestination(int index) {
    if (index == 4) {
      _showMoreActions();
      return;
    }
    setState(() => _selectedIndex = index);
    final route = switch (index) {
      0 when widget.projectId != null => AppRoutes.studioProject.replaceFirst(
        ':projectId',
        widget.projectId!,
      ),
      0 => AppRoutes.workspace,
      1 => AppRoutes.projects,
      2 => AppRoutes.aiStudio,
      3 => AppRoutes.assets,
      _ => AppRoutes.workspace,
    };
    context.go(route);
  }

  Future<void> _showMoreActions() {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.palette.panel,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MoreDestination(
              icon: Icons.collections_bookmark_outlined,
              label: 'References',
              onTap: () => _goFromSheet(sheetContext, AppRoutes.references),
            ),
            _MoreDestination(
              icon: Icons.menu_book_outlined,
              label: 'Project Bible',
              onTap: () => _goFromSheet(sheetContext, AppRoutes.bible),
            ),
            _MoreDestination(
              icon: Icons.health_and_safety_outlined,
              label: 'Diagnostics',
              onTap: () =>
                  _goFromSheet(sheetContext, AppRoutes.projectDiagnostics),
            ),
          ],
        ),
      ),
    );
  }

  void _goFromSheet(BuildContext sheetContext, String route) {
    Navigator.of(sheetContext).pop();
    context.go(route);
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
          IconButton(
            tooltip: 'Search assets',
            onPressed: () => context.go(AppRoutes.assets),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () => context.go(AppRoutes.dashboard),
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      drawer:  Drawer(
        backgroundColor: context.palette.panel,
        child: const SafeArea(child: ExplorerPanel()),
      ),
      body: const WorkspacePanel(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectDestination,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            label: 'Projects',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            label: 'AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            label: 'Assets',
          ),
          NavigationDestination(
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
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: context.palette.textSecondary),
    title: Text(label, style:  TextStyle(color: context.palette.textPrimary)),
    onTap: onTap,
  );
}
