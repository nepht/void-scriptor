import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routing/app_routes.dart';
import '../../../design_system/colors/void_colors.dart';
import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'project_controller.dart';
import 'widgets/project_card.dart';
import 'widgets/project_empty_state.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectControllerProvider);
    return Scaffold(
      backgroundColor: VoidColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(VoidSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Projects', style: VoidTypography.displayMedium),
                        SizedBox(height: 6),
                        Text(
                          'Create and manage your universes.',
                          style: VoidTypography.body,
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => context.go(AppRoutes.createProject),
                    icon: const Icon(Icons.add),
                    label: const Text('New Project'),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Expanded(
                child: projects.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('$error')),
                  data: (items) {
                    if (items.isEmpty) return const ProjectEmptyState();
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        var columns = 1;
                        if (constraints.maxWidth >= 1600) {
                          columns = 4;
                        } else if (constraints.maxWidth >= 1100) {
                          columns = 3;
                        } else if (constraints.maxWidth >= 700) {
                          columns = 2;
                        }
                        return GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.55,
                              ),
                          itemCount: items.length,
                          itemBuilder: (context, index) =>
                              ProjectCard(project: items[index]),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
