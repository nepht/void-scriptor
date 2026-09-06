import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../platform/domain/platform_capability.dart';
import '../../platform/platform_capability_providers.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/typography/void_typography.dart';
import '../../../design_system/widgets/void_button.dart';
import '../domain/project_model.dart';
import 'project_controller.dart';
import 'project_persistence_providers.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';
import '../../../app/routing/app_routes.dart';

typedef CreateProjectAction =
    Future<ProjectModel> Function({
      required String name,
      required String description,
    });

class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key, this.onCreateProject});

  final CreateProjectAction? onCreateProject;

  @override
  ConsumerState<CreateProjectScreen> createState() =>
      _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project name is required.')),
      );
      return;
    }

    setState(() => _creating = true);
    try {
      final description = _descriptionController.text.trim();
      final action = widget.onCreateProject;
      final project = action != null
          ? await action(name: name, description: description)
          : await _createPersistentProject(name, description);
      ref.read(currentProjectProvider.notifier).state = project;
      if (mounted) context.go('/studio/${project.id}');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create project: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<ProjectModel> _createPersistentProject(
    String name,
    String description,
  ) async {
    final projectRoot = await ref.read(projectPathsProvider).root();
    return ref
        .read(projectControllerProvider.notifier)
        .createProject(
          name: name,
          description: description,
          localPath: projectRoot.path,
        );
  }

  @override
  Widget build(BuildContext context) {
    final capabilities = ref.watch(platformCapabilitiesProvider);
    final canCreate = capabilities.supports(PlatformCapability.localFileSystem);
    return Scaffold(
      backgroundColor: context.palette.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: context.palette.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.palette.borderSoft),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Create Project',
                    style: VoidTypography.headingLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create a new universe workspace.',
                    style: VoidTypography.body,
                  ),
                  const SizedBox(height: 26),
                  if (!canCreate) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.palette.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.palette.borderSoft),
                      ),
                      child: Text(
                        capabilities.unsupportedMessageFor(
                          PlatformCapability.localFileSystem,
                          action: 'Membuat proyek baru',
                        ),
                        style: VoidTypography.body,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Project name',
                      hintText: 'Void Universe',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe this universe...',
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _creating
                            ? null
                            : () => context.go(AppRoutes.projects),
                        child: const Text('Cancel'),
                      ),
                      const Spacer(),
                      VoidButton(
                        label: _creating ? 'Creating...' : 'Create Project',
                        icon: Icons.add,
                        onPressed: _creating || !canCreate ? null : _create,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
