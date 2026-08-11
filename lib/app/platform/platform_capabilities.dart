enum AppTarget {
  windows,
  macos,
  linux,
  android,
  ios,
  web;

  bool get isDesktop => switch (this) {
    windows || macos || linux => true,
    android || ios || web => false,
  };
}

enum StudioMode { full, adaptive }

class PlatformCapabilities {
  const PlatformCapabilities({
    required this.studioMode,
    required this.supportsPersistentInspector,
    required this.supportsDesktopPlugins,
    required this.supportsLocalFileSystem,
  });

  factory PlatformCapabilities.forTarget(AppTarget target) {
    if (target.isDesktop) {
      return const PlatformCapabilities(
        studioMode: StudioMode.full,
        supportsPersistentInspector: true,
        supportsDesktopPlugins: true,
        supportsLocalFileSystem: true,
      );
    }

    return PlatformCapabilities(
      studioMode: StudioMode.adaptive,
      supportsPersistentInspector: false,
      supportsDesktopPlugins: false,
      supportsLocalFileSystem: target != AppTarget.web,
    );
  }

  final StudioMode studioMode;
  final bool supportsPersistentInspector;
  final bool supportsDesktopPlugins;
  final bool supportsLocalFileSystem;
}
