import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';
import '../../domain/project_model.dart';
import '../project_controller.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class ProjectCard extends ConsumerWidget {
  const ProjectCard({super.key, required this.project, required this.onDelete});

  final ProjectModel project;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return VoidCard(
      onTap: () {
        ref.read(currentProjectProvider.notifier).state = project;
        context.go('/studio/${project.id}');
      },
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.palette.surfaceElevated,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.auto_awesome_mosaic_outlined,
                      size: 38,
                      color: context.palette.textMuted,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: PopupMenuButton<String>(
                      tooltip: 'Project actions for ${project.name}',
                      onSelected: (value) {
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red),
                              SizedBox(width: 10),
                              Text('Delete Project'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: VoidTypography.title,
                ),
                const SizedBox(height: 4),
                Text(
                  project.description.isEmpty
                      ? 'No description'
                      : project.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: VoidTypography.caption,
                ),
                const SizedBox(height: 10),
                Text(
                  'Version ${project.version}',
                  style: VoidTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
