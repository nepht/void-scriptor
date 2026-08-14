import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../design_system/colors/void_colors.dart';
import '../../projects/presentation/project_persistence_providers.dart';
import '../application/create_story_service.dart';
import '../data/story_repository_impl.dart';
import 'scene_beat_editor.dart';
import '../../timeline/domain/timeline_model.dart';
import '../../timeline/application/create_timeline_service.dart';
import '../../timeline/application/move_timeline_clip_command.dart';
import '../../timeline/presentation/timeline_workspace_screen.dart';
import '../../scene_assets/application/scene_asset_instance_repository.dart';
import '../../scene_assets/domain/scene_asset_instance.dart';
import '../../scene_assets/presentation/scene_asset_panel.dart';
import '../../../app/routing/app_routes.dart';

final sceneWorkspaceProvider = FutureProvider.family<StorySceneNode?, String>((
  ref,
  sceneId,
) async {
  final session = ref.watch(projectSessionProvider).valueOrNull;
  if (session == null) return null;
  return StoryRepositoryImpl(
    database: session.database,
    projectId: session.manifest.id,
  ).getScene(sceneId);
});

final sceneAssetInstancesProvider =
    FutureProvider.family<List<SceneAssetInstanceModel>, String>((
      ref,
      sceneId,
    ) async {
      final session = ref.watch(projectSessionProvider).valueOrNull;
      if (session == null) return const [];
      return SceneAssetInstanceRepository(
        session.database,
      ).instancesForScene(sceneId);
    });

class SceneWorkspaceScreen extends ConsumerStatefulWidget {
  const SceneWorkspaceScreen({
    super.key,
    required this.sceneId,
    this.title = 'Scene',
  });
  final String sceneId;
  final String title;
  @override
  ConsumerState<SceneWorkspaceScreen> createState() =>
      _SceneWorkspaceScreenState();
}

