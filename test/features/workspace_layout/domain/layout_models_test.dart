import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';
import 'package:void_scriptor/features/workspace_layout/domain/layout_model.dart';
import 'package:void_scriptor/features/workspace_layout/domain/layout_preset.dart';
import 'package:void_scriptor/features/workspace_layout/domain/workspace_tab.dart';

void main() {
  group('PanelLayout', () {
    test(
      'defaults match character-sheet reference (240 / 177 / not collapsed)',
      () {
        const layout = PanelLayout.defaults;
        expect(layout.leftWidth, 240);
        expect(layout.rightWidth, 177);
        expect(layout.leftCollapsed, isFalse);
        expect(layout.rightCollapsed, isFalse);
        expect(layout.splitRatio, 0.5);
        expect(layout.activeTabIndex, 0);
      },
    );

    test('copyWith produces an independent immutable instance', () {
      const layout = PanelLayout.defaults;
      final resized = layout.copyWith(leftWidth: 300);

      expect(layout.leftWidth, 240);
      expect(resized.leftWidth, 300);
      expect(identical(layout, resized), isFalse);
    });

    test('value equality is based on fields', () {
      const a = PanelLayout.defaults;
      const b = PanelLayout.defaults;
      const c = PanelLayout(
        leftWidth: 240,
        rightWidth: 177,
        leftCollapsed: false,
        rightCollapsed: false,
        splitRatio: 0.5,
      );

      expect(a, b);
      expect(a, c);
      expect(a.hashCode, c.hashCode);
    });
  });

  group('WorkspaceTab', () {
    test('equals by id, not by asset fields', () {
      const a = WorkspaceTab(
        id: 'tab-1',
        assetId: 'asset-a',
        assetType: AssetType.character,
        title: 'Qowner',
      );
      const b = WorkspaceTab(
        id: 'tab-1',
        assetId: 'asset-b',
        assetType: AssetType.weapon,
        title: 'Dagger',
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('LayoutPreset', () {
    test('carries name + layout', () {
      const preset = LayoutPreset(name: 'Wide', layout: PanelLayout.defaults);
      expect(preset.name, 'Wide');
      expect(preset.layout, PanelLayout.defaults);
    });
  });
}
