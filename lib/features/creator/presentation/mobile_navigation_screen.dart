import 'package:flutter/material.dart';

/// Step 43.52 — Mobile Navigation.
///
/// Bottom navigation untuk layar mobile: Home, Projects, Create, AI, Profile.
class MobileNavigationScreen extends StatefulWidget {
  const MobileNavigationScreen({super.key});

  @override
  State<MobileNavigationScreen> createState() => _MobileNavigationScreenState();
}

class _MobileNavigationScreenState extends State<MobileNavigationScreen> {
  int _index = 0;

  static const _destinations = <(IconData, IconData, String)>[
    (Icons.home_outlined, Icons.home, 'Home'),
    (Icons.folder_copy_outlined, Icons.folder_copy, 'Projects'),
    (Icons.add_circle_outline, Icons.add_circle, 'Create'),
    (Icons.auto_awesome_outlined, Icons.auto_awesome, 'AI'),
    (Icons.person_outline, Icons.person, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Text(
            _destinations[_index].$3,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final (icon, selectedIcon, label) in _destinations)
            NavigationDestination(
              icon: Icon(icon),
              selectedIcon: Icon(selectedIcon),
              label: label,
            ),
        ],
      ),
    );
  }
}
