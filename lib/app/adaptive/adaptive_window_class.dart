abstract final class VoidBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1440;
}

enum AdaptiveWindowClass {
  phone,
  tablet,
  compactDesktop,
  desktop;

  static AdaptiveWindowClass fromWidth(double width) {
    if (width < VoidBreakpoints.mobile) return phone;
    if (width < VoidBreakpoints.tablet) return tablet;
    if (width < VoidBreakpoints.desktop) return compactDesktop;
    return desktop;
  }
}
