/// Panel side for the dockable shell.
enum PanelSide { left, right }

/// Immutable panel layout state (Step 27.1).
class PanelLayout {
  const PanelLayout({
    required this.leftWidth,
    required this.rightWidth,
    required this.leftCollapsed,
    required this.rightCollapsed,
    required this.splitRatio,
    this.activeTabIndex = 0,
  });

  final double leftWidth;
  final double rightWidth;
  final bool leftCollapsed;
  final bool rightCollapsed;
  final double splitRatio;
  final int activeTabIndex;

  static const defaults = PanelLayout(
    leftWidth: 240,
    rightWidth: 177,
    leftCollapsed: false,
    rightCollapsed: false,
    splitRatio: 0.5,
  );

  PanelLayout copyWith({
    double? leftWidth,
    double? rightWidth,
    bool? leftCollapsed,
    bool? rightCollapsed,
    double? splitRatio,
    int? activeTabIndex,
  }) {
    return PanelLayout(
      leftWidth: leftWidth ?? this.leftWidth,
      rightWidth: rightWidth ?? this.rightWidth,
      leftCollapsed: leftCollapsed ?? this.leftCollapsed,
      rightCollapsed: rightCollapsed ?? this.rightCollapsed,
      splitRatio: splitRatio ?? this.splitRatio,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PanelLayout &&
      other.leftWidth == leftWidth &&
      other.rightWidth == rightWidth &&
      other.leftCollapsed == leftCollapsed &&
      other.rightCollapsed == rightCollapsed &&
      other.splitRatio == splitRatio &&
      other.activeTabIndex == activeTabIndex;

  @override
  int get hashCode => Object.hash(
    leftWidth,
    rightWidth,
    leftCollapsed,
    rightCollapsed,
    splitRatio,
    activeTabIndex,
  );
}
