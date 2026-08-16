import 'dart:convert';

import 'package:flutter/material.dart';

import '../domain/plugin_manifest.dart';

/// Dialog to paste a plugin manifest JSON and validate it (Step 31.17).
class PluginInstallDialog extends StatefulWidget {
  const PluginInstallDialog({super.key});

  @override
  State<PluginInstallDialog> createState() => _PluginInstallDialogState();
}

class _PluginInstallDialogState extends State<PluginInstallDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _install() {
    setState(() => _error = null);
    try {
      final json = jsonDecode(_controller.text) as Map<String, dynamic>;
      final manifest = PluginManifest.fromJson(json);
      Navigator.of(context).pop(manifest);
    } on Exception catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Instal Plugin'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Tempel JSON manifest plugin…',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _install, child: const Text('Instal')),
      ],
    );
  }
}
