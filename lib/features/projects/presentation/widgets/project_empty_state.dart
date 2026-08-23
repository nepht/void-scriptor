import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class ProjectEmptyState extends StatelessWidget {
  const ProjectEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.palette.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.palette.borderSoft),
              ),
              child: Icon(
                Icons.folder_open_outlined,
                size: 32,
                color: context.palette.primaryBright,
              ),
            ),
            const SizedBox(height: 20),
            const Text('No projects yet', style: VoidTypography.headingLarge),
            const SizedBox(height: 8),
            const Text(
              'Create your first universe to begin building characters, assets and stories.',
              textAlign: TextAlign.center,
              style: VoidTypography.body,
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.createProject),
              icon: const Icon(Icons.add),
              label: const Text('Create Project'),
            ),
          ],
        ),
      ),
    );
  }
}
