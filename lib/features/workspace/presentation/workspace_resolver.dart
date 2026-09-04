import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/selection/selection_controller.dart';
import '../../../core/selection/selection_model.dart';
import '../../projects/presentation/project_persistence_providers.dart';
import '../../assets/domain/asset_type.dart';
import '../../character/presentation/character_workspace_screen.dart';
import '../../wardrobe/presentation/wardrobe_workspace_screen.dart';
import '../../weapon/presentation/weapon_workspace_screen.dart';
import '../../environment/presentation/environment_workspace_screen.dart';
import '../../bible/application/create_lore_entity_service.dart';
import '../../story/application/create_story_service.dart';
import '../../story/data/story_repository_impl.dart';
import '../../project_resilience/application/durable_draft_journal.dart';
import '../../story/presentation/story_workspace_screen.dart';
import '../../workspaces/presentation/workspace_export_actions.dart';
import 'global_search_sheet.dart';
import '../../explorer/presentation/explorer_panel.dart';
import '../../workspaces/presentation/workspace_import_actions.dart';
import '../application/global_search_launcher.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';
import '../../../design_system/typography/void_typography.dart';

class WorkspaceResolver extends ConsumerWidget {
  const WorkspaceResolver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(selectionProvider);
    final session = ref.watch(projectSessionProvider).valueOrNull;
    final intent = ref.watch(workspaceIntentProvider);
    // Mount the catalog-recovery provider so pending typed navigation
    // restores its remembered selection once the catalog finishes loading.
    ref.watch(explorerCatalogRecoveryProvider);
    if (selection == null ||
        (session != null && selection.projectId != session.manifest.id)) {
      final type = intent?.$1 == session?.manifest.id ? intent?.$2 : null;
      if (session != null &&
          (type == AssetType.character || type == AssetType.environment)) {
        final character = type == AssetType.character;
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  character ? 'Character Workspace' : 'Worldbuilding Workspace',
                  style: VoidTypography.headingMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  character
                      ? 'Pilih karakter dari Explorer atau buat karakter pertama.'
                      : 'Pilih lokasi dari Explorer atau buat lokasi pertama.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      createExplorerAsset(context, ref, fixedType: type),
                  icon: Icon(
                    character
                        ? Icons.person_add_outlined
                        : Icons.add_location_alt_outlined,
                  ),
                  label: Text(character ? 'Buat Karakter' : 'Buat Lokasi'),
                ),
              ],
            ),
          ),
        );
      }
      return ProjectOverview(
        onCreateNovel: session == null
            ? null
            : (title) async {
                final service = CreateStoryService(
                  database: session.database,
                  paths: ref.read(projectPathsProvider),
                );
                final storyId = await service.createStory(
                  projectId: session.manifest.id,
                  title: title,
                );
                final chapterId = await service.createChapter(
                  storyId: storyId,
                  title: 'Chapter 1',
                  chapterNumber: 1,
                );
                await service.createScene(
                  storyId: storyId,
                  chapterId: chapterId,
                  title: 'Scene 1',
                  sceneNumber: 1,
                );
                ref
                    .read(selectionProvider.notifier)
                    .select(
                      SelectionModel(
                        assetId: storyId,
                        assetType: AssetType.story,
                        projectId: session.manifest.id,
                      ),
                    );
              },
        onOpenGlobalSearch: session == null
            ? null
            : (sheetContext) {
                showGlobalSearchSheet(
                  sheetContext,
                  launcher: GlobalSearchLauncher(database: session.database),
                  projectId: session.manifest.id,
                );
              },
      );
    }
    return switch (selection.assetType) {
      AssetType.character => CharacterWorkspaceScreen(
        characterId: selection.assetId,
      ),
      AssetType.wardrobe => WardrobeWorkspaceScreen(
        wardrobeId: selection.assetId,
      ),
      AssetType.weapon => WeaponWorkspaceScreen(weaponId: selection.assetId),
      AssetType.environment => EnvironmentWorkspaceScreen(
        environmentId: selection.assetId,
      ),
      AssetType.story => StoryWorkspaceScreen(
        storyId: selection.assetId,
        draftJournal: session == null
            ? null
            : DurableDraftJournal(
                dir: Directory(
                  '${session.package.root.path}/recovery/draft-journal',
                ),
              ),
        repository: session == null
            ? null
            : StoryRepositoryImpl(
                database: session.database,
                projectId: session.manifest.id,
              ),
        loadLoreCatalog: session == null
            ? null
            : () {
                final s = session;
                return const CreateLoreEntityService().loadCatalog(
                  s.database,
                  s.manifest.id,
                );
              },
        onCreateLoreEntity: session == null
            ? null
            : (name) {
                final s = session;
                return const CreateLoreEntityService().create(
                  s.database,
                  projectId: s.manifest.id,
                  name: name,
                );
              },
        exportDirectory: session?.package.exportDirectory,
        novelExportActions: session == null
            ? null
            : WorkspaceExportActions(
                package: session.package,
                links: session.novelCharacterLinks,
              ),
        novelImportActions: session == null
            ? null
            : WorkspaceImportActions(
                package: session.package,
                links: session.novelCharacterLinks,
              ),
        workspaceProjection: session?.workspaceProjectionReader.forNovel(
          selection.assetId,
        ),
      ),
      _ => const ProjectOverview(),
    };
  }
}

class ProjectOverview extends StatelessWidget {
  const ProjectOverview({
    super.key,
    this.onCreateNovel,
    this.onOpenGlobalSearch,
  });

  final Future<void> Function(String title)? onCreateNovel;
  final void Function(BuildContext context)? onOpenGlobalSearch;

  Future<void> _createNovel(BuildContext context) async {
    var title = '';
    final submitted = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Novel'),
        content: TextField(
          autofocus: true,
          onChanged: (value) => title = value.trim(),
          decoration: const InputDecoration(labelText: 'Novel title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (title.isNotEmpty) Navigator.pop(dialogContext, title);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (submitted == null || onCreateNovel == null) return;
    await onCreateNovel!(submitted);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Novel created.')));
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Novel Workspace', style: VoidTypography.headingMedium),
        const SizedBox(height: 8),
        Text(
          'Select an asset from Explorer to open its workspace.',
          style: TextStyle(color: context.palette.textMuted),
        ),
        if (onCreateNovel != null) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _createNovel(context),
            icon: const Icon(Icons.auto_stories_outlined),
            label: const Text('Create Novel'),
          ),
        ],
        if (onOpenGlobalSearch != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => onOpenGlobalSearch!(context),
            icon: const Icon(Icons.search),
            label: const Text('Cari di Proyek'),
          ),
        ],
      ],
    ),
  );
}

void selectAsset(WidgetRef ref, SelectionModel selection) {
  ref.read(selectionProvider.notifier).select(selection);
}
