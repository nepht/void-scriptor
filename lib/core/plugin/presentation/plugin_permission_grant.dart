import 'package:flutter/material.dart';

/// Displays a plugin's granted permissions (Step 31.18).
class PluginPermissionGrant extends StatelessWidget {
  const PluginPermissionGrant({super.key, required this.grantedPermissions});

  final List<String> grantedPermissions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Izin Plugin')),
      body: grantedPermissions.isEmpty
          ? const Center(child: Text('Tidak ada izin.'))
          : ListView(
              children: [
                for (final permission in grantedPermissions)
                  ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(permission),
                  ),
              ],
            ),
    );
  }
}
