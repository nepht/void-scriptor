import 'package:flutter_riverpod/flutter_riverpod.dart';

enum WorkspaceKind { novel, character, worldbuilding, asset }

/// Keep navigation requests from older sidebar entries usable.
String canonicalWorkspaceSection(WorkspaceKind kind, String section) =>
    switch ((kind, section)) {
      (WorkspaceKind.novel, 'Outline') => 'Planning',
      (WorkspaceKind.character, 'Identity') => 'Profile',
      (WorkspaceKind.character, 'Appearance & Gear') => 'Appearance',
      (WorkspaceKind.character, 'Companions & Carry') => 'Relationships',
      _ => section,
    };

class WorkspaceSectionState {
  const WorkspaceSectionState([this._activeSections = const {}]);

  final Map<WorkspaceKind, String> _activeSections;

  String? activeFor(WorkspaceKind kind) => _activeSections[kind];

  WorkspaceSectionState activate(WorkspaceKind kind, String section) =>
      WorkspaceSectionState({
        ..._activeSections,
        kind: canonicalWorkspaceSection(kind, section),
      });
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
