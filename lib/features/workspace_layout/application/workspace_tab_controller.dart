import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/workspace_tab.dart';

/// Multi-tab workspace state (Step 27.5).
class WorkspaceTabsState {
  const WorkspaceTabsState({required this.tabs, required this.activeTabId});

  final List<WorkspaceTab> tabs;
  final String? activeTabId;
}

class WorkspaceTabController extends Notifier<WorkspaceTabsState> {
  @override
  WorkspaceTabsState build() =>
      const WorkspaceTabsState(tabs: [], activeTabId: null);

  void open(WorkspaceTab tab) {
    final existing = state.tabs.any((t) => t.id == tab.id);
    if (existing) {
      state = WorkspaceTabsState(tabs: state.tabs, activeTabId: tab.id);
      return;
    }
    state = WorkspaceTabsState(tabs: [...state.tabs, tab], activeTabId: tab.id);
  }

  void close(String id) {
    final index = state.tabs.indexWhere((t) => t.id == id);
    if (index < 0) return;

    final tabs = [...state.tabs]..removeAt(index);
    String? nextActive = state.activeTabId;
    if (state.activeTabId == id) {
      if (tabs.isEmpty) {
        nextActive = null;
      } else {
        // activate the neighbor: prefer the tab that took this index
        final neighborIndex = index.clamp(0, tabs.length - 1);
        nextActive = tabs[neighborIndex].id;
      }
    }
    state = WorkspaceTabsState(tabs: tabs, activeTabId: nextActive);
  }

  void closeOthers(String id) {
    final keep = state.tabs.where((t) => t.id == id).toList();
    state = WorkspaceTabsState(tabs: keep, activeTabId: id);
  }

  void closeAll() {
    state = const WorkspaceTabsState(tabs: [], activeTabId: null);
  }

  void activate(String id) {
    if (state.tabs.any((t) => t.id == id)) {
      state = WorkspaceTabsState(tabs: state.tabs, activeTabId: id);
    }
  }
}

final workspaceTabsProvider =
    NotifierProvider<WorkspaceTabController, WorkspaceTabsState>(
      WorkspaceTabController.new,
    );
