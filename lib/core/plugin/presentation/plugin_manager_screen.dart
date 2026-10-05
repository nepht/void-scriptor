import 'package:flutter/material.dart';

import '../domain/plugin_manifest.dart';

/// Lists installed plugins with enable/disable + status (Step 31.16).
class PluginManagerScreen extends StatelessWidget {
  const PluginManagerScreen({super.key, required this.plugins});

  final List<PluginDescriptor> plugins;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plugin Manager')),
      body: plugins.isEmpty
          ? const Center(child: Text('Belum ada plugin terpasang.'))
          : ListView.separated(
              itemCount: plugins.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final plugin = plugins[index];
                return ListTile(
                  leading: const Icon(Icons.extension),
                  title: Text(plugin.manifest.name),
                  subtitle: Text(
                    'v${plugin.manifest.version} · ${plugin.manifest.author}',
                  ),
                  trailing: Text(
                    plugin.status.name,
                    style: TextStyle(
                      color: plugin.status == PluginStatus.enabled
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
