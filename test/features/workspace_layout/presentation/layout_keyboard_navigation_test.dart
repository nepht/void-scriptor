import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/workspace_layout/presentation/layout_keyboard_navigation.dart';

void main() {
  test('exposes intent + shortcut bindings for focus navigation', () {
    final bindings = layoutKeyboardBindings;
    expect(bindings, isNotEmpty);

    // Focus navigation
    expect(
      bindings[LayoutShortcutKeys.focusExplorer],
      const FocusExplorerIntent(),
    );
    expect(
      bindings[LayoutShortcutKeys.focusWorkspace],
      const FocusWorkspaceIntent(),
    );
    expect(
      bindings[LayoutShortcutKeys.focusInspector],
      const FocusInspectorIntent(),
    );

    // Tab management + fullscreen
    expect(bindings[LayoutShortcutKeys.closeTab], const CloseTabIntent());
    expect(
      bindings[LayoutShortcutKeys.closeOtherTabs],
      const CloseOtherTabsIntent(),
    );
    expect(
      bindings[LayoutShortcutKeys.toggleFullscreen],
      const ToggleFullscreenIntent(),
    );
    expect(
      bindings[LayoutShortcutKeys.openLayoutMenu],
      const OpenLayoutMenuIntent(),
    );
  });

  test('shortcut keys use the documented combos', () {
    expect(
      LayoutShortcutKeys.focusExplorer,
      const SingleActivator(LogicalKeyboardKey.digit1, control: true),
    );
    expect(
      LayoutShortcutKeys.focusWorkspace,
      const SingleActivator(LogicalKeyboardKey.digit2, control: true),
    );
    expect(
      LayoutShortcutKeys.focusInspector,
      const SingleActivator(LogicalKeyboardKey.digit3, control: true),
    );
    expect(
      LayoutShortcutKeys.closeTab,
      const SingleActivator(LogicalKeyboardKey.keyW, control: true),
    );
    expect(
      LayoutShortcutKeys.closeOtherTabs,
      const SingleActivator(
        LogicalKeyboardKey.keyW,
        control: true,
        shift: true,
      ),
    );
    expect(
      LayoutShortcutKeys.toggleFullscreen,
      const SingleActivator(LogicalKeyboardKey.f11),
    );
    expect(
      LayoutShortcutKeys.openLayoutMenu,
      const SingleActivator(
        LogicalKeyboardKey.keyL,
        control: true,
        shift: true,
      ),
    );
  });
}
