import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../design_system/colors/void_colors.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';
import '../../../projects/domain/project_model.dart';
import '../../../projects/presentation/project_controller.dart';

class RecentProjects extends ConsumerWidget {
  const RecentProjects({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectControllerProvider);
    return VoidCard(
      child: projects.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Text('$error', style: VoidTypography.body),
        data: (items) {
          final recent = [...items]
            ..sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
          final visible = recent.take(3).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Recent Projects',
                      style: VoidTypography.headingMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.projects),
                    child: const Text('View all'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (visible.isEmpty)
                const Text(
                  'No projects yet. Create your first universe.',
                  style: VoidTypography.body,
                )
              else
                for (var index = 0; index < visible.length; index++) ...[
                  _ProjectItem(project: visible[index]),
                  if (index != visible.length - 1) const Divider(),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _ProjectItem extends ConsumerWidget {
  const _ProjectItem({required this.project});

  final ProjectModel project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        ref.read(currentProjectProvider.notifier).state = project;
        context.go('/studio/${project.id}');
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 42,
              decoration: BoxDecoration(
                color: VoidColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.folder_outlined,
                color: VoidColors.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(project.name, style: VoidTypography.title),
                  const SizedBox(height: 3),
                  Text(
                    project.description.isEmpty
                        ? 'No description'
                        : project.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VoidTypography.caption,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: VoidColors.textMuted),
          ],
        ),
      ),
    );
  }
}
