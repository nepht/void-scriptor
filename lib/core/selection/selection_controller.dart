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
  bool _memoryHydrated = false;
  @override
  SelectionModel? build() => null;

  /// Replaces in-session workspace memory with persisted entries exactly
  /// once, before any user pick in this session. Stale persisted entries
  /// must never overwrite selections the user has already made.
  void hydrateWorkspaceMemory(SelectionMemorySnapshot persisted) {
    if (_memoryHydrated) return;
    _memoryHydrated = true;
    persisted.forEach((key, value) {
      _workspaceSelections.putIfAbsent(key, () => value);
    });
  }

  bool get isWorkspaceMemoryHydrated => _memoryHydrated;

  /// Copy of the live per-workspace memory for persistence.
  SelectionMemorySnapshot workspaceMemorySnapshot() =>
      Map<(String, AssetType), String>.of(_workspaceSelections);

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

  void focusWorkspace({required String projectId, required AssetType type}) {
    ref.read(workspaceIntentProvider.notifier).state = (projectId, type);
    if (state?.projectId != projectId || state?.assetType != type) clear();
  }
}

final selectionProvider =
    NotifierProvider<SelectionController, SelectionModel?>(
      SelectionController.new,
    );
