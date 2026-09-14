import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/asset_type.dart';
import 'selection_memory_snapshot.dart';
import 'selection_model.dart';

/// Navigation intent is independent of whether a workspace contains assets.
final workspaceIntentProvider = StateProvider<(String, AssetType)?>(
  (ref) => null,
);

class SelectionController extends Notifier<SelectionModel?> {
  final _workspaceSelections = <(String, AssetType), String>{};

  /// Per-project hydration guard: re-hydration is allowed exactly once per
  /// project session (hunt-20260910b BUG-2). A single app-lifetime flag made
  /// the second project of a run inherit the first project's memory and let
  /// persistence overwrite the second project's snapshot file with foreign
  /// entries.
  final _hydratedProjects = <String>{};
  @override
  SelectionModel? build() => null;

  /// Replaces in-session workspace memory with persisted entries exactly
  /// once per project session, before any user pick in this session. Stale
  /// persisted entries must never overwrite selections the user has
  /// already made.
  void hydrateWorkspaceMemory(
    SelectionMemorySnapshot persisted, {
    required String projectId,
  }) {
    if (_hydratedProjects.contains(projectId)) return;
    _hydratedProjects.add(projectId);
    persisted.forEach((key, value) {
      _workspaceSelections.putIfAbsent(key, () => value);
    });
  }

  bool get isWorkspaceMemoryHydrated => _hydratedProjects.isNotEmpty;

  /// Whether the given project's persisted memory has been hydrated in
  /// this app run.
  bool isWorkspaceMemoryHydratedForProject(String projectId) =>
      _hydratedProjects.contains(projectId);

  /// Copy of the live per-workspace memory for persistence.
  ///
  /// [projectId] scopes the result to the active project: the persisted
  /// file lives inside one project package, so writing entries from other
  /// projects would pollute it and drop the project's own remembered
  /// selections (hunt-20260910b BUG-2).
  SelectionMemorySnapshot workspaceMemorySnapshot({String? projectId}) {
    if (projectId == null) {
      return Map<(String, AssetType), String>.of(_workspaceSelections);
    }
    return {
      for (final entry in _workspaceSelections.entries)
        if (entry.key.$1 == projectId) entry.key: entry.value,
    };
  }

  void select(SelectionModel selection) {
    final projectId = selection.projectId;
    if (projectId != null) {
      ref.read(workspaceIntentProvider.notifier).state = (
        projectId,
        selection.assetType,
      );
      _workspaceSelections[(projectId, selection.assetType)] =
          selection.assetId;
    }
    state = selection;
  }

  /// Session-local navigation memory; it neither duplicates nor edits assets.
  /// The caller supplies the current project catalog to reject deleted ids.
  void selectWorkspace({
    required String projectId,
    required AssetType type,
    required Iterable<String> availableAssetIds,
  }) {
    focusWorkspace(projectId: projectId, type: type);
    final ids = availableAssetIds.toList(growable: false);
    final key = (projectId, type);
    final remembered = _workspaceSelections[key];
    final id = ids.contains(remembered) ? remembered : ids.firstOrNull;
    if (id == null) {
      _workspaceSelections.remove(key);
      clear();
      return;
    }
    select(SelectionModel(assetId: id, assetType: type, projectId: projectId));
  }

  void clear() => state = null;

  /// Whether a workspace still carries a remembered asset id. The Explorer
  /// catalog recovery uses this to skip scheduling a restore microtask for
  /// a successful empty catalog that has nothing left to discard (vs-hunt
  /// -20260914-explorer-selection BUG-2): the empty-ids branch below must
  /// only run when a stale/deleted remembered entry actually needs to be
  /// removed, so an empty workspace never mutates providers from a queued
  /// microtask.
  bool remembersWorkspace({
    required String projectId,
    required AssetType type,
  }) => _workspaceSelections.containsKey((projectId, type));

  void focusWorkspace({required String projectId, required AssetType type}) {
    ref.read(workspaceIntentProvider.notifier).state = (projectId, type);
    if (state?.projectId != projectId || state?.assetType != type) clear();
  }
}

final selectionProvider =
    NotifierProvider<SelectionController, SelectionModel?>(
      SelectionController.new,
    );
