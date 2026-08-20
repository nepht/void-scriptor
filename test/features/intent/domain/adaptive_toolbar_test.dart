import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/adaptive_toolbar.dart';

void main() {
  test('shows edit and save actions for an edited target', () {
    final actions = AdaptiveToolbar().actionsFor(
      const ToolbarContext(targetId: 'scene-1', intent: 'edit'),
    );

    expect(actions, const [
      ToolbarAction(command: 'save', targetId: 'scene-1'),
      ToolbarAction(command: 'undo', targetId: 'scene-1'),
    ]);
  });

  test('shows edit for a selected target', () {
    final actions = AdaptiveToolbar().actionsFor(
      const ToolbarContext(targetId: 'scene-1', intent: 'select'),
    );

    expect(actions, const [
      ToolbarAction(command: 'edit', targetId: 'scene-1'),
    ]);
  });

  test('does not expose destructive actions by default', () {
    final actions = AdaptiveToolbar().actionsFor(
      const ToolbarContext(targetId: 'scene-1', intent: 'delete'),
    );

    expect(actions.where((action) => action.isDestructive), isEmpty);
  });
}
