import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/asset_type.dart';
import 'selection_model.dart';

/// Navigation intent is independent of whether a workspace contains assets.
final workspaceIntentProvider = StateProvider<(String, AssetType)?>(
  (ref) => null,
);

class SelectionController extends Notifier<SelectionModel?> {
  final _workspaceSelections = <(String, AssetType), String>{};
  @override
  SelectionModel? build() => null;

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
