import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/selection/selection_controller.dart';
import '../../../core/selection/selection_model.dart';
import '../../projects/presentation/project_persistence_providers.dart';
import '../../assets/domain/asset_type.dart';
import '../../assets/presentation/supporting_asset_workspace_screen.dart';
import '../../character/presentation/character_workspace_screen.dart';
import '../../character_mode/presentation/character_mode_controller.dart';
import '../../creatures/presentation/creature_workspace_screen.dart';
import '../../wardrobe/presentation/wardrobe_workspace_screen.dart';
import '../../weapon/presentation/weapon_workspace_screen.dart';
import '../../environment/presentation/environment_workspace_screen.dart';
import '../../bible/application/bible_timeline_repository.dart';
import '../../bible/application/create_faction_service.dart';
import '../../bible/application/create_lore_entity_service.dart';
import '../../environment/data/environment_repository_impl.dart';
import '../../environment/domain/environment_model.dart';
import '../../relations/application/character_relation_map_service.dart';
import '../../bible/application/faction_repository.dart';
import '../../bible/domain/faction.dart' as domain;
import '../../bible/domain/timeline_era.dart' as era;
import '../../story/domain/lore_link_suggester.dart';
import '../../story/application/create_story_service.dart';
import '../../story/data/story_repository_impl.dart';
import '../../project_resilience/application/durable_draft_journal.dart';
import '../../story/presentation/story_workspace_screen.dart';
import '../../project_resilience/application/project_session_manager.dart';
import '../../workspaces/application/create_novel_character_link_service.dart';
import '../../workspaces/application/workspace_projection_cache.dart';
import '../../workspaces/presentation/workspace_export_actions.dart';
import 'global_search_sheet.dart';
import '../../explorer/presentation/explorer_panel.dart';
import '../../workspaces/presentation/workspace_import_actions.dart';
import '../application/global_search_launcher.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';
import '../../../design_system/typography/void_typography.dart';

class WorkspaceResolver extends ConsumerWidget {
  const WorkspaceResolver({
    super.key,
    this.activeSection,
    this.onSectionRequested,
  });

  final String? activeSection;
  final ValueChanged<String>? onSectionRequested;

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
          activeSection: activeSection,
        );
      }
      if (session != null && type == AssetType.creature) {
        // BUG-05 (hunt-20260910): intent creature tanpa selection tidak boleh
        // jatuh ke WorldbuildingBody generik (header panel mengiklankan
        // "Creature Workspace" dengan tab Profile/Anatomy/Abilities yang
        // merender kosong). explorerCatalogRecoveryProvider memulihkan
        // selection creature dari memori/katalog; widget ini menampilkan
        // keadaan yang jujur: recovery/loading, error, atau kosong dengan
        // aksi create nyata.
        return _CreatureEmptyState(projectId: session.manifest.id);
      }
      return ProjectOverview(
        activeSection: activeSection,
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
                // New novels must be selectable as narrative/support story
                // context without an unrelated action rebuilding the asset
                // graph (hunt-run157 BUG-05, Referee REAL BUG Medium).
                ref.invalidate(projectAssetsProvider);
              },
        onOpenGlobalSearch: session == null
            ? null
            : (sheetContext) {
                showGlobalSearchSheet(
                  sheetContext,
                  launcher: GlobalSearchLauncher(database: session.database),
                  projectId: session.manifest.id,
                  // BUG-02 (hunt-20260910): a faction hit has no Assets row and
                  // no typed AssetType, so the sheet routes it through this
                  // callback; write the same typed faction SelectionModel the
                  // Explorer writes so the resolver opens the faction branch.
                  onSelectFaction: (factionId, factionName) {
                    ref
                        .read(selectionProvider.notifier)
                        .select(
                          SelectionModel(
                            assetId: factionId,
                            assetType: AssetType.faction,
                            projectId: session.manifest.id,
                          ),
                        );
                  },
                );
              },
      );
    }
    return switch (selection.assetType) {
      AssetType.character => CharacterWorkspaceScreen(
        characterId: selection.assetId,
        activeSection: activeSection,
      ),
      AssetType.wardrobe => WardrobeWorkspaceScreen(
        wardrobeId: selection.assetId,
      ),
      AssetType.weapon => WeaponWorkspaceScreen(weaponId: selection.assetId),
      AssetType.armor ||
      AssetType.accessory ||
      AssetType.prop ||
      AssetType.vehicle => SupportingAssetWorkspaceScreen(
        // BUG-09 (hunt run165): vehicle producible via Asset Browser create +
        // search sheet; tanpa case ini selection vehicle dead-end ke overview
        // tanpa callback. Layar supporting-asset bersifat data-driven.
        assetId: selection.assetId,
        activeSection: activeSection,
      ),
      AssetType.environment =>
        _opensWorldbuildingCollection(activeSection)
            ? WorldbuildingBody(
                key: ValueKey('wb-${selection.projectId ?? ''}'),
                assetId: selection.assetId,
                assetType: selection.assetType,
                activeSection: activeSection,
              )
            : EnvironmentWorkspaceScreen(environmentId: selection.assetId),
      AssetType.creature => CreatureWorkspaceScreen(
        creatureId: selection.assetId,
        activeSection: activeSection,
      ),
      AssetType.faction ||
      AssetType.timeline ||
      AssetType.species ||
      AssetType.technology ||
      AssetType.powerSystem => WorldbuildingBody(
        key: ValueKey('wb-${selection.projectId ?? ''}'),
        assetId: selection.assetId,
        assetType: selection.assetType,
        activeSection: activeSection,
      ),
      AssetType.story => StoryWorkspaceScreen(
        // bug-hunt-run128 BUG-22: story -> story pada element yang sama
        // memakai ulang State layar story (draft scene/journal basi). Key per
        // story memaksa State baru - pola sama dengan key 'wb-<projectId>'.
        key: ValueKey('story-${selection.assetId}'),
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
        onTapAddCharacter: session == null
            ? null
            : (novelWorkspaceId) =>
                  _linkCharacterToNovel(context, session, novelWorkspaceId),
        activeSection: activeSection,
        onSectionRequested: onSectionRequested,
      ),
      _ => const ProjectOverview(),
    };
  }
}

