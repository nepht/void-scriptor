import 'package:flutter/material.dart';

import '../../design_system/colors/void_colors.dart';
import 'void_device_type.dart';
import 'void_resolver.dart';

class VoidAdaptiveScaffold extends StatelessWidget {
  const VoidAdaptiveScaffold({
    super.key,
    required this.body,
    required this.desktopSidebar,
    required this.mobileNavigation,
    this.inspector,
  });

  final Widget body;
  final Widget desktopSidebar;
  final Widget mobileNavigation;
  final Widget? inspector;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final device = resolveDeviceType(constraints.maxWidth);

        switch (device) {
          case VoidDeviceType.phone:
            return Scaffold(
              key: const Key('scaffold-phone'),
              backgroundColor: VoidColors.background,
              body: body,
              bottomNavigationBar: mobileNavigation,
            );
          case VoidDeviceType.tablet:
          case VoidDeviceType.compactDesktop:
            return Scaffold(
              key: const Key('scaffold-tablet-or-compact'),
              backgroundColor: VoidColors.background,
              body: Row(
                children: [
                  desktopSidebar,
                  Expanded(child: body),
                ],
              ),
            );
          case VoidDeviceType.desktop:
            return Scaffold(
              key: const Key('scaffold-desktop'),
              backgroundColor: VoidColors.background,
              body: Row(
                children: [
                  desktopSidebar,
                  Expanded(child: body),
                  if (inspector != null) inspector!,
                ],
              ),
            );
        }
      },
    );
  }
}
