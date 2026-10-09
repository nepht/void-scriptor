import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key, this.onCreateCharacter});

  final VoidCallback? onCreateCharacter;

  @override
  Widget build(BuildContext context) {
    return VoidCard(
      key: const ValueKey('dashboard-quick-actions'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_outlined, color: context.palette.primaryBright),
              const SizedBox(width: 8),
              const Text('Start creating', style: VoidTypography.title),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Open a project or add a new story asset.',
            style: VoidTypography.caption,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                label: const Text('New Novel'),
                icon: const Icon(Icons.add),
                onPressed: () => context.go(AppRoutes.createProject),
              ),
              OutlinedButton.icon(
                label: const Text('Open Novel'),
                icon: const Icon(Icons.folder_open_outlined),
                onPressed: () => context.go(AppRoutes.projects),
              ),
              TextButton.icon(
                label: const Text('Create Character'),
                icon: const Icon(Icons.person_add_alt_1_outlined),
                onPressed: onCreateCharacter,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
