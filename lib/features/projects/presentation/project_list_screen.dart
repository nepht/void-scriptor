import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routing/app_routes.dart';
import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import '../../platform/domain/platform_capability.dart';
import '../../platform/platform_capability_providers.dart';
import '../domain/project_model.dart';
import 'project_controller.dart';
import 'widgets/project_card.dart';
import 'widgets/project_empty_state.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectControllerProvider);
    return Scaffold(
      backgroundColor: context.palette.background,
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
                          itemBuilder: (context, index) => ProjectCard(
                            project: items[index],
                            onDelete: () =>
                                _confirmDelete(context, ref, items[index]),
                            onMove:
                                ref
                                    .watch(platformCapabilitiesProvider)
                                    .supports(
                                      PlatformCapability.localFileSystem,
                                    )
                                ? (project) => _startMove(context, ref, project)
                                : null,
                          ),
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

  /// Wiring sprint Task 3: folder picker for the move trigger; a cancelled
  /// picker is a no-op, a failed move keeps the project where it was and the
  /// typed reason surfaces in the snack bar.
  ///
  /// vs-hunt-20260911 BUG-8: the capability check happens BEFORE the native
  /// picker opens (check-first pattern, mirroring ProjectController
  /// createProject), and the card only exposes the action when the
  /// relocation host is present.
  Future<void> _startMove(
    BuildContext context,
    WidgetRef ref,
    ProjectModel project,
  ) async {
    try {
      ref
          .read(platformCapabilitiesProvider)
          .require(
            PlatformCapability.localFileSystem,
            action: 'Memindahkan proyek',
          );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
      return;
    }
    // file_selector ^1.x getDirectoryPath has no label parameter.
    final destinationPath = await getDirectoryPath();
    if (destinationPath == null || !context.mounted) return;
    try {
      final moved = await ref
          .read(projectControllerProvider.notifier)
          .moveProject(
            projectId: project.id,
            destinationRoot: Directory(destinationPath),
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Proyek dipindah ke ${moved.path}')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat memindah proyek: $error')),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ProjectModel project,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteProjectDialog(project: project),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(projectControllerProvider.notifier)
          .deleteProject(project.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project removed. Local files were kept.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete project: $error')),
      );
    }
  }
}

class _DeleteProjectDialog extends StatefulWidget {
  const _DeleteProjectDialog({required this.project});

  final ProjectModel project;

  @override
  State<_DeleteProjectDialog> createState() => _DeleteProjectDialogState();
}

class _DeleteProjectDialogState extends State<_DeleteProjectDialog> {
  final _confirmationController = TextEditingController();

  bool get _matchesProjectName =>
      _confirmationController.text == widget.project.name;

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    return AlertDialog(
      title: const Text('Delete Project'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This removes "${project.name}" from Void Scriptor. '
                'Local files at ${project.localPath} will be kept for recovery.',
              ),
              const SizedBox(height: 16),
              Text('Type "${project.name}" to confirm.'),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmationController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Project name'),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (_matchesProjectName) Navigator.of(context).pop(true);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('confirm-delete-project-button'),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _matchesProjectName
              ? () => Navigator.of(context).pop(true)
              : null,
          child: const Text('Delete Project'),
        ),
      ],
    );
  }
}
