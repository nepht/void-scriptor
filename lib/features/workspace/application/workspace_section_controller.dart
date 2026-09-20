import 'package:flutter_riverpod/flutter_riverpod.dart';

enum WorkspaceKind { novel, character, worldbuilding, asset }

/// Keep navigation requests from older sidebar entries usable.
String canonicalWorkspaceSection(WorkspaceKind kind, String section) =>
    switch ((kind, section)) {
      (WorkspaceKind.novel, 'Outline') => 'Planning',
      // Character workspace navigation uses the product vocabulary directly.
      (WorkspaceKind.character, 'Profile') => 'Overview',
      (WorkspaceKind.character, 'Identity') => 'Overview',
      (WorkspaceKind.character, 'Overview Character') => 'Overview',
      (WorkspaceKind.character, 'Appearance') => 'Wardrobe',
      (WorkspaceKind.character, 'Appearance & Gear') => 'Wardrobe',
      (WorkspaceKind.character, 'Weapon') => 'Weapons',
      (WorkspaceKind.character, 'Expressions') => 'Expressions Library',
      (WorkspaceKind.character, 'Relationships') => 'Relations',
      (WorkspaceKind.character, 'Companions & Carry') => 'Relations',
      (WorkspaceKind.worldbuilding, 'Location') => 'Location',
      (WorkspaceKind.worldbuilding, 'Locations') => 'Location',
      (WorkspaceKind.worldbuilding, 'Faction') => 'Faction',
      (WorkspaceKind.worldbuilding, 'Factions') => 'Faction',
      (WorkspaceKind.worldbuilding, 'Organizations') => 'Organizations',
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
