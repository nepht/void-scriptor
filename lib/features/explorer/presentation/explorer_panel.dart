import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/selection/selection_memory_snapshot.dart';
import '../../../core/selection/selection_controller.dart';
import '../../../core/selection/selection_model.dart';
import '../../assets/domain/asset_type.dart';
import '../../character/domain/character_model.dart';
import '../../character/presentation/character_controller.dart';
import '../../character_mode/presentation/character_mode_controller.dart';
import '../../projects/presentation/project_persistence_providers.dart';
import '../../wardrobe/data/wardrobe_repository_impl.dart';
import '../../wardrobe/domain/wardrobe_model.dart';
import '../../weapon/data/weapon_repository_impl.dart';
import '../../weapon/domain/weapon_model.dart';
import '../../props/data/prop_repository.dart';
import '../../props/domain/prop_model.dart';
import '../../props/application/create_prop_service.dart';
import '../../creatures/application/create_creature_service.dart';
import '../../creatures/data/creature_repository.dart';
import '../../creatures/domain/creature_model.dart';
import 'explorer_environment_group.dart';
import '../../environment/data/environment_repository_impl.dart';
import '../../environment/domain/environment_model.dart';
import '../../../database/project/project_database.dart';
import 'explorer_story_group.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';
import '../../character/application/create_character_service.dart';
import '../../environment/application/create_environment_service.dart';
import '../../environment/domain/environment_type.dart';
import '../../story/application/create_story_service.dart';
import '../../wardrobe/application/create_wardrobe_service.dart';
import '../../weapon/application/create_weapon_service.dart';
import '../../workspaces/application/narrative_assignment_repository.dart';
import '../../workspaces/domain/narrative_assignment.dart';
import '../../workspaces/domain/narrative_character_filter.dart';
import '../application/project_sidebar_module_preferences.dart';
import '../../workspace/application/workspace_section_controller.dart';

enum WorldbuildingExplorerSection { factions, relationshipMap }

final worldbuildingSectionIntentProvider =
    StateProvider<(String, WorldbuildingExplorerSection)?>((ref) => null);

final projectSidebarModulePreferencesServiceProvider =
    Provider<ProjectSidebarModulePreferencesService>(
      (ref) => const ProjectSidebarModulePreferencesService(),
    );

final projectSidebarModulePreferencesProvider =
    FutureProvider.family<ProjectSidebarModulePreferences, String>((
      ref,
      projectId,
    ) async {
      final session = ref.watch(projectSessionProvider).valueOrNull;
      if (session == null || session.manifest.id != projectId) {
        return const ProjectSidebarModulePreferences(
          factions: false,
          relationshipMap: true,
        );
      }
      return ref
          .watch(projectSidebarModulePreferencesServiceProvider)
          .load(
            package: session.package,
            database: session.database,
            projectId: projectId,
          );
    });

final propExplorerProvider = FutureProvider.family<List<PropModel>, String>((
  ref,
  projectId,
) async {
  final session = ref.watch(projectSessionProvider).valueOrNull;
  if (session == null || session.manifest.id != projectId) return const [];
  return PropRepository(session.database).listForProject(projectId);
});

final creatureExplorerProvider =
    FutureProvider.family<List<CreatureModel>, String>((ref, projectId) async {
      final session = ref.watch(projectSessionProvider).valueOrNull;
      if (session == null || session.manifest.id != projectId) return const [];
      return CreatureRepository(session.database).listForProject(projectId);
    });

final supportingAssetExplorerProvider =
    FutureProvider.family<List<Asset>, (String, AssetType)>((ref, key) async {
      final session = ref.watch(projectSessionProvider).valueOrNull;
      if (session == null || session.manifest.id != key.$1) return const [];
      return (await session.database.assetDao.getAllAssets())
          .where(
            (asset) => asset.projectId == key.$1 && asset.type == key.$2.name,
          )
          .toList(growable: false)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    });

final storyExplorerProvider = FutureProvider.family<List<Asset>, String>((
  ref,
  projectId,
) async {
  final session = ref.watch(projectSessionProvider).valueOrNull;
  if (session == null || session.manifest.id != projectId) return const [];
  return (await session.database.assetDao.getAllAssets())
      .where((asset) => asset.projectId == projectId && asset.type == 'story')
      .toList(growable: false);
});

/// Tracks the semantic asset type requested by top-bar navigation, stamped
/// with the project session that produced it. Consumers must compare the
/// stamp against the ACTIVE project session (hunt-run171 BUG-13: a bare
/// `AssetType?` leaked the focus highlight into the next opened project).
final explorerAssetFocusProvider = StateProvider<(String, AssetType)?>(
  (ref) => null,
);

/// All narrative assignments of the active project (empty when no session).
/// Feeds the explorer character-list narrative filter (backlog
/// character-roles-support phase_one).
final explorerNarrativeAssignmentsProvider =
    FutureProvider<List<NarrativeAssignment>>((ref) async {
      final session = ref.watch(projectSessionProvider).valueOrNull;
      if (session == null) return const [];
      return NarrativeAssignmentRepository(
        database: session.database,
        projectId: session.manifest.id,
      ).listAssignments();
    });

AssetType? explorerAssetTypeForMenu(String menu) => switch (menu) {
  // hunt-run171 BUG-4: 'novels' adalah destinasi global Projects (top-bar
  // desktop), bukan fokus aset Explorer; memetakannya ke AssetType.story
  // mengintersep tombol "Projects" ke Novel workspace dan membuat arm
  // 'novels' => AppRoutes.projects dead code. Focus aset Novel tetap lewat
  // key 'story' (satu-satunya producer) dan seleksi Explorer biasa.
  'story' => AssetType.story,
  'characters' => AssetType.character,
  'world' => AssetType.environment,
  _ => null,
};

