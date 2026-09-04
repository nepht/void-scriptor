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
import '../../bible/application/bible_timeline_repository.dart';
import '../../bible/application/create_faction_service.dart';
import '../../bible/application/create_lore_entity_service.dart';
import '../../bible/application/faction_repository.dart';
import '../../bible/domain/faction.dart' as domain;
import '../../bible/domain/timeline_era.dart' as era;
import '../../story/domain/lore_link_suggester.dart';
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
    ref.watch(selectionMemoryPersistenceProvider);
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
      if (session != null && _isWorldbuildingIntent(type)) {
        return WorldbuildingBody(
          key: ValueKey('wb-${session.manifest.id}'),
          assetType: type,
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
      AssetType.faction ||
      AssetType.timeline ||
      AssetType.creature ||
      AssetType.species ||
      AssetType.technology ||
      AssetType.powerSystem => WorldbuildingBody(
        key: ValueKey('wb-${selection.projectId ?? ''}'),
        assetId: selection.assetId,
        assetType: selection.assetType,
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

bool _isWorldbuildingIntent(AssetType? type) => switch (type) {
  AssetType.environment ||
  AssetType.faction ||
  AssetType.timeline ||
  AssetType.creature ||
  AssetType.species ||
  AssetType.technology ||
  AssetType.powerSystem => true,
  _ => false,
};

/// Body workspace worldbuilding nyata: menampilkan data proyek
/// (faksi, era timeline, entri lore) alih-alih fallback Novel.
class WorldbuildingBody extends ConsumerStatefulWidget {
  const WorldbuildingBody({super.key, this.assetId, this.assetType});

  final String? assetId;
  final AssetType? assetType;

  @override
  ConsumerState<WorldbuildingBody> createState() => _WorldbuildingBodyState();
}

class _WorldbuildingBodyState extends ConsumerState<WorldbuildingBody> {
  List<domain.FactionModel>? _factions;
  List<era.TimelineEraModel>? _eras;
  List<LoreEntityRef>? _lore;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    // Body bisa ter-mount saat session masih loading (selection tersedia
    // lebih dulu). Muat begitu session siap, tanpa kehilangan data awal.
    ref.listenManual(projectSessionProvider, (previous, next) {
      if (next.valueOrNull != null && _factions == null && !_loading) {
        _load();
      }
    }, fireImmediately: true);
  }

  Future<void> _load() async {
    final session = ref.read(projectSessionProvider).valueOrNull;
    if (session == null) return;
    final projectId = session.manifest.id;
    final db = session.database;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final factions = await FactionRepository(db).listForProject(projectId);
      final eras = await BibleTimelineRepository(db).listEras(projectId);
      final lore = await const CreateLoreEntityService().loadCatalog(
        db,
        projectId,
      );
      if (!mounted) return;
      setState(() {
        _factions = factions;
        _eras = eras;
        _lore = lore;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  Future<void> _createFaction() async {
    final session = ref.read(projectSessionProvider).valueOrNull;
    if (session == null) return;
    var name = '';
    final submitted = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Faction'),
        content: TextField(
          autofocus: true,
          onChanged: (value) => name = value.trim(),
          decoration: const InputDecoration(labelText: 'Faction name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (name.isNotEmpty) Navigator.pop(dialogContext, name);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (submitted == null) return;
    try {
      final faction = await const CreateFactionService().create(
        session.database,
        projectId: session.manifest.id,
        name: submitted,
      );
      if (!mounted) return;
      ref
          .read(selectionProvider.notifier)
          .select(
            SelectionModel(
              assetId: faction.assetId,
              assetType: AssetType.faction,
              projectId: session.manifest.id,
            ),
          );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faksi gagal dibuat. Coba lagi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final selectedId = ref.watch(selectionProvider)?.assetId;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Worldbuilding Workspace',
                      style: VoidTypography.headingMedium,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _createFaction,
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('Create Faction'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null) ...[
                Text(
                  'Gagal memuat data worldbuilding.',
                  style: TextStyle(color: palette.textSecondary),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _load,
                  child: const Text('Muat ulang'),
                ),
              ] else ...[
                _WorldSection(
                  title: 'Factions',
                  emptyLabel: 'Belum ada faksi. Buat faksi pertama.',
                  items: [
                    for (final faction in _factions ?? const [])
                      _WorldItem(
                        id: faction.assetId,
                        title: faction.name,
                        subtitle: faction.ideology.trim(),
                        selected: selectedId == faction.assetId,
                        onTap: () =>
                            _selectAsset(faction.assetId, AssetType.faction),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _WorldSection(
                  title: 'Timeline',
                  emptyLabel: 'Belum ada era pada timeline proyek ini.',
                  items: [
                    for (final eraItem in _eras ?? const [])
                      _WorldItem(
                        id: eraItem.id,
                        title: eraItem.name,
                        subtitle: eraItem.description.trim(),
                        selected: selectedId == eraItem.id,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _WorldSection(
                  title: 'Lore Notes',
                  emptyLabel: 'Belum ada entri lore pada proyek ini.',
                  items: [
                    for (final entry in _lore ?? const [])
                      _WorldItem(
                        id: entry.id,
                        title: entry.name,
                        subtitle: entry.kind,
                        selected: selectedId == entry.id,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _selectAsset(String assetId, AssetType assetType) {
    final session = ref.read(projectSessionProvider).valueOrNull;
    if (session == null) return;
    ref
        .read(selectionProvider.notifier)
        .select(
          SelectionModel(
            assetId: assetId,
            assetType: assetType,
            projectId: session.manifest.id,
          ),
        );
  }
}

class _WorldSection extends StatelessWidget {
  const _WorldSection({
    required this.title,
    required this.emptyLabel,
    required this.items,
  });

  final String title;
  final String emptyLabel;
  final List<_WorldItem> items;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.panel,
        border: Border.all(color: palette.borderSoft),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: VoidTypography.title),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(emptyLabel, style: TextStyle(color: palette.textMuted))
          else
            for (final item in items) item,
        ],
      ),
    );
  }
}

class _WorldItem extends StatelessWidget {
  const _WorldItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.selected = false,
    this.onTap,
  });

  final String id;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // Material transparan: ListTile butuh Material ancestor agar ink
    // splash terlihat (section memakai DecoratedBox ber-background).
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        selected: selected,
        leading: const Icon(Icons.public_outlined, size: 18),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: subtitle.isEmpty
            ? null
            : Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: palette.textMuted, fontSize: 12),
              ),
        onTap: onTap,
      ),
    );
  }
}

void selectAsset(WidgetRef ref, SelectionModel selection) {
  ref.read(selectionProvider.notifier).select(selection);
}
