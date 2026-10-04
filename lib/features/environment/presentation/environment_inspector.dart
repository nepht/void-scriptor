import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../projects/presentation/project_persistence_providers.dart';
import '../data/environment_repository_impl.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

final environmentInspectorProvider = FutureProvider.family<String?, String>((
  ref,
  environmentId,
) async {
  final session = ref.watch(projectSessionProvider).value;
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
        .value;
    return Container(
      color: context.palette.panel,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              model ?? environmentId,
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Environment',
              style: TextStyle(color: context.palette.textMuted),
            ),
            const SizedBox(height: 20),
            Text(
              'SCENE CONTEXT',
              style: TextStyle(
                color: context.palette.primaryBright,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Lighting, weather, zones, continuity, and physics are stored in the project database.',
              style: TextStyle(color: context.palette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
