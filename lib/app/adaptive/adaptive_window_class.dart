enum AdaptiveWindowClass {
  compact,
  medium,
  expanded;

  static AdaptiveWindowClass fromWidth(double width) {
    if (width < 600) return compact;
    if (width < 1200) return medium;
    return expanded;
  }
}
