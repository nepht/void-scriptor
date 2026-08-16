import '../domain/plugin_manifest.dart';

/// Permissions a plugin may request (Step 31.10).
enum PluginPermission {
  storage,
  network,
  ui,
  commands,
  projectData;

  static PluginPermission fromName(String name) {
    return PluginPermission.values.firstWhere(
      (p) => p.name == name,
      orElse: () =>
          throw ArgumentError.value(name, 'name', 'unknown permission'),
    );
  }
}

/// Validated permission set (Step 31.12).
class PluginPermissionSet {
  const PluginPermissionSet._(this.permissions);

  final Set<PluginPermission> permissions;

  static Set<PluginPermission> validate(List<String> names) {
    final result = <PluginPermission>{};
    for (final name in names) {
      try {
        result.add(PluginPermission.fromName(name));
      } on ArgumentError {
        throw PluginManifestException('unknown permission "$name"');
      }
    }
    return result;
  }
}
