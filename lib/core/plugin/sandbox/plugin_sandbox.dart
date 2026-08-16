import 'plugin_permission.dart';

class PluginPermissionDenied implements Exception {
  const PluginPermissionDenied(this.permission);
  final PluginPermission permission;
  @override
  String toString() => 'PluginPermissionDenied: $permission';
}

/// Guards plugin access to protected capabilities (Step 31.11).
class PluginSandbox {
  PluginSandbox({Set<PluginPermission>? granted})
    : _granted = granted ?? const {};

  final Set<PluginPermission> _granted;

  bool canAccess(PluginPermission permission) => _granted.contains(permission);

  void require(PluginPermission permission) {
    if (!canAccess(permission)) {
      throw PluginPermissionDenied(permission);
    }
  }
}
