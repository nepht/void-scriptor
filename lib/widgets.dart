// UI Components — v1.0.0
// Reusable widget library for Void Scriptor.

import 'package:flutter/material.dart';

// --- Navigation Button (used in tests with scrollUntilVisible) ---
class NavigationButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isActive;

  const NavigationButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.purple : null,
        foregroundColor: isActive ? Colors.white : null,
      ),
    );
  }
}

// --- Status Bar (v1.0.0 live feedback) ---
class StatusBar extends StatelessWidget {
  final String message;
  final Color backgroundColor;

  const StatusBar({
    super.key,
    required this.message,
    this.backgroundColor = const Color(0xFF6C3483),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: backgroundColor,
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.green),
          const SizedBox(width: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// --- TopBar with ThemePicker ---
class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onThemeToggle;
  final VoidCallback? onMenuToggle;

  const TopBar({
    super.key,
    required this.title,
    this.onThemeToggle,
    this.onMenuToggle,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: onMenuToggle != null
          ? IconButton(
              icon: const Icon(Icons.menu),
              onPressed: onMenuToggle,
            )
          : null,
      actions: [
        if (onThemeToggle != null)
          IconButton(
            icon: const Icon(Icons.dark_mode),
            onPressed: onThemeToggle,
          ),
      ],
    );
  }
}

// --- Panel Container (for dock panels) ---
class PanelContainer extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isCollapsed;

  const PanelContainer({
    super.key,
    required this.title,
    required this.child,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          if (!isCollapsed) const Divider(height: 1),
          if (!isCollapsed) child,
        ],
      ),
    );
  }
}
