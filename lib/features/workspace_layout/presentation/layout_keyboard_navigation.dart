import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Layout keyboard navigation (Step 27.8).
///
/// Maps keyboard shortcuts to focus/intent actions. The binding map is consumed
/// by `WorkspaceLayoutShell` through `Shortcuts`/`Actions`; callers register the
/// corresponding `CallbackAction` per intent.

class FocusExplorerIntent extends Intent {
  const FocusExplorerIntent();
}

class FocusWorkspaceIntent extends Intent {
  const FocusWorkspaceIntent();
}

class FocusInspectorIntent extends Intent {
  const FocusInspectorIntent();
}

class CloseTabIntent extends Intent {
  const CloseTabIntent();
}

class CloseOtherTabsIntent extends Intent {
  const CloseOtherTabsIntent();
}

class ToggleFullscreenIntent extends Intent {
  const ToggleFullscreenIntent();
}

class OpenLayoutMenuIntent extends Intent {
  const OpenLayoutMenuIntent();
}

/// The documented shortcut combos for Sprint 27.
abstract final class LayoutShortcutKeys {
  static const focusExplorer = SingleActivator(
    LogicalKeyboardKey.digit1,
    control: true,
  );
  static const focusWorkspace = SingleActivator(
    LogicalKeyboardKey.digit2,
    control: true,
  );
  static const focusInspector = SingleActivator(
    LogicalKeyboardKey.digit3,
    control: true,
  );
  static const closeTab = SingleActivator(
    LogicalKeyboardKey.keyW,
    control: true,
  );
  static const closeOtherTabs = SingleActivator(
    LogicalKeyboardKey.keyW,
    control: true,
    shift: true,
  );
  static const toggleFullscreen = SingleActivator(LogicalKeyboardKey.f11);
  static const openLayoutMenu = SingleActivator(
    LogicalKeyboardKey.keyL,
    control: true,
    shift: true,
  );
}

/// Shortcut → intent bindings for the layout shell.
final Map<ShortcutActivator, Intent> layoutKeyboardBindings = {
  LayoutShortcutKeys.focusExplorer: const FocusExplorerIntent(),
  LayoutShortcutKeys.focusWorkspace: const FocusWorkspaceIntent(),
  LayoutShortcutKeys.focusInspector: const FocusInspectorIntent(),
  LayoutShortcutKeys.closeTab: const CloseTabIntent(),
  LayoutShortcutKeys.closeOtherTabs: const CloseOtherTabsIntent(),
  LayoutShortcutKeys.toggleFullscreen: const ToggleFullscreenIntent(),
  LayoutShortcutKeys.openLayoutMenu: const OpenLayoutMenuIntent(),
};
