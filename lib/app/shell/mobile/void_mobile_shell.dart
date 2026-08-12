import 'package:flutter/material.dart';

import '../../../design_system/colors/void_colors.dart';
import '../../../design_system/widgets/branding/void_logo.dart';
import '../../../features/workspace/presentation/workspace_panel.dart';

class VoidMobileShell extends StatefulWidget {
  const VoidMobileShell({super.key, this.onLogout, this.projectId});

  final VoidCallback? onLogout;
  final String? projectId;

  @override
  State<VoidMobileShell> createState() => _VoidMobileShellState();
}

class _VoidMobileShellState extends State<VoidMobileShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoidColors.background,

      appBar: AppBar(
        backgroundColor: VoidColors.panel,
        titleSpacing: 12,
        title: const VoidLogo(),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.person_outline)),
          IconButton(
            tooltip: 'Logout',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),

      drawer: const Drawer(
        backgroundColor: VoidColors.panel,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Project Explorer',
              style: TextStyle(color: VoidColors.textPrimary),
            ),
          ),
        ),
      ),

      body: const WorkspacePanel(),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
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
        ],
      ),
    );
  }
}
