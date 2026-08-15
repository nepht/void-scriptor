import 'package:flutter/material.dart';

import '../../../design_system/colors/void_colors.dart';
import '../../../design_system/widgets/branding/void_logo.dart';
import '../../../features/collaboration/domain/sync_models.dart';
import '../../../features/collaboration/presentation/sync_status_indicator.dart';

class VoidTopBar extends StatelessWidget {
  const VoidTopBar({
    super.key,
    required this.onMenuSelected,
    this.onLogout,
    this.onUndo,
    this.onRedo,
    this.canUndo = false,
    this.canRedo = false,
    this.syncStatus = const SyncStatus(),
  });

  final ValueChanged<String> onMenuSelected;
  final VoidCallback? onLogout;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool canUndo;
  final bool canRedo;
  final SyncStatus syncStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: VoidColors.panel,
        border: Border(bottom: BorderSide(color: VoidColors.borderSoft)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1200;
          return Row(
            children: [
              const SizedBox(width: 230, child: VoidLogo()),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _TopMenuButton(
                        label: 'Workspace',
                        onTap: () => onMenuSelected('workspace'),
                      ),
                      _TopMenuButton(
                        label: 'Projects',
                        onTap: () => onMenuSelected('projects'),
                      ),
                      _TopMenuButton(
                        label: 'AI Tools',
                        onTap: () => onMenuSelected('ai'),
                      ),
                      _TopMenuButton(
                        label: 'Assets',
                        onTap: () => onMenuSelected('assets'),
                      ),
                      _TopMenuButton(
                        label: 'Bible',
                        onTap: () => onMenuSelected('bible'),
                      ),
                      if (wide) ...[
                        _TopMenuButton(
                          label: 'Marketplace',
                          onTap: () => onMenuSelected('marketplace'),
                        ),
                        _TopMenuButton(
                          label: 'Donate',
                          onTap: () => onMenuSelected('donate'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (wide) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 240,
                  height: 34,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: const Icon(Icons.search, size: 17),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              _TopIconButton(
                icon: Icons.undo_rounded,
                tooltip: 'Undo',
                onPressed: canUndo ? onUndo : null,
              ),
              _TopIconButton(
                icon: Icons.redo_rounded,
                tooltip: 'Redo',
                onPressed: canRedo ? onRedo : null,
              ),
              _TopIconButton(
                icon: Icons.health_and_safety_outlined,
                tooltip: 'Project resilience',
                onPressed: () => onMenuSelected('resilience'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SyncStatusIndicator(status: syncStatus),
              ),
              const _TopIconButton(
                icon: Icons.notifications_none_rounded,
                tooltip: 'Notifications',
              ),
              IconButton(
                tooltip: 'Logout',
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded, size: 18),
              ),
              const SizedBox(width: 6),
              const CircleAvatar(
                radius: 16,
                backgroundColor: VoidColors.primary,
                child: Icon(
                  Icons.person_outline,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TopMenuButton extends StatelessWidget {
  const _TopMenuButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: VoidColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
    );
  }
}
