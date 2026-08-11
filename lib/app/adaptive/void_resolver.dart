import 'void_breakpoints.dart';
import 'void_device_type.dart';

VoidDeviceType resolveDeviceType(double width) {
  if (width < VoidBreakpoints.phone) {
    return VoidDeviceType.phone;
  }
  if (width < VoidBreakpoints.tablet) {
    return VoidDeviceType.tablet;
  }
  if (width < VoidBreakpoints.compactDesktop) {
    return VoidDeviceType.compactDesktop;
  }
  if (width < VoidBreakpoints.largeDesktop) {
    return VoidDeviceType.desktop;
  }
  return VoidDeviceType.largeDesktop;
}