void focusExplorerAsset(WidgetRef ref, AssetType type) {
  if (type != AssetType.faction) {
    ref.read(worldbuildingSectionIntentProvider.notifier).state = null;
  }
  final session = ref.read(projectSessionProvider).valueOrNull;
  // hunt-run171 BUG-13: stamp the focus intent with its project session;
  // without a session there is nothing to highlight, so clear instead of
  // leaving a bare type that would leak into the next opened project.
  ref.read(explorerAssetFocusProvider.notifier).state = session == null
      ? null
      : (session.manifest.id, type);
  final sectionTarget = switch (type) {
    AssetType.story || AssetType.scene => (WorkspaceKind.novel, 'Outline'),
    AssetType.character => (WorkspaceKind.character, 'Profile'),
    AssetType.environment => (WorkspaceKind.worldbuilding, 'Locations'),
    AssetType.timeline => (WorkspaceKind.worldbuilding, 'Timeline'),
    _ => null,
  };
  if (sectionTarget != null) {
    ref
        .read(workspaceSectionProvider.notifier)
        .activate(sectionTarget.$1, sectionTarget.$2);
  }
  if (session == null) return;
  final projectId = session.manifest.id;
  final controller = ref.read(selectionProvider.notifier);
  controller.focusWorkspace(projectId: projectId, type: type);
  void restore(Iterable<String>? ids) {
    if (ids == null) {
      // Do not discard remembered ids while the destination catalog loads.
      final current = ref.read(selectionProvider);
      if (current?.projectId != projectId || current?.assetType != type) {
        controller.clear();
      }
      return;
    }
    controller.selectWorkspace(
      projectId: projectId,
      type: type,
      availableAssetIds: ids,
    );
  }

  switch (type) {
    case AssetType.character:
      final characters = ref
          .read(characterControllerProvider(projectId))
          .valueOrNull;
      restore(characters?.map((item) => item.assetId));
    case AssetType.story:
      final stories = ref.read(storyExplorerProvider(projectId)).valueOrNull;
      restore(stories?.map((item) => item.id));
    case AssetType.environment:
      final environments = ref
          .read(environmentExplorerProvider(projectId))
          .valueOrNull;
      restore(environments?.map((item) => item.assetId));
    case AssetType.creature:
      // BUG-05 (hunt-20260910): restore sinkron saat katalog creature
      // sudah siap, mengikuti pola character/environment.
      final creatures = ref
          .read(creatureExplorerProvider(projectId))
          .valueOrNull;
      restore(creatures?.map((item) => item.assetId));
    default:
      if (ref.read(selectionProvider)?.assetType != type) {
        ref.read(selectionProvider.notifier).clear();
      }
  }
}

void focusWorldbuildingSection(
  WidgetRef ref,
  WorldbuildingExplorerSection section,
) {
  final session = ref.read(projectSessionProvider).valueOrNull;
  if (session == null) return;
  final projectId = session.manifest.id;
  ref.read(worldbuildingSectionIntentProvider.notifier).state = (
    projectId,
    section,
  );
  ref
      .read(workspaceSectionProvider.notifier)
      .activate(
        WorkspaceKind.worldbuilding,
        section == WorldbuildingExplorerSection.factions
            ? 'Factions'
            : 'Relationships',
      );
  final controller = ref.read(selectionProvider.notifier);
  controller.focusWorkspace(projectId: projectId, type: AssetType.faction);
  controller.clear();
}

/// Reactive catalog recovery for typed workspace navigation.
///
/// While a focused workspace catalog is loading, the incompatible previous
/// selection is released and the per-workspace session memory is kept.
/// As soon as the focused catalog provides data, the remembered selection
/// (or the first asset) is restored without another user tap. A selection
/// the user makes while waiting is never overridden, and stale intents for
/// other projects are ignored.
/// Persists per-workspace selection memory into the active project package
/// (cache/selection_memory.json) so the remembered workspace selection
/// survives an application restart. Hydration happens exactly once per
/// project session (re-hydrating when a different project is opened) and
/// never overwrites selections the user has already made. Writes are
/// scoped to the active project before persisting; disk failures are
/// swallowed by contract (memory is a convenience, never a blocker) but
/// are observable via debugPrint.
final selectionMemoryPersistenceProvider = Provider<void>((ref) {
  final session = ref.watch(projectSessionProvider).valueOrNull;
  if (session == null) return;
  final projectId = session.manifest.id;

  // Hydration is per project session (hunt-20260910b BUG-2): each opened
  // project loads its own persisted memory exactly once; a later project
  // must not inherit the previous project's hydrated flag.
  ref
      .read(selectionProvider.notifier)
      .hydrateWorkspaceMemory(
        loadSelectionMemorySnapshotSync(
          selectionMemoryFileFor(session.package),
        ),
        projectId: projectId,
      );

  // Synchronous write on each selection change: the snapshot is a tiny JSON
  // file, selection changes are tap-frequency, and a sync write inside the
  // single isolate is inherently serialized. A debounced Timer here would
  // dangle across widget-tree teardowns in fake-async test zones.
  //
  // The snapshot is scoped to the ACTIVE project before writing: the file
  // lives inside this project's package, so foreign entries must never
  // reach it (hunt-20260910b BUG-2).
  ref.listen(selectionProvider, (_, __) {
    persistSelectionMemorySnapshotSync(
      selectionMemoryFileFor(session.package),
      ref
          .read(selectionProvider.notifier)
          .workspaceMemorySnapshot(projectId: projectId),
    );
  });
});

