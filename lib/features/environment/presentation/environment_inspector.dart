import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors/void_colors.dart';
import '../../projects/presentation/project_persistence_providers.dart';
import '../data/environment_repository_impl.dart';

final environmentInspectorProvider = FutureProvider.family<String?, String>((
  ref,
  environmentId,
) async {
  final session = ref.watch(projectSessionProvider).valueOrNull;
  if (session == null) return null;
  return (await EnvironmentRepositoryImpl(
    database: session.database,
    projectId: session.manifest.id,
  ).getEnvironment(environmentId))?.name;
});

class EnvironmentInspector extends ConsumerWidget {
  const EnvironmentInspector({super.key, required this.environmentId});
  final String environmentId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref
        .watch(environmentInspectorProvider(environmentId))
        .valueOrNull;
    return Container(
      color: VoidColors.panel,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              model ?? environmentId,
              style: const TextStyle(
                color: VoidColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Text(
              'Environment',
              style: TextStyle(color: VoidColors.textMuted),
            ),
            const SizedBox(height: 20),
            const Text(
              'SCENE CONTEXT',
              style: TextStyle(
                color: VoidColors.primaryBright,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Lighting, weather, zones, continuity, and physics are stored in the project database.',
              style: TextStyle(color: VoidColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
