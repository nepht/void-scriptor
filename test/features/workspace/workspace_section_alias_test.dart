import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/workspace/application/workspace_section_controller.dart';

void main() {
  test('legacy navigation maps to the current owning section', () {
    const state = WorkspaceSectionState();
    expect(
      state
          .activate(WorkspaceKind.novel, 'Outline')
          .activeFor(WorkspaceKind.novel),
      'Planning',
    );
    expect(
      state
          .activate(WorkspaceKind.character, 'Identity')
          .activeFor(WorkspaceKind.character),
      'Overview',
    );
    expect(
      state
          .activate(WorkspaceKind.character, 'Appearance & Gear')
          .activeFor(WorkspaceKind.character),
      'Wardrobe',
    );
    expect(
      state
          .activate(WorkspaceKind.character, 'Companions & Carry')
          .activeFor(WorkspaceKind.character),
      'Relations',
    );
    expect(
      state
          .activate(WorkspaceKind.novel, 'Export')
          .activeFor(WorkspaceKind.novel),
      'Export',
    );
  });
}