final explorerCatalogRecoveryProvider = Provider<void>((ref) {
  final intent = ref.watch(workspaceIntentProvider);
  final selection = ref.watch(selectionProvider);
  final session = ref.watch(projectSessionProvider).valueOrNull;
  if (intent == null || session == null) return;
  final (projectId, type) = intent;
  if (projectId != session.manifest.id) return;
  // A live selection (compatible or user-chosen meanwhile) is never
  // overridden by catalog completion.
  if (selection != null) return;
  List<String>? idsOf(AsyncValue<List<Object?>> value) {
    if (type == AssetType.story) {
      return (value as AsyncValue<List<Asset>>).valueOrNull
          ?.map((item) => item.id)
          .toList(growable: false);
    }
    return value.valueOrNull
        ?.map((item) => (item as dynamic).assetId as String)
        .toList(growable: false);
  }

  final AsyncValue<List<Object?>> catalog;
  switch (type) {
    case AssetType.character:
      catalog = ref.watch(characterControllerProvider(projectId));
    case AssetType.story:
      catalog = ref.watch(storyExplorerProvider(projectId));
    case AssetType.environment:
      catalog = ref.watch(environmentExplorerProvider(projectId));
    case AssetType.creature:
      // BUG-05 (hunt-20260910): creature intent tanpa selection pun butuh
      // pemulihan; tanpa ini intent creature stranded tanpa jalur pulih.
      catalog = ref.watch(creatureExplorerProvider(projectId));
    default:
      return;
  }
  final ids = idsOf(catalog);
  if (ids == null || ids.isEmpty) {
    // Still loading, failed, or nothing to select: keep waiting; this
    // provider re-evaluates whenever the catalog, intent, or selection
    // changes. Writing here on an empty catalog would loop through the
    // intent provider without ever changing state.
    //
    // BUG-8 (hunt-run171): a failed catalog never re-emits on its own;
    // the user-visible retry lives on the Explorer group error rows
    // (onRetry -> invalidate). Recovery simply keeps waiting here until
    // that retry (or any other invalidation) re-runs the catalog.
    return;
  }
  // Never mutate other providers synchronously while building: schedule
  // the restore and re-guard inside the microtask so a user selection or
  // an intent change that happened meanwhile always wins.
  Future<void>.microtask(() {
    final currentIntent = ref.read(workspaceIntentProvider);
    if (currentIntent == null ||
        currentIntent.$1 != projectId ||
        currentIntent.$2 != type) {
      return;
    }
    if (ref.read(selectionProvider) != null) return;
    ref
        .read(selectionProvider.notifier)
        .selectWorkspace(
          projectId: projectId,
          type: type,
          availableAssetIds: ids,
        );
  });
});

final wardrobeExplorerProvider =
    FutureProvider.family<List<WardrobeModel>, String>((ref, projectId) async {
      final session = ref.watch(projectSessionProvider).valueOrNull;
      if (session == null || session.manifest.id != projectId) return const [];
      return WardrobeRepositoryImpl(
        database: session.database,
        projectId: projectId,
      ).getWardrobes();
    });

final weaponExplorerProvider = FutureProvider.family<List<WeaponModel>, String>(
  (ref, projectId) async {
    final session = ref.watch(projectSessionProvider).valueOrNull;
    if (session == null || session.manifest.id != projectId) return const [];
    return WeaponRepositoryImpl(
      database: session.database,
      projectId: projectId,
    ).getWeapons();
  },
);

final environmentExplorerProvider =
    FutureProvider.family<List<EnvironmentModel>, String>((
      ref,
      projectId,
    ) async {
      final session = ref.watch(projectSessionProvider).valueOrNull;
      if (session == null || session.manifest.id != projectId) return const [];
      return EnvironmentRepositoryImpl(
        database: session.database,
        projectId: projectId,
      ).getEnvironments();
    });

class ExplorerPanel extends ConsumerWidget {
  const ExplorerPanel({super.key, this.onTimelineSelected});

  final VoidCallback? onTimelineSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep the reactive catalog recovery mounted with the panel.
    ref.watch(explorerCatalogRecoveryProvider);
    ref.watch(selectionMemoryPersistenceProvider);
    final projectId = ref
        .watch(projectSessionProvider)
        .valueOrNull
        ?.manifest
        .id;
    final characters = projectId == null
        ? const AsyncValue<List<CharacterModel>>.data([])
        : ref.watch(characterControllerProvider(projectId));
    final wardrobes = projectId == null
        ? const AsyncValue<List<WardrobeModel>>.data([])
        : ref.watch(wardrobeExplorerProvider(projectId));
    final weapons = projectId == null
        ? const AsyncValue<List<WeaponModel>>.data([])
        : ref.watch(weaponExplorerProvider(projectId));
    final storyItems = projectId == null
        ? const AsyncValue<List<PropModel>>.data([])
        : ref.watch(propExplorerProvider(projectId));
    final creatures = projectId == null
        ? const AsyncValue<List<CreatureModel>>.data([])
        : ref.watch(creatureExplorerProvider(projectId));
    final armors = projectId == null
        ? const AsyncValue<List<Asset>>.data([])
        : ref.watch(
            supportingAssetExplorerProvider((projectId, AssetType.armor)),
          );
    final accessories = projectId == null
        ? const AsyncValue<List<Asset>>.data([])
        : ref.watch(
            supportingAssetExplorerProvider((projectId, AssetType.accessory)),
          );

    final environments = projectId == null
        ? const AsyncValue<List<EnvironmentModel>>.data([])
        : ref.watch(environmentExplorerProvider(projectId));
    final stories = projectId == null
        ? const AsyncValue<List<Asset>>.data([])
        : ref.watch(storyExplorerProvider(projectId));
    final focusedType = ref.watch(explorerAssetFocusProvider);
    // hunt-run171 BUG-13: the focus intent must match the ACTIVE project
    // session; a stale focus typed in another project must not highlight
    // this project's explorer groups.
    final activeSession = ref.watch(projectSessionProvider).valueOrNull;
    final effectiveFocusedType =
        focusedType != null &&
            activeSession != null &&
            focusedType.$1 == activeSession.manifest.id
        ? focusedType.$2
        : null;
    final modulePreferences = projectId == null
        ? const ProjectSidebarModulePreferences(
            factions: false,
            relationshipMap: true,
          )
        : ref
                  .watch(projectSidebarModulePreferencesProvider(projectId))
                  .valueOrNull ??
              const ProjectSidebarModulePreferences(
                factions: false,
                relationshipMap: true,
              );

