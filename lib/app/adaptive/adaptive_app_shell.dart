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
      AdaptiveWindowClass.phone => const _PhoneShell(),
      AdaptiveWindowClass.tablet => const _TabletShell(),
      AdaptiveWindowClass.compactDesktop => const _DesktopShell(
        showInspector: false,
      ),
      AdaptiveWindowClass.desktop => const _DesktopShell(showInspector: true),
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
      child: Center(
        child: Text(
          'VOID SCRIPTOR',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
      ),
    );
  }
}

class _PhoneShell extends StatelessWidget {
  const _PhoneShell();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        key: const Key('phone-app-bar'),
        title: const Text('Void Scriptor'),
        actions: [
          IconButton(
            key: const Key('phone-open-inspector'),
            tooltip: 'Inspector',
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => const SizedBox(
                key: Key('phone-inspector-bottom-sheet'),
                height: 280,
                child: Center(child: Text('Inspector')),
              ),
            ),
            icon: const Icon(Icons.tune_outlined),
          ),
        ],
      ),
      body: const _Workspace(),
      bottomNavigationBar: NavigationBar(
        key: const Key('phone-bottom-navigation'),
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

class _TabletShell extends StatelessWidget {
  const _TabletShell();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Void Scriptor'),
        actions: [
          IconButton(
            key: const Key('tablet-open-inspector'),
            tooltip: 'Inspector',
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const Dialog(
                key: Key('tablet-inspector-overlay'),
                child: SizedBox(
                  width: 360,
                  height: 520,
                  child: Center(child: Text('Inspector')),
                ),
              ),
            ),
            icon: const Icon(Icons.tune_outlined),
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            key: const Key('tablet-navigation-rail'),
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

class _DesktopShell extends StatefulWidget {
  const _DesktopShell({required this.showInspector});

  final bool showInspector;

  @override
  State<_DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<_DesktopShell> {
  late bool _inspectorVisible = widget.showInspector;

  @override
  void didUpdateWidget(covariant _DesktopShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showInspector != widget.showInspector) {
      _inspectorVisible = widget.showInspector;
    }
  }

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
            child: Row(
              children: [
                const Expanded(child: Text('Void Scriptor')),
                if (!widget.showInspector)
                  IconButton(
                    key: const Key('desktop-toggle-inspector'),
                    tooltip: 'Toggle Inspector',
                    onPressed: () =>
                        setState(() => _inspectorVisible = !_inspectorVisible),
                    icon: const Icon(Icons.tune_outlined),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Row(
              children: [
                const SizedBox(
                  key: Key('desktop-sidebar'),
                  width: 240,
                  child: Center(child: Text('Explorer')),
                ),
                const VerticalDivider(width: 1),
                const Expanded(child: _Workspace()),
                if (_inspectorVisible) ...[
                  const VerticalDivider(width: 1),
                  const SizedBox(
                    key: Key('desktop-inspector'),
                    width: 280,
                    child: Center(child: Text('Inspector')),
                  ),
                ],
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