bool _opensWorldbuildingCollection(String? section) => switch (section) {
  'Factions' || 'Relationships' || 'Timeline' || 'Lore Notes' => true,
  _ => false,
};

class ProjectOverview extends StatelessWidget {
  const ProjectOverview({
    super.key,
    this.activeSection,
    this.onCreateNovel,
    this.onOpenGlobalSearch,
  });

  final String? activeSection;

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
    // hunt run165 BUG-04 (Referee REAL BUG Medium): persist failure tidak
    // boleh lepas ke global zone handler tanpa feedback - pola yang sama
    // dengan _createFaction di bawah.
    try {
      await onCreateNovel!(submitted);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Novel gagal dibuat. Coba lagi.')),
      );
      return;
    }
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
        // Friksi #4 native journey 145.43: tab Outline tanpa aset terpilih
        // tidak boleh mati total - tunjukkan struktur yang akan dibuat dan
        // arahkan ke novel pertama lewat aksi Create Novel yang sama.
        if (activeSection == 'Outline' || activeSection == 'Planning') ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.palette.panel,
              border: Border.all(color: context.palette.borderSoft),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('STORY STRUCTURE'),
                SizedBox(height: 8),
                Text('Story → Arc → Chapter → Scene'),
                SizedBox(height: 8),
                Text(
                  'Pilih novel dari Explorer untuk membuka Outline, '
                  'atau buat novel pertama di bawah - bab dan adegan awal '
                  'dibuat otomatis.',
                ),
              ],
            ),
          ),
        ],
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