    return Container(
      width: 245,
      decoration: BoxDecoration(
        color: context.palette.panel,
        border: Border(right: BorderSide(color: context.palette.borderSoft)),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'PROJECT EXPLORER',
                      style: TextStyle(
                        color: context.palette.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Configure sidebar modules',
                    onPressed: projectId == null
                        ? null
                        : () => _configureSidebarModules(
                            context,
                            ref,
                            projectId,
                            modulePreferences,
                          ),
                    icon: const Icon(Icons.tune_outlined, size: 18),
                  ),
                  IconButton(
                    tooltip: 'Create Asset',
                    onPressed: projectId == null
                        ? null
                        : () => _createExplorerAsset(context, ref),
                    icon: const Icon(Icons.add, size: 18),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                children: [
                  const _ExplorerSectionLabel('NOVEL & STORY'),
                  _ExplorerItem(
                    icon: Icons.auto_stories_outlined,
                    label: 'Novel Workspace',
                    onTap: () => focusExplorerAsset(ref, AssetType.story),
                  ),
                  StoryGroup(
                    onFocused: () => focusExplorerAsset(ref, AssetType.story),
                    stories: stories,
                    focused: effectiveFocusedType == AssetType.story,
                    selectedId: ref.watch(selectionProvider)?.assetId,
                    // BUG-8 (hunt-run171): katalog gagal harus bisa di-retry
                    // dari baris error, bukan hanya menunggu invalidasi tak
                    // langsung dari create flow.
                    onRetry: projectId == null
                        ? null
                        : () =>
                              ref.invalidate(storyExplorerProvider(projectId)),
                    onSelected: (story) => ref
                        .read(selectionProvider.notifier)
                        .select(
                          SelectionModel(
                            assetId: story.id,
                            assetType: AssetType.story,
                            projectId: story.projectId,
                          ),
                        ),
                  ),
                  const _ExplorerSectionLabel('CAST & CHARACTERS'),
                  _CharacterGroup(
                    onFocused: () =>
                        focusExplorerAsset(ref, AssetType.character),
                    characters: characters,
                    focused: effectiveFocusedType == AssetType.character,
                    selectedId: ref.watch(selectionProvider)?.assetId,

                    onSelected: (character) => ref
                        .read(selectionProvider.notifier)
                        .select(
                          SelectionModel(
                            assetId: character.assetId,
                            assetType: AssetType.character,
                            projectId: character.projectId,
                          ),
                        ),
                  ),
                  const _ExplorerSectionLabel('WORLD & CREATURES'),
                  if (modulePreferences.creatures)
                    _CreatureGroup(
                      creatures: creatures,
                      selectedId: ref.watch(selectionProvider)?.assetId,
                      onSelected: (creature) => ref
                          .read(selectionProvider.notifier)
                          .select(
                            SelectionModel(
                              assetId: creature.assetId,
                              assetType: AssetType.creature,
                              projectId: creature.projectId,
                            ),
                          ),
                    ),
                  EnvironmentGroup(
                    onFocused: () =>
                        focusExplorerAsset(ref, AssetType.environment),
                    environments: environments,
                    selectedId: ref.watch(selectionProvider)?.assetId,

                    // BUG-8 (hunt-run171): katalog gagal harus bisa di-retry
                    // dari baris error, bukan hanya menunggu invalidasi tak
                    // langsung dari create flow.
                    onRetry: projectId == null
                        ? null
                        : () => ref.invalidate(
                            environmentExplorerProvider(projectId),
                          ),
                    onSelected: (environment) => ref
                        .read(selectionProvider.notifier)
                        .select(
                          SelectionModel(
                            assetId: environment.assetId,
                            assetType: AssetType.environment,
                            projectId: environment.projectId,
                          ),
                        ),
                  ),
                  _ExplorerItem(
                    icon: Icons.timeline_outlined,
                    label: 'Timeline',
                    onTap:
                        onTimelineSelected ??
                        () => focusExplorerAsset(ref, AssetType.timeline),
                  ),
                  if (modulePreferences.hasLoadout)
                    const _ExplorerSectionLabel('OBJECTS & LOADOUT'),
                  if (modulePreferences.wardrobe)
                    _WardrobeGroup(
                      wardrobes: wardrobes,
                      selectedId: ref.watch(selectionProvider)?.assetId,

                      onSelected: (wardrobe) => ref
                          .read(selectionProvider.notifier)
                          .select(
                            SelectionModel(
                              assetId: wardrobe.assetId,
                              assetType: AssetType.wardrobe,
                              projectId: wardrobe.projectId,
                            ),
                          ),
                    ),
                  if (modulePreferences.armor)
                    _AssetGroup(
                      label: 'Armor',
                      icon: Icons.shield_outlined,
                      assets: armors,
                      selectedId: ref.watch(selectionProvider)?.assetId,
                      onSelected: (asset) =>
                          _selectDatabaseAsset(ref, asset, AssetType.armor),
                    ),
                  if (modulePreferences.accessories)
                    _AssetGroup(
                      label: 'Accessories',
                      icon: Icons.watch_outlined,
                      assets: accessories,
                      selectedId: ref.watch(selectionProvider)?.assetId,
                      onSelected: (asset) =>
                          _selectDatabaseAsset(ref, asset, AssetType.accessory),
                    ),
                  if (modulePreferences.weapons)
                    _WeaponGroup(
                      weapons: weapons,
                      selectedId: ref.watch(selectionProvider)?.assetId,

                      onSelected: (weapon) => ref
                          .read(selectionProvider.notifier)
                          .select(
                            SelectionModel(
                              assetId: weapon.assetId,
                              assetType: AssetType.weapon,
                              projectId: weapon.projectId,
                            ),
                          ),
                    ),
                  if (modulePreferences.storyItems)
                    _StoryItemGroup(
                      items: storyItems,
                      selectedId: ref.watch(selectionProvider)?.assetId,
                      onSelected: (item) => ref
                          .read(selectionProvider.notifier)
                          .select(
                            SelectionModel(
                              assetId: item.assetId,
                              assetType: AssetType.prop,
                              projectId: item.projectId,
                            ),
                          ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _selectDatabaseAsset(WidgetRef ref, Asset asset, AssetType type) => ref
    .read(selectionProvider.notifier)
    .select(
      SelectionModel(
        assetId: asset.id,
        assetType: type,
        projectId: asset.projectId,
      ),
    );

class _ExplorerSectionLabel extends StatelessWidget {
  const _ExplorerSectionLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 16, 10, 6),
    child: Text(
      label,
      style: TextStyle(
        color: context.palette.textMuted,
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    ),
  );
}

class _CreatureGroup extends StatelessWidget {
  const _CreatureGroup({
    required this.creatures,
    required this.selectedId,
    required this.onSelected,
  });
  final AsyncValue<List<CreatureModel>> creatures;
  final String? selectedId;
  final ValueChanged<CreatureModel> onSelected;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    initiallyExpanded: true,
    tilePadding: const EdgeInsets.symmetric(horizontal: 9),
    childrenPadding: const EdgeInsets.only(left: 28),
    leading: Icon(
      Icons.pets_outlined,
      size: 16,
      color: context.palette.textMuted,
    ),
    title: Text(
      'Creatures & Companions',
      style: TextStyle(color: context.palette.textSecondary, fontSize: 12),
    ),
    children: creatures.when(
      loading: () => const [ListTile(dense: true, title: Text('Loading...'))],
      error: (error, _) => [ListTile(dense: true, title: Text('$error'))],
      data: (items) => items.isEmpty
          ? const [ListTile(dense: true, title: Text('No creatures yet'))]
          : [
              for (final item in items)
                ListTile(
                  dense: true,
                  minTileHeight: 36,
                  leading: Icon(
                    item.category == CreatureCategory.companion
                        ? Icons.favorite_outline
                        : Icons.cruelty_free_outlined,
                    size: 15,
                  ),
                  title: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: item.category == CreatureCategory.companion
                      ? const Text('Companion')
                      : null,
                  selected: selectedId == item.assetId,
                  onTap: () => onSelected(item),
                ),
            ],
    ),
  );
}

class _AssetGroup extends StatelessWidget {
  const _AssetGroup({
    required this.label,
    required this.icon,
    required this.assets,
    required this.selectedId,
    required this.onSelected,
  });
  final String label;
  final IconData icon;
  final AsyncValue<List<Asset>> assets;
  final String? selectedId;
  final ValueChanged<Asset> onSelected;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    initiallyExpanded: true,
    tilePadding: const EdgeInsets.symmetric(horizontal: 9),
    childrenPadding: const EdgeInsets.only(left: 28),
    leading: Icon(icon, size: 16, color: context.palette.textMuted),
    title: Text(
      label,
      style: TextStyle(color: context.palette.textSecondary, fontSize: 12),
    ),
    children: assets.when(
      loading: () => const [ListTile(dense: true, title: Text('Loading...'))],
      error: (error, _) => [ListTile(dense: true, title: Text('$error'))],
      data: (items) => items.isEmpty
          ? [
              ListTile(
                dense: true,
                title: Text('No ${label.toLowerCase()} yet'),
              ),
            ]
          : [
              for (final item in items)
                ListTile(
                  dense: true,
                  minTileHeight: 36,
                  title: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: selectedId == item.id,
                  onTap: () => onSelected(item),
                ),
            ],
    ),
  );
}

Future<void> _configureSidebarModules(
  BuildContext context,
  WidgetRef ref,
  String projectId,
  ProjectSidebarModulePreferences current,
) async {
  var wardrobe = current.wardrobe;
  var weapons = current.weapons;
  var storyItems = current.storyItems;
  var creatures = current.creatures;
  var armor = current.armor;
  var accessories = current.accessories;
  final result = await showDialog<ProjectSidebarModulePreferences>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Sidebar modules'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggested by genre; you remain in control.',
                  style: TextStyle(color: context.palette.textMuted),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hidden modules keep their data. Changes apply only to this project.',
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => setState(() {
                        wardrobe = true;
                        storyItems = true;
                        accessories = true;
                        weapons = false;
                        armor = false;
                        creatures = false;
                      }),
                      child: const Text('Drama / Romance'),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        wardrobe = true;
                        storyItems = true;
                        accessories = true;
                        weapons = true;
                        armor = true;
                        creatures = true;
                      }),
                      child: const Text('Fantasy / Adventure'),
                    ),
                  ],
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Creatures & Companions'),
                  value: creatures,
                  onChanged: (value) =>
                      setState(() => creatures = value ?? creatures),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Armor'),
                  value: armor,
                  onChanged: (value) => setState(() => armor = value ?? armor),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Accessories'),
                  value: accessories,
                  onChanged: (value) =>
                      setState(() => accessories = value ?? accessories),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Wardrobe'),
                  subtitle: const Text(
                    'Clothing, costumes, jewelry, and accessories',
                  ),
                  value: wardrobe,
                  onChanged: (value) =>
                      setState(() => wardrobe = value ?? wardrobe),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Weapons'),
                  subtitle: const Text(
                    'Useful for action, fantasy, war, and adventure stories',
                  ),
                  value: weapons,
                  onChanged: (value) =>
                      setState(() => weapons = value ?? weapons),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Story Items'),
                  subtitle: const Text(
                    'Letters, keepsakes, evidence, artifacts, and plot objects',
                  ),
                  value: storyItems,
                  onChanged: (value) =>
                      setState(() => storyItems = value ?? storyItems),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              ProjectSidebarModulePreferences(
                factions: false,
                relationshipMap: false,
                weapons: weapons,
                storyItems: storyItems,
                wardrobe: wardrobe,
                creatures: creatures,
                armor: armor,
                accessories: accessories,
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  if (result == null) return;
  final session = ref.read(projectSessionProvider).valueOrNull;
  if (session == null || session.manifest.id != projectId) return;
  try {
    await ref
        .read(projectSidebarModulePreferencesServiceProvider)
        .save(session.package, result);
    ref.invalidate(projectSidebarModulePreferencesProvider(projectId));
  } on FileSystemException {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Sidebar settings could not be saved. Check storage access.',
        ),
      ),
    );
  }
}

