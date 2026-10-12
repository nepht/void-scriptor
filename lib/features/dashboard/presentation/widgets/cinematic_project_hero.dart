import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../design_system/theme/void_palette.dart';
import '../../../../design_system/theme/void_theme_context.dart';
import '../../../projects/domain/project_model.dart';
import '../../../projects/presentation/project_controller.dart';
import 'project_thumbnail.dart';

/// Full-bleed project focus for the dashboard.
///
/// This is intentionally limited to the dashboard's project shelf. The
/// writing workspace keeps its information-dense layout, while this surface
/// gives the latest real project a cinematic entrance without inventing art
/// or project activity.
class CinematicProjectHero extends ConsumerWidget {
  const CinematicProjectHero({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectControllerProvider);
    return projects.when(
      loading: () => const _CinematicHeroFrame(
        eyebrow: 'Writing desk',
        title: 'Loading your next chapter',
        description: 'Your projects are being prepared.',
        actionLabel: 'Loading projects',
        actionEnabled: false,
      ),
      error: (_, _) => const _CinematicHeroFrame(
        eyebrow: 'Writing desk',
        title: 'Your projects could not be loaded',
        description: 'Open Projects to retry loading your writing library.',
        actionLabel: 'Open Projects',
        actionRoute: AppRoutes.projects,
      ),
      data: (items) {
        final recent = [...items]
          ..sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
        if (recent.isEmpty) {
          return const _CinematicHeroFrame(
            eyebrow: 'Writing desk',
            title: 'A place for your next chapter',
            description:
                'Start a novel and keep its characters, scenes, and world in one focused desk.',
            actionLabel: 'Create your first project',
            actionRoute: AppRoutes.createProject,
            emptyState: true,
          );
        }
        return _CinematicHeroFrame(project: recent.first);
      },
    );
  }
}

class _CinematicHeroFrame extends StatelessWidget {
  const _CinematicHeroFrame({
    this.project,
    this.eyebrow,
    this.title,
    this.description,
    this.actionLabel,
    this.actionRoute,
    this.actionEnabled = true,
    this.emptyState = false,
  });

  final ProjectModel? project;
  final String? eyebrow;
  final String? title;
  final String? description;
  final String? actionLabel;
  final String? actionRoute;
  final bool actionEnabled;
  final bool emptyState;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final activeProject = project;
    final resolvedEyebrow = eyebrow ?? 'Featured project';
    final resolvedTitle = title ?? activeProject?.name ?? 'Your next chapter';
    final resolvedDescription =
        description ?? activeProject?.description ?? 'Continue writing.';
    final resolvedAction = actionLabel ?? 'Continue writing';
    final route = actionRoute;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 600;
        final height = width >= 1000
            ? 390.0
            : width >= 600
            ? 330.0
            : 370.0;
        final horizontalPadding = compact ? 20.0 : 32.0;

        return Semantics(
          container: true,
          label: '$resolvedEyebrow: $resolvedTitle',
          child: SizedBox(
            key: const ValueKey('dashboard-cinematic-hero'),
            width: double.infinity,
            height: height,
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _HeroBackdrop(project: activeProject, emptyState: emptyState),
                  // The scrim exists only to keep foreground copy readable
                  // over real project artwork; it is not a page-wide glow.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                        colors: [
                          palette.background.withValues(alpha: 0.98),
                          palette.background.withValues(alpha: 0.76),
                          palette.background.withValues(alpha: 0.08),
                        ],
                        stops: const [0, 0.46, 1],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      compact ? 22 : 28,
                      horizontalPadding,
                      compact ? 24 : 32,
                    ),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: compact ? width - 40 : 680,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              resolvedEyebrow,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: palette.primaryBright),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              resolvedTitle,
                              maxLines: compact ? 3 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    color: palette.textPrimary,
                                    fontSize: compact ? 27 : 36,
                                    height: 1.08,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              resolvedDescription,
                              maxLines: compact ? 3 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: palette.textSecondary),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: !actionEnabled
                                  ? null
                                  : () {
                                      if (route != null) {
                                        context.go(route);
                                      } else if (activeProject != null) {
                                        _openProject(context, activeProject);
                                      }
                                    },
                              icon: Icon(
                                activeProject == null
                                    ? Icons.add
                                    : Icons.edit_outlined,
                              ),
                              label: Text(resolvedAction),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openProject(BuildContext context, ProjectModel project) {
    context.go('/studio/${Uri.encodeComponent(project.id)}');
  }
}

class _HeroBackdrop extends StatelessWidget {
  const _HeroBackdrop({required this.project, required this.emptyState});

  final ProjectModel? project;
  final bool emptyState;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return buildProjectThumbnail(
      project: project,
      fallback: _fallback(palette),
    );
  }

  Widget _fallback(VoidPalette palette) {
    return ColoredBox(
      color: palette.surfaceElevated,
      child: Align(
        alignment: emptyState ? Alignment.centerRight : Alignment.center,
        child: Icon(
          Icons.auto_stories_outlined,
          size: emptyState ? 260 : 220,
          color: palette.primary.withValues(alpha: 0.12),
        ),
      ),
    );
  }
}
