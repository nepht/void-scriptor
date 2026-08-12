import 'package:flutter/material.dart';

import '../../../design_system/colors/void_colors.dart';

class ExplorerPanel extends StatelessWidget {
  const ExplorerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 245,
      decoration: const BoxDecoration(
        color: VoidColors.panel,
        border: Border(right: BorderSide(color: VoidColors.borderSoft)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Text(
              'PROJECT EXPLORER',
              style: TextStyle(
                color: VoidColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              children: const [
                _ExplorerItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                ),
                _ExplorerItem(icon: Icons.folder_outlined, label: 'Projects'),
                _ExplorerGroup(
                  title: 'Characters',
                  children: ['Main Characters', 'Supporting', 'NPC', 'Enemies'],
                ),
                _ExplorerItem(
                  icon: Icons.checkroom_outlined,
                  label: 'Wardrobe',
                ),
                _ExplorerItem(
                  icon: Icons.auto_fix_high_outlined,
                  label: 'Weapons',
                ),
                _ExplorerItem(
                  icon: Icons.landscape_outlined,
                  label: 'Environment',
                ),
                _ExplorerItem(icon: Icons.menu_book_outlined, label: 'Story'),
                _ExplorerItem(icon: Icons.timeline_outlined, label: 'Timeline'),
                _ExplorerItem(
                  icon: Icons.auto_awesome_outlined,
                  label: 'AI Studio',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplorerItem extends StatelessWidget {
  const _ExplorerItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: VoidColors.textMuted),
            const SizedBox(width: 9),
            Text(
              label,
              style: const TextStyle(
                color: VoidColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplorerGroup extends StatelessWidget {
  const _ExplorerGroup({required this.title, required this.children});

  final String title;
  final List<String> children;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: true,
      tilePadding: const EdgeInsets.symmetric(horizontal: 9),
      childrenPadding: const EdgeInsets.only(left: 28),
      leading: const Icon(
        Icons.people_outline,
        size: 16,
        color: VoidColors.textMuted,
      ),
      title: Text(
        title,
        style: const TextStyle(color: VoidColors.textSecondary, fontSize: 12),
      ),
      children: children
          .map(
            (item) => ListTile(
              dense: true,
              minTileHeight: 30,
              title: Text(
                item,
                style: const TextStyle(
                  color: VoidColors.textMuted,
                  fontSize: 11,
                ),
              ),
              onTap: () {},
            ),
          )
          .toList(),
    );
  }
}