Future<void> _createExplorerAsset(BuildContext context, WidgetRef ref) =>
    createExplorerAsset(context, ref);

Future<void> createExplorerAsset(
  BuildContext context,
  WidgetRef ref, {
  AssetType? fixedType,
}) async {
  final session = ref.read(projectSessionProvider).valueOrNull;
  if (session == null) return;
  var type = fixedType ?? AssetType.character;
  var creatureCategory = CreatureCategory.animal;
  var assetName = '';
  final result = await showDialog<(AssetType, String, CreatureCategory)>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Create Asset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (fixedType == null)
              DropdownButtonFormField<AssetType>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(
                    value: AssetType.character,
                    child: Text('Character'),
                  ),
                  DropdownMenuItem(
                    value: AssetType.story,
                    child: Text('Story'),
                  ),
                  DropdownMenuItem(
                    value: AssetType.wardrobe,
                    child: Text('Wardrobe'),
                  ),
                  DropdownMenuItem(
                    value: AssetType.weapon,
                    child: Text('Weapon'),
                  ),
                  DropdownMenuItem(
                    value: AssetType.armor,
                    child: Text('Armor'),
                  ),
                  DropdownMenuItem(
                    value: AssetType.accessory,
                    child: Text('Accessory'),
                  ),
                  DropdownMenuItem(
                    value: AssetType.prop,
                    child: Text('Item / Prop'),
                  ),
                  DropdownMenuItem(
                    value: AssetType.creature,
                    child: Text('Creature / Companion'),
                  ),
                  DropdownMenuItem(
                    value: AssetType.environment,
                    child: Text('Environment'),
                  ),
                ],
                onChanged: (value) => setState(() => type = value ?? type),
              ),
            if (type == AssetType.creature)
              DropdownButtonFormField<CreatureCategory>(
                initialValue: creatureCategory,
                decoration: const InputDecoration(labelText: 'Creature role'),
                items: CreatureCategory.values
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(
                          category.name[0].toUpperCase() +
                              category.name.substring(1),
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setState(
                  () => creatureCategory = value ?? creatureCategory,
                ),
              ),
            TextField(
              onChanged: (value) => assetName = value,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = assetName.trim();
              if (name.isNotEmpty) {
                Navigator.pop(dialogContext, (type, name, creatureCategory));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    ),
  );
  if (result == null) return;
  final (assetType, name, selectedCreatureCategory) = result;
  final projectId = session.manifest.id;
  final paths = ref.read(projectPathsProvider);
  if (ref.read(projectSessionProvider).valueOrNull != session) return;
  try {
    late final String assetId;
    switch (assetType) {
      case AssetType.character:
        assetId = await CreateCharacterService(
          database: session.database,
          paths: paths,
        ).create(projectId: projectId, name: name);
        ref.invalidate(characterControllerProvider(projectId));
      case AssetType.story:
        // hunt-run171 BUG-9: story → chapter → scene must land atomically;
        // the old three-await chain left an orphan story row (retry
        // duplicated the novel) whenever a later insert failed.
        assetId = await CreateStoryService(
          database: session.database,
          paths: paths,
        ).createNovelWithFirstChapter(projectId: projectId, title: name);
        ref.invalidate(storyExplorerProvider(projectId));
        // New novels must be selectable as narrative/support story context
        // without an unrelated action rebuilding the asset graph
        // (hunt-run157 BUG-05, Referee REAL BUG Medium).
        ref.invalidate(projectAssetsProvider);
      case AssetType.wardrobe:
        assetId = await CreateWardrobeService(
          database: session.database,
          paths: paths,
        ).create(projectId: projectId, name: name);
        ref.invalidate(wardrobeExplorerProvider(projectId));
      case AssetType.weapon:
        assetId = await CreateWeaponService(
          database: session.database,
          paths: paths,
        ).create(projectId: projectId, name: name, weaponType: 'custom');
        ref.invalidate(weaponExplorerProvider(projectId));
      case AssetType.environment:
        assetId =
            await CreateEnvironmentService(
              database: session.database,
              paths: paths,
            ).create(
              projectId: projectId,
              name: name,
              type: EnvironmentType.custom,
            );
        ref.invalidate(environmentExplorerProvider(projectId));
      case AssetType.armor || AssetType.accessory:
        assetId = const Uuid().v4();
        await session.database.assetDao.createStandaloneAsset(
          id: assetId,
          projectId: projectId,
          name: name,
          type: assetType.name,
          now: DateTime.now().toUtc(),
        );
        ref.invalidate(supportingAssetExplorerProvider((projectId, assetType)));
      case AssetType.prop:
        assetId =
            await CreatePropService(
              database: session.database,
              paths: paths,
            ).create(
              projectId: projectId,
              name: name,
              category: PropCategory.other,
            );
        ref.invalidate(propExplorerProvider(projectId));
      case AssetType.creature:
        assetId =
            await CreateCreatureService(
              database: session.database,
              paths: paths,
            ).create(
              projectId: projectId,
              name: name,
              category: selectedCreatureCategory,
            );
        ref.invalidate(creatureExplorerProvider(projectId));
      default:
        return;
    }
    if (!context.mounted ||
        ref.read(projectSessionProvider).valueOrNull != session) {
      return;
    }
    ref
        .read(selectionProvider.notifier)
        .select(
          SelectionModel(
            assetId: assetId,
            assetType: assetType,
            projectId: projectId,
          ),
        );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aset gagal dibuat. Periksa akses penyimpanan dan coba lagi.',
          ),
        ),
      );
    }
  }
}

