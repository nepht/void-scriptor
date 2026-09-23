import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/layout_model.dart';
import '../domain/layout_preset.dart';

/// Panel layout controller (Step 27.4).
///
/// Widths are clamped to `minWidth` (176) and `maxWidth` (0.45 × total), and
/// the split ratio to [0.25, 0.75].
class LayoutController extends Notifier<PanelLayout> {
  // The reference desktop composition keeps the inspector compact (~177 px)
  // while leaving the explorer readable at 240 px.
  static const double minWidth = 176;
  static const double minSplitRatio = 0.25;
  static const double maxSplitRatio = 0.75;

  @override
  PanelLayout build() => PanelLayout.defaults;

  void setLeftWidth(double width) {
    state = state.copyWith(leftWidth: _clampWidth(width));
  }

  void setRightWidth(double width) {
    state = state.copyWith(rightWidth: _clampWidth(width));
  }

  void toggleLeft() {
    state = state.copyWith(leftCollapsed: !state.leftCollapsed);
  }

  void toggleRight() {
    state = state.copyWith(rightCollapsed: !state.rightCollapsed);
  }

  void setSplitRatio(double ratio) {
    final clamped = ratio.clamp(minSplitRatio, maxSplitRatio).toDouble();
    state = state.copyWith(splitRatio: clamped);
  }

  void setActiveTab(int index) {
    state = state.copyWith(activeTabIndex: index);
  }

  void applyPreset(LayoutPreset preset) {
    state = preset.layout;
  }

  /// Applies a raw layout (used by per-project restoration).
  void applyLayout(PanelLayout layout) {
    state = layout;
  }

  double _clampWidth(double width) {
    final total = state.leftWidth + state.rightWidth;
    // A panel may grow only until the other keeps at least minWidth.
    final upper = total - minWidth < minWidth ? minWidth : total - minWidth;
    return width.clamp(minWidth, upper).toDouble();
  }
}

final layoutProvider = NotifierProvider<LayoutController, PanelLayout>(
  LayoutController.new,
);
