import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';
import 'package:void_scriptor/features/story/domain/story_model.dart';

final storyInspectorProvider = FutureProvider.family<StoryModel?, String>((
  ref,
  storyId,
) async {
  final session = await ref.watch(projectSessionProvider.future);
  if (session == null) return null;
  return (await StoryRepositoryImpl(
    database: session.database,
    projectId: session.manifest.id,
  ).getStoryHierarchy(storyId)).story;
});

class StoryInspector extends ConsumerWidget {
  const StoryInspector({super.key, required this.storyId});
  final String storyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final story = ref.watch(storyInspectorProvider(storyId)).valueOrNull;
    final title = story?.title ?? storyId;
    final status = story?.status.isNotEmpty == true ? story!.status : 'Draft';
    final synopsis = story?.synopsis;
    return ColoredBox(
      color: context.palette.panel,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.palette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Story · $storyId',
                style: TextStyle(color: context.palette.textMuted),
              ),
              const Divider(),
              Text(
                'Status\n$status',
                style: TextStyle(
                  color: context.palette.textSecondary,
                  height: 1.5,
                ),
              ),
              if (synopsis != null && synopsis.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  synopsis,
                  style: TextStyle(color: context.palette.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
