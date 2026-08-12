import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/colors/void_colors.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';
import '../../domain/project_model.dart';
import '../project_controller.dart';

class ProjectCard extends ConsumerWidget {
  const ProjectCard({super.key, required this.project});

  final ProjectModel project;

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
              decoration: const BoxDecoration(
                color: VoidColors.surfaceElevated,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Center(
                child: Icon(
                  Icons.auto_awesome_mosaic_outlined,
                  size: 38,
                  color: VoidColors.textMuted,
                ),
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