/// Typed creature empty-state untuk intent creature tanpa selection
/// (BUG-05, hunt-20260910). Menampilkan keadaan katalog yang jujur:
/// memuat (menunggu recovery), gagal (dengan retry), kosong (dengan aksi
/// create nyata), atau memulihkan selection yang diingat dari katalog.
class _CreatureEmptyState extends ConsumerWidget {
  const _CreatureEmptyState({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(creatureExplorerProvider(projectId));
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Creature Workspace',
              style: VoidTypography.headingMedium,
            ),
            const SizedBox(height: 8),
            switch (catalog) {
              AsyncLoading() => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(),
              ),
              AsyncData(:final value) when value.isEmpty => const Text(
                'Belum ada creature di proyek ini. Buat creature '
                'pertama dari Explorer atau tombol di bawah.',
                textAlign: TextAlign.center,
              ),
              AsyncError() => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Katalog creature gagal dimuat.'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () =>
                        ref.invalidate(creatureExplorerProvider(projectId)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba lagi'),
                  ),
                ],
              ),
              _ => const SizedBox.shrink(),
            },
            if (!catalog.isLoading && catalog is! AsyncError) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => createExplorerAsset(
                  context,
                  ref,
                  fixedType: AssetType.creature,
                ),
                icon: const Icon(Icons.pets_outlined),
                label: const Text('Buat Creature'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

bool _isWorldbuildingIntent(AssetType? type) => switch (type) {
  AssetType.environment ||
  AssetType.faction ||
  AssetType.timeline ||
  AssetType.species ||
  AssetType.technology ||
  AssetType.powerSystem => true,
  _ => false,
};

/// Body workspace worldbuilding nyata: menampilkan data proyek
/// (faksi, era timeline, entri lore) alih-alih fallback Novel.
class WorldbuildingBody extends ConsumerStatefulWidget {
  const WorldbuildingBody({
    super.key,
    this.assetId,
    this.assetType,
    this.activeSection,
  });

  final String? assetId;
  final AssetType? assetType;
  final String? activeSection;

  @override
  ConsumerState<WorldbuildingBody> createState() => _WorldbuildingBodyState();
}

class _WorldbuildingBodyState extends ConsumerState<WorldbuildingBody> {
  List<domain.FactionModel>? _factions;
  List<era.TimelineEraModel>? _eras;
  List<LoreEntityRef>? _lore;
  List<EnvironmentModel>? _locations;
  List<CharacterRelationMapEntry>? _relations;
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
      final environments = await EnvironmentRepositoryImpl(
        database: db,
        projectId: projectId,
      ).getEnvironments();
      final relations = await const CharacterRelationMapService().mapForProject(
        db,
        projectId: projectId,
      );
      if (!mounted) return;
      setState(() {
        _factions = factions;
        _eras = eras;
        _lore = lore;
        _locations = environments;
        _relations = relations;
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
    final session = ref.watch(projectSessionProvider).valueOrNull;
    final sectionIntent = ref.watch(worldbuildingSectionIntentProvider);
    final focusedSection = sectionIntent?.$1 == session?.manifest.id
        ? sectionIntent?.$2
        : null;
    final requestedSection =
        widget.activeSection ??
        switch (focusedSection) {
          WorldbuildingExplorerSection.factions => 'Factions',
          WorldbuildingExplorerSection.relationshipMap => 'Relationships',
          null => null,
        };
    final showOverview =
        requestedSection == null || requestedSection == 'Overview';
    final showFactions = showOverview || requestedSection == 'Factions';
    final showRelationships =
        showOverview || requestedSection == 'Relationships';
    final showTimeline = showOverview || requestedSection == 'Timeline';
    final showLore = showOverview || requestedSection == 'Lore Notes';
    final showLocations = showOverview || requestedSection == 'Locations';
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
                  Expanded(
                    child: Text(
                      showOverview
                          ? 'Worldbuilding Workspace'
                          : requestedSection,
                      style: VoidTypography.headingMedium,
                    ),
                  ),
                  if (showFactions)
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
                if (showFactions)
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
                if (showTimeline) ...[
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
                ],
                if (showLore) ...[
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
                if (showLocations) ...[
                  const SizedBox(height: 16),
                  _WorldSection(
                    title: 'Locations',
                    emptyLabel: 'Belum ada lokasi pada proyek ini.',
                    items: [
                      for (final location in _locations ?? const [])
                        _WorldItem(
                          id: location.assetId,
                          title: location.name,
                          subtitle: location.environmentType,
                          selected: selectedId == location.assetId,
                          onTap: () => _selectAsset(
                            location.assetId,
                            AssetType.environment,
                          ),
                        ),
                    ],
                  ),
                ],
                if (showRelationships) ...[
                  const SizedBox(height: 16),
                  _WorldSection(
                    title: 'Relationship Map',
                    emptyLabel:
                        'Belum ada relasi antar karakter pada proyek ini.',
                    items: [
                      for (final relation in _relations ?? const [])
                        _RelationItem(entry: relation),
                    ],
                  ),
                ],
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
  final List<Widget> items;

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

/// Baris relasi karakter pada section Relationship Map: sumber -> target
/// dengan label tipe relasi di tengah (Step 145.27 Relationship Map).
class _RelationItem extends StatelessWidget {
  const _RelationItem({required this.entry});

  final CharacterRelationMapEntry entry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                entry.sourceName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: palette.borderSoft),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                entry.typeLabel,
                style: const TextStyle(fontSize: 11),
              ),
            ),
            Expanded(
              child: Text(
                entry.targetName,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void selectAsset(WidgetRef ref, SelectionModel selection) {
  ref.read(selectionProvider.notifier).select(selection);
}

/// Step 145.43 friksi #1: aksi link karakter ke novel dari kartu Linked
/// Characters. Satu pintu lewat [CreateNovelCharacterLinkService]; picker
/// karakter dari katalog proyek; katalog kosong = snackbar jujur, bukan
/// dialog mati; kegagalan persist = snackbar, kartu tetap valid.
Future<WorkspaceProjection?> _linkCharacterToNovel(
  BuildContext context,
  ProjectSession session,
  String novelWorkspaceId,
) async {
  final characters = await session.database.characterDao.getAllCharacters(
    session.manifest.id,
  );
  if (characters.isEmpty) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Belum ada karakter. Buat karakter dulu dari Explorer.'),
      ),
    );
    return null;
  }
  if (!context.mounted) return null;
  final characterId = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Link character to novel'),
      content: SizedBox(
        width: 360,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: characters.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final character = characters[index];
            return ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(character.displayName),
              onTap: () => Navigator.pop(dialogContext, character.assetId),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
  if (characterId == null) return null;
  try {
    await CreateNovelCharacterLinkService(
      links: session.novelCharacterLinks,
      projections: session.workspaceProjections,
    ).create(novelWorkspaceId: novelWorkspaceId, characterAssetId: characterId);
    return session.workspaceProjectionReader.forNovel(novelWorkspaceId);
  } catch (_) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link gagal dibuat. Coba lagi.')),
    );
    return null;
  }
}
