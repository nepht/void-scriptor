import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../../design_system/colors/void_colors.dart';
import '../../../design_system/typography/void_typography.dart';
import '../../../design_system/widgets/void_button.dart';
import 'project_controller.dart';

class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});

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
      final directory = await getApplicationDocumentsDirectory();
      final project = await ref
          .read(projectControllerProvider.notifier)
          .createProject(
            name: name,
            description: _descriptionController.text.trim(),
            localPath: '${directory.path}/VoidScriptor/Projects',
          );
      ref.read(currentProjectProvider.notifier).state = project;
      if (mounted) context.go('/studio/${project.id}');
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoidColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: VoidColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: VoidColors.borderSoft),
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
                        onPressed: _creating ? null : () => context.pop(),
                        child: const Text('Cancel'),
                      ),
                      const Spacer(),
                      VoidButton(
                        label: _creating ? 'Creating...' : 'Create Project',
                        icon: Icons.add,
                        onPressed: _creating ? null : _create,
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
