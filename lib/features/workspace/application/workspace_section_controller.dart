import 'package:flutter_riverpod/flutter_riverpod.dart';

enum WorkspaceKind { novel, character, worldbuilding, asset }

class WorkspaceSectionState {
  const WorkspaceSectionState([this._activeSections = const {}]);

  final Map<WorkspaceKind, String> _activeSections;

  String? activeFor(WorkspaceKind kind) => _activeSections[kind];

  WorkspaceSectionState activate(WorkspaceKind kind, String section) =>
      WorkspaceSectionState({..._activeSections, kind: section});
}

class WorkspaceSectionController extends Notifier<WorkspaceSectionState> {
  @override
  WorkspaceSectionState build() => const WorkspaceSectionState();

  void activate(WorkspaceKind kind, String section) {
    state = state.activate(kind, section);
  }
}

final workspaceSectionProvider =
    NotifierProvider<WorkspaceSectionController, WorkspaceSectionState>(
      WorkspaceSectionController.new,
    );
