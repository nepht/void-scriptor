import 'package:flutter/material.dart';
import 'package:void_scriptor/app/adaptive/adaptive_window_class.dart';

class AdaptiveAppShell extends StatelessWidget {
  const AdaptiveAppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final windowClass = AdaptiveWindowClass.fromWidth(
      MediaQuery.sizeOf(context).width,
    );

    return switch (windowClass) {
      AdaptiveWindowClass.compact => const _CompactShell(),
      AdaptiveWindowClass.medium => const _MediumShell(),
      AdaptiveWindowClass.expanded => const _ExpandedShell(),
    };
  }
}

class _Workspace extends StatelessWidget {
  const _Workspace();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      key: Key('adaptive-workspace'),
      color: Color(0xFF121218),
      child: Center(child: Text('Void Scriptor Workspace')),
    );
  }
}

class _CompactShell extends StatelessWidget {
  const _CompactShell();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        key: const Key('compact-app-bar'),
        title: const Text('Void Scriptor'),
      ),
      body: const _Workspace(),
      bottomNavigationBar: NavigationBar(
        key: const Key('compact-bottom-navigation'),
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            label: 'Project',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            label: 'AI',
          ),
        ],
      ),
    );
  }
}

class _MediumShell extends StatelessWidget {
  const _MediumShell();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Void Scriptor')),
      body: Row(
        children: [
          NavigationRail(
            key: const Key('medium-navigation-rail'),
            selectedIndex: 0,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.folder_outlined),
                label: Text('Project'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                label: Text('AI'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          const Expanded(child: _Workspace()),
        ],
      ),
    );
  }
}

class _ExpandedShell extends StatelessWidget {
  const _ExpandedShell();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            key: const Key('desktop-top-bar'),
            height: 56,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Text('Void Scriptor'),
          ),
          const Divider(height: 1),
          const Expanded(
            child: Row(
              children: [
                SizedBox(
                  key: Key('desktop-explorer'),
                  width: 240,
                  child: Center(child: Text('Explorer')),
                ),
                VerticalDivider(width: 1),
                Expanded(child: _Workspace()),
                VerticalDivider(width: 1),
                SizedBox(
                  key: Key('desktop-inspector'),
                  width: 280,
                  child: Center(child: Text('Inspector')),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Container(
            key: const Key('desktop-status-bar'),
            height: 28,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const Text('Ready'),
          ),
        ],
      ),
    );
  }
}
