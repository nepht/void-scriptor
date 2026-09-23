import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';
import 'package:void_scriptor/features/workspace_layout/application/layout_controller.dart';
import 'package:void_scriptor/features/workspace_layout/application/workspace_tab_controller.dart';
import 'package:void_scriptor/features/workspace_layout/domain/layout_model.dart';
import 'package:void_scriptor/features/workspace_layout/domain/layout_preset.dart';
import 'package:void_scriptor/features/workspace_layout/domain/workspace_tab.dart';

void main() {
  group('LayoutController', () {
    test('starts at defaults', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(layoutProvider), PanelLayout.defaults);
    });

    test('setLeftWidth respects the compact shell bounds', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(layoutProvider.notifier);

      notifier.setLeftWidth(300); // within the 240 / 280 desktop shell bounds
      expect(container.read(layoutProvider).leftWidth, 300);

      notifier.setLeftWidth(10); // below min
      expect(container.read(layoutProvider).leftWidth, 176);
    });

    test('toggleLeft flips collapsed state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(layoutProvider.notifier);

      notifier.toggleLeft();
      expect(container.read(layoutProvider).leftCollapsed, isTrue);

      notifier.toggleLeft();
      expect(container.read(layoutProvider).leftCollapsed, isFalse);
    });

    test('setSplitRatio clamps to [0.25, 0.75]', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(layoutProvider.notifier);

      notifier.setSplitRatio(0.6);
      expect(container.read(layoutProvider).splitRatio, 0.6);

      notifier.setSplitRatio(0.01); // below min
      expect(container.read(layoutProvider).splitRatio, 0.25);

      notifier.setSplitRatio(0.99); // above max
      expect(container.read(layoutProvider).splitRatio, 0.75);
    });

    test('applyPreset replaces layout', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(layoutProvider.notifier);

      const preset = LayoutPreset(
        name: 'Narrow',
        layout: PanelLayout(
          leftWidth: 200,
          rightWidth: 250,
          leftCollapsed: true,
          rightCollapsed: false,
          splitRatio: 0.5,
        ),
      );
      notifier.applyPreset(preset);
      expect(container.read(layoutProvider), preset.layout);
    });
  });

  group('WorkspaceTabController', () {
    const tabA = WorkspaceTab(
      id: 'tab-a',
      assetId: 'asset-a',
      assetType: AssetType.character,
      title: 'Qowner',
    );
    const tabB = WorkspaceTab(
      id: 'tab-b',
      assetId: 'asset-b',
      assetType: AssetType.weapon,
      title: 'Dagger',
    );

    test('open adds a tab and activates it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(workspaceTabsProvider.notifier);

      notifier.open(tabA);
      final state = container.read(workspaceTabsProvider);
      expect(state.tabs.length, 1);
      expect(state.activeTabId, 'tab-a');
    });

    test('open dedups by id (same id -> activate, no duplicate)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(workspaceTabsProvider.notifier);

      notifier.open(tabA);
      notifier.open(tabB);
      notifier.open(tabA); // already open -> activate
      final state = container.read(workspaceTabsProvider);
      expect(state.tabs.length, 2);
      expect(state.activeTabId, 'tab-a');
    });

    test('close active tab activates a neighbor', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(workspaceTabsProvider.notifier);

      notifier.open(tabA);
      notifier.open(tabB); // active = tab-b
      notifier.close('tab-b');
      final state = container.read(workspaceTabsProvider);
      expect(state.tabs.length, 1);
      expect(state.activeTabId, 'tab-a');
    });

    test('closeOthers keeps only the given tab', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(workspaceTabsProvider.notifier);

      notifier.open(tabA);
      notifier.open(tabB);
      notifier.closeOthers('tab-a');
      final state = container.read(workspaceTabsProvider);
      expect(state.tabs.map((t) => t.id), ['tab-a']);
    });

    test('closeAll empties tabs', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(workspaceTabsProvider.notifier);

      notifier.open(tabA);
      notifier.open(tabB);
      notifier.closeAll();
      final state = container.read(workspaceTabsProvider);
      expect(state.tabs, isEmpty);
      expect(state.activeTabId, isNull);
    });
  });
}
