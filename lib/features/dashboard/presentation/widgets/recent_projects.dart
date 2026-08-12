import 'package:flutter/material.dart';

import '../../../../design_system/colors/void_colors.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';

class RecentProjects extends StatelessWidget {
  const RecentProjects({super.key});

  @override
  Widget build(BuildContext context) {
    return const VoidCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Projects', style: VoidTypography.headingMedium),
          SizedBox(height: 16),
          _ProjectItem(name: 'Void Universe', subtitle: 'Edited recently'),
          Divider(),
          _ProjectItem(name: 'Neo Lyra', subtitle: '2 days ago'),
        ],
      ),
    );
  }
}

class _ProjectItem extends StatelessWidget {
  const _ProjectItem({required this.name, required this.subtitle});

  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 42,
          decoration: BoxDecoration(
            color: VoidColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.folder_outlined, color: VoidColors.textMuted),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: VoidTypography.title),
              const SizedBox(height: 3),
              Text(subtitle, style: VoidTypography.caption),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: VoidColors.textMuted),
      ],
    );
  }
}