class _ExplorerItem extends StatelessWidget {
  const _ExplorerItem({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: context.palette.textMuted),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.palette.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _CharacterGroup extends ConsumerStatefulWidget {
  const _CharacterGroup({
    required this.characters,
    required this.selectedId,
    required this.onSelected,
    this.focused = false,
    this.onFocused,
  });
  final AsyncValue<List<CharacterModel>> characters;
  final String? selectedId;
  final bool focused;
  final VoidCallback? onFocused;
  final ValueChanged<CharacterModel> onSelected;
  @override
  ConsumerState<_CharacterGroup> createState() => _CharacterGroupState();
}

class _CharacterGroupState extends ConsumerState<_CharacterGroup> {
  NarrativeRole? _role;
  NarrativeImportance? _importance;
  NarrativePov? _pov;

  bool get _hasActiveFilter =>
      _role != null || _importance != null || _pov != null;

  NarrativeCharacterFilter get _filter =>
      NarrativeCharacterFilter(role: _role, importance: _importance, pov: _pov);

  Future<void> _showFilterMenu() async {
    NarrativeRole? role = _role;
    NarrativeImportance? importance = _importance;
    NarrativePov? pov = _pov;
    final applied = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Filter Characters'),
          content: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Role'),
                DropdownButton<NarrativeRole>(
                  isExpanded: true,
                  value: role,
                  hint: const Text('All roles'),
                  items: [
                    for (final value in NarrativeRole.values)
                      DropdownMenuItem(
                        value: value,
                        child: Text(switch (value) {
                          NarrativeRole.protagonist => 'Protagonist',
                          NarrativeRole.antagonist => 'Antagonist',
                          NarrativeRole.supporting => 'Supporting',
                          NarrativeRole.background => 'Background',
                        }),
                      ),
                  ],
                  onChanged: (value) => setDialogState(() => role = value),
                ),
                const SizedBox(height: 8),
                const Text('Importance'),
                DropdownButton<NarrativeImportance>(
                  isExpanded: true,
                  value: importance,
                  hint: const Text('All importance levels'),
                  items: [
                    for (final value in NarrativeImportance.values)
                      DropdownMenuItem(
                        value: value,
                        child: Text(switch (value) {
                          NarrativeImportance.major => 'Major',
                          NarrativeImportance.supporting => 'Supporting',
                          NarrativeImportance.minor => 'Minor',
                          NarrativeImportance.unspecified => 'Unspecified',
                        }),
                      ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => importance = value),
                ),
                const SizedBox(height: 8),
                const Text('POV'),
                DropdownButton<NarrativePov>(
                  isExpanded: true,
                  value: pov,
                  hint: const Text('All POV values'),
                  items: [
                    for (final value in NarrativePov.values)
                      DropdownMenuItem(
                        value: value,
                        child: Text(switch (value) {
                          NarrativePov.yes => 'Yes',
                          NarrativePov.no => 'No',
                          NarrativePov.unspecified => 'Unspecified',
                        }),
                      ),
                  ],
                  onChanged: (value) => setDialogState(() => pov = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              key: const ValueKey('narrative-filter-reset'),
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Reset'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      if (applied == true) {
        _role = role;
        _importance = importance;
        _pov = pov;
      } else {
        _role = null;
        _importance = null;
        _pov = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final assignments = ref.watch(explorerNarrativeAssignmentsProvider);
    // Hunt-20260909 BUG-06: a failed narrative provider must be visible and
    // must never silently collapse the character list (an empty assignment
    // list makes every filter dimension match nobody).
    final assignmentError = assignments.hasError && !assignments.isLoading
        ? (assignments.error is StateError
              ? (assignments.error as StateError).message.toString()
              : assignments.error.toString())
        : null;
    final usableAssignments = assignments.valueOrNull ?? const [];
    final filter = _filter;
    final characters = widget.characters.valueOrNull;
    final List<CharacterModel>? filtered;
    if (characters == null) {
      filtered = null;
    } else if (filter.isActive && assignmentError != null) {
      // Fail open: unavailable narrative data degrades to the unfiltered
      // list instead of matching nobody.
      filtered = null;
    } else if (filter.isActive) {
      filtered = characters
          .where(
            (item) => filter.matchesCharacter(
              characterId: item.assetId,
              assignments: usableAssignments,
            ),
          )
          .toList(growable: false);
    } else {
      filtered = null;
    }
    return ExpansionTile(
      onExpansionChanged: (_) => widget.onFocused?.call(),
      initiallyExpanded: true,
      backgroundColor: widget.focused
          ? context.palette.primary.withValues(alpha: 0.08)
          : null,
      tilePadding: const EdgeInsets.symmetric(horizontal: 9),
      childrenPadding: const EdgeInsets.only(left: 28),
      leading: Icon(
        Icons.people_outline,
        size: 16,
        color: context.palette.textMuted,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              'Characters',
              style: TextStyle(
                color: context.palette.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          if (widget.characters.hasValue && widget.characters.value!.isNotEmpty)
            IconButton(
              tooltip: 'Filter characters by narrative role',
              icon: Icon(
                Icons.filter_list,
                size: 16,
                color: _hasActiveFilter
                    ? context.palette.primary
                    : context.palette.textMuted,
              ),
              onPressed: _showFilterMenu,
            ),
        ],
      ),
      children: [
        if (assignmentError != null)
          ListTile(
            dense: true,
            minTileHeight: 30,
            leading: Icon(
              Icons.warning_amber_outlined,
              size: 16,
              color: context.palette.danger,
            ),
            title: Text(
              'Narrative data unavailable: $assignmentError',
              style: TextStyle(color: context.palette.danger, fontSize: 11),
            ),
          ),
        ...widget.characters.when(
          loading: () => [
            const ListTile(dense: true, title: Text('Loading...')),
          ],
          error: (error, _) => [ListTile(dense: true, title: Text('$error'))],
          data: (items) => items.isEmpty
              ? [const ListTile(dense: true, title: Text('No characters yet'))]
              : (filtered ?? items)
                    .map(
                      (item) => ListTile(
                        dense: true,
                        minTileHeight: 30,
                        title: Text(
                          item.displayName,
                          style: TextStyle(
                            color: context.palette.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        selected: widget.selectedId == item.assetId,
                        selectedTileColor: context.palette.primary.withValues(
                          alpha: 0.12,
                        ),
                        onTap: () => widget.onSelected(item),
                      ),
                    )
                    .toList(),
        ),
      ],
    );
  }
}

class _WeaponGroup extends StatelessWidget {
  const _WeaponGroup({
    required this.weapons,
    required this.selectedId,
    required this.onSelected,
  });

  final AsyncValue<List<WeaponModel>> weapons;
  final String? selectedId;
  final ValueChanged<WeaponModel> onSelected;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    initiallyExpanded: true,
    tilePadding: const EdgeInsets.symmetric(horizontal: 9),
    childrenPadding: const EdgeInsets.only(left: 28),
    leading: Icon(
      Icons.auto_fix_high_outlined,
      size: 16,
      color: context.palette.textMuted,
    ),
    title: Text(
      'Weapons',
      style: TextStyle(color: context.palette.textSecondary, fontSize: 12),
    ),
    children: weapons.when(
      loading: () => [const ListTile(dense: true, title: Text('Loading...'))],
      error: (error, _) => [ListTile(dense: true, title: Text('$error'))],
      data: (items) => items.isEmpty
          ? [const ListTile(dense: true, title: Text('No weapons yet'))]
          : items
                .map(
                  (item) => ListTile(
                    dense: true,
                    minTileHeight: 30,
                    title: Text(
                      item.name,
                      style: TextStyle(
                        color: context.palette.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    selected: selectedId == item.assetId,
                    selectedTileColor: context.palette.primary.withValues(
                      alpha: 0.12,
                    ),
                    onTap: () => onSelected(item),
                  ),
                )
                .toList(),
    ),
  );
}

class _WardrobeGroup extends StatelessWidget {
  const _WardrobeGroup({
    required this.wardrobes,
    required this.selectedId,
    required this.onSelected,
  });
  final AsyncValue<List<WardrobeModel>> wardrobes;
  final String? selectedId;
  final ValueChanged<WardrobeModel> onSelected;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    initiallyExpanded: true,
    tilePadding: const EdgeInsets.symmetric(horizontal: 9),
    childrenPadding: const EdgeInsets.only(left: 28),
    leading: Icon(
      Icons.checkroom_outlined,
      size: 16,
      color: context.palette.textMuted,
    ),
    title: Text(
      'Wardrobe',
      style: TextStyle(color: context.palette.textSecondary, fontSize: 12),
    ),
    children: wardrobes.when(
      loading: () => [const ListTile(dense: true, title: Text('Loading...'))],
      error: (error, _) => [ListTile(dense: true, title: Text('$error'))],
      data: (items) => items.isEmpty
          ? [const ListTile(dense: true, title: Text('No wardrobes yet'))]
          : items
                .map(
                  (item) => ListTile(
                    dense: true,
                    minTileHeight: 30,
                    title: Text(
                      item.name,
                      style: TextStyle(
                        color: context.palette.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    selected: selectedId == item.assetId,
                    selectedTileColor: context.palette.primary.withValues(
                      alpha: 0.12,
                    ),
                    onTap: () => onSelected(item),
                  ),
                )
                .toList(),
    ),
  );
}

class _StoryItemGroup extends StatelessWidget {
  const _StoryItemGroup({
    required this.items,
    required this.selectedId,
    required this.onSelected,
  });

  final AsyncValue<List<PropModel>> items;
  final String? selectedId;
  final ValueChanged<PropModel> onSelected;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    initiallyExpanded: true,
    tilePadding: const EdgeInsets.symmetric(horizontal: 9),
    childrenPadding: const EdgeInsets.only(left: 28),
    leading: Icon(
      Icons.inventory_2_outlined,
      size: 16,
      color: context.palette.textMuted,
    ),
    title: Text(
      'Story Items',
      style: TextStyle(color: context.palette.textSecondary, fontSize: 12),
    ),
    children: items.when(
      loading: () => [const ListTile(dense: true, title: Text('Loading...'))],
      error: (error, _) => [ListTile(dense: true, title: Text('$error'))],
      data: (values) => values.isEmpty
          ? [const ListTile(dense: true, title: Text('No story items yet'))]
          : values
                .map(
                  (item) => ListTile(
                    dense: true,
                    minTileHeight: 30,
                    title: Text(
                      item.name,
                      style: TextStyle(
                        color: context.palette.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    selected: selectedId == item.assetId,
                    selectedTileColor: context.palette.primary.withValues(
                      alpha: 0.12,
                    ),
                    onTap: () => onSelected(item),
                  ),
                )
                .toList(),
    ),
  );
}