class _SceneWorkspaceScreenState extends ConsumerState<SceneWorkspaceScreen> {
  Future<void> _openTimeline() async {
    final session = ref.read(projectSessionProvider).valueOrNull;
    if (session == null || !mounted) return;
    final service = CreateTimelineService(database: session.database);
    final timelineId = await service.ensureTimelineForScene(
      projectId: session.manifest.id,
      sceneId: widget.sceneId,
    );
    final timeline = await session.database.timelineDao.getTimeline(timelineId);
    final tracks = await service.getTracks(timelineId);
    final trackTypes = {for (final track in tracks) track.id: track.trackType};
    final clips = (await service.getClips(timelineId))
        .map(
          (clip) => TimelineClipModel(
            id: clip.id,
            trackId: trackTypes[clip.trackId] ?? 'action',
            startSeconds: clip.startSeconds,
            durationSeconds: clip.durationSeconds,
            label: clip.label,
            sourceId: clip.sourceId,
            clipType: clip.clipType,
            payload: clip.payload,
          ),
        )
        .toList();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TimelineWorkspaceScreen(
          sceneId: widget.sceneId,
          sceneTitle: widget.title,
          durationSeconds: timeline?.durationSeconds ?? 10,
          clips: clips,
          onClipTimingChanged: (previous, clip) {
            return session.mutationRuntime.bus.execute(
              MoveTimelineClipCommand(
                id: const Uuid().v4(),
                projectId: session.manifest.id,
                timelineService: service,
                clipId: clip.id,
                oldStartSeconds: previous.startSeconds,
                newStartSeconds: clip.startSeconds,
                durationSeconds: clip.durationSeconds,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _addBeat() async {
    final content = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Beat'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Content'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (content == null || content.isEmpty) return;
    final session = ref.read(projectSessionProvider).valueOrNull;
    if (session == null) return;
    await CreateStoryService(
      database: session.database,
      paths: ref.read(projectPathsProvider),
    ).addBeat(sceneId: widget.sceneId, content: content);
    ref.invalidate(sceneWorkspaceProvider(widget.sceneId));
  }

  Future<void> _deleteBeat(SceneBeatEditorItem beat) async {
    final session = ref.read(projectSessionProvider).valueOrNull;
    if (session == null) return;
    await CreateStoryService(
      database: session.database,
      paths: ref.read(projectPathsProvider),
    ).deleteBeat(beat.id);
    ref.invalidate(sceneWorkspaceProvider(widget.sceneId));
  }

  Future<void> _reorderBeats(List<SceneBeatEditorItem> ordered) async {
    final session = ref.read(projectSessionProvider).valueOrNull;
    if (session == null) return;
    await CreateStoryService(
      database: session.database,
      paths: ref.read(projectPathsProvider),
    ).reorderBeats(
      sceneId: widget.sceneId,
      orderedIds: ordered.map((beat) => beat.id).toList(),
    );
    ref.invalidate(sceneWorkspaceProvider(widget.sceneId));
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(sceneWorkspaceProvider(widget.sceneId)).valueOrNull;
    final beats =
        data?.beats
            .map(
              (beat) => SceneBeatEditorItem(
                id: beat.id,
                content: beat.content,
                beatType: beat.beatType,
                startSecond: beat.startSecond,
                durationSeconds: beat.durationSeconds,
              ),
            )
            .toList() ??
        const <SceneBeatEditorItem>[];
    final environment = data?.environment;
    final sceneAssets =
        ref.watch(sceneAssetInstancesProvider(widget.sceneId)).valueOrNull ??
        const <SceneAssetInstanceModel>[];
    final total = beats.fold<double>(
      0,
      (sum, beat) => sum + (beat.durationSeconds ?? 0),
    );
    return ColoredBox(
      color: VoidColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scene — ${widget.title}',
              style: const TextStyle(
                color: VoidColors.textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              beats.isEmpty
                  ? 'Duration not set'
                  : '${total.toStringAsFixed(1)} sec of beats',
              style: const TextStyle(color: VoidColors.textMuted),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _openTimeline,
              icon: const Icon(Icons.timeline_outlined),
              label: const Text('Open Timeline'),
            ),
            const SizedBox(height: 18),
            _Section(
              title: 'ENVIRONMENT',
              children: [
                Text(environment?.environmentId ?? 'Environment not linked'),
                Text(environment?.zoneId ?? 'Zone not linked'),
                Text(environment?.weatherProfileId ?? 'Weather not linked'),
                Text(environment?.lightingProfileId ?? 'Lighting not linked'),
              ],
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'CHARACTERS',
              children: [
                if (data == null || data.characters.isEmpty)
                  const Text('No scene characters yet')
                else
                  ...data.characters.map(
                    (character) => Text(
                      '${character.characterId} — ${character.modeId ?? 'Base Mode'} (${character.role})',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SceneAssetPanel(
              groups: {
                'Characters': sceneAssets
                    .where((item) => item.assetType == SceneAssetType.character)
                    .map((item) => item.assetId)
                    .toList(),
                'Creatures': sceneAssets
                    .where((item) => item.assetType == SceneAssetType.creature)
                    .map((item) => item.assetId)
                    .toList(),
                'Vehicles': sceneAssets
                    .where((item) => item.assetType == SceneAssetType.vehicle)
                    .map((item) => item.assetId)
                    .toList(),
                'Props': sceneAssets
                    .where((item) => item.assetType == SceneAssetType.prop)
                    .map((item) => item.assetId)
                    .toList(),
                'Environment': [
                  if (environment?.environmentId != null)
                    environment!.environmentId,
                ],
              },
              onAddAsset: () => context.push(AppRoutes.assets),
            ),
            const SizedBox(height: 12),
            Card(
              color: VoidColors.panel,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ACTION BEATS',
                      style: TextStyle(
                        color: VoidColors.primaryBright,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (beats.isEmpty)
                      const Text(
                        'No beats yet',
                        style: TextStyle(color: VoidColors.textSecondary),
                      ),
                    if (beats.isNotEmpty)
                      SceneBeatEditor(
                        beats: beats,
                        onReordered: _reorderBeats,
                        onDelete: _deleteBeat,
                      ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _addBeat,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Beat'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _Section(
              title: 'CONTINUITY',
              children: [Text('No continuity changes yet')],
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
    color: VoidColors.panel,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: VoidColors.primaryBright,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          DefaultTextStyle(
            style: const TextStyle(
              color: VoidColors.textSecondary,
              height: 1.6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    ),
  );
}
