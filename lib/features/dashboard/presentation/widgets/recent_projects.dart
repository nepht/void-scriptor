import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';
import '../../../projects/domain/project_model.dart';
import '../../../projects/presentation/project_controller.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class RecentProjects extends ConsumerWidget {
  const RecentProjects({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectControllerProvider);
    return VoidCard(
      child: projects.when(
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RecentProjectsHeader(
              onViewAll: () => context.go(AppRoutes.projects),
            ),
            const SizedBox(height: 16),
            const Text('Loading projects...'),
          ],
        ),
        error: (error, stack) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Projects could not be loaded.'),
            TextButton(
              onPressed: () => ref.invalidate(projectControllerProvider),
              child: const Text('Try again'),
            ),
          ],
        ),
        data: (items) {
          final recent = [...items]
            ..sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
          final visible = recent.take(4).toList();
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
              if (visible.isEmpty) ...[
                const Text(
                  'No projects yet. Create your first universe.',
                  style: VoidTypography.body,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => context.go(AppRoutes.createProject),
                  icon: const Icon(Icons.add),
                  label: const Text('Create your first project'),
                ),
              ] else ...[
                _ContinueProject(project: visible.first),
                if (visible.length > 1) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Other recent projects',
                    style: VoidTypography.title,
                  ),
                  const SizedBox(height: 8),
                ],
                for (var index = 1; index < visible.length; index++) ...[
                  _ProjectItem(project: visible[index]),
                  if (index != visible.length - 1) const Divider(),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _RecentProjectsHeader extends StatelessWidget {
  const _RecentProjectsHeader({required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text('Recent Projects', style: VoidTypography.headingMedium),
        ),
        TextButton(onPressed: onViewAll, child: const Text('View all')),
      ],
    );
  }
}

void _openProject(BuildContext context, WidgetRef ref, ProjectModel project) {
  ref.read(currentProjectProvider.notifier).state = project;
  context.go('/studio/${Uri.encodeComponent(project.id)}');
}

String _openedLabel(BuildContext context, ProjectModel project) =>
    'Last opened ${MaterialLocalizations.of(context).formatMediumDate(project.lastOpenedAt.toLocal())}';

class _ProjectCover extends StatelessWidget {
  const _ProjectCover({required this.project, this.large = false});
  final ProjectModel project;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final thumbnail = project.thumbnailPath;
    final placeholder = ColoredBox(
      color: context.palette.surfaceElevated,
      child: Center(
        child: Icon(
          Icons.auto_stories_outlined,
          size: large ? 40 : 24,
          color: context.palette.textMuted,
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: large ? 112 : 48,
        height: large ? 156 : 64,
        child: !kIsWeb && thumbnail != null && thumbnail.trim().isNotEmpty
            ? Image.file(
                File(
                  path.isAbsolute(thumbnail)
                      ? thumbnail
                      : path.join(project.localPath, thumbnail),
                ),
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) => placeholder,
              )
            : placeholder,
      ),
    );
  }
}

class _ContinueProject extends ConsumerWidget {
  const _ContinueProject({required this.project});
  final ProjectModel project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pick up where you left off',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: context.palette.textMuted),
        ),
        const SizedBox(height: 8),
        Text(
          project.name,
          style: Theme.of(context).textTheme.headlineSmall,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        if (project.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            project.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 12),
        Text(
          _openedLabel(context, project),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => _openProject(context, ref, project),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Continue writing'),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 480) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProjectCover(project: project),
              const SizedBox(height: 16),
              details,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProjectCover(project: project, large: true),
            const SizedBox(width: 24),
            Expanded(child: details),
          ],
        );
      },
    );
  }
}

class _ProjectItem extends ConsumerWidget {
  const _ProjectItem({required this.project});

  final ProjectModel project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _openProject(context, ref, project),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            _ProjectCover(project: project),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: VoidTypography.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    project.description.isEmpty
                        ? 'No description'
                        : project.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VoidTypography.caption,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _openedLabel(context, project),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.palette.textMuted),
          ],
        ),
      ),
    );
  }
}
