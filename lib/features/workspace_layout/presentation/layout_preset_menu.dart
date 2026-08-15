import 'package:flutter/material.dart';

import '../domain/layout_preset.dart';

/// Dropdown menu for applying, saving, and deleting layout presets (Step 27.18).
class LayoutPresetMenu extends StatelessWidget {
  const LayoutPresetMenu({
    super.key,
    required this.presets,
    required this.activeName,
    required this.onApply,
    required this.onSave,
    required this.onDelete,
  });

  final List<LayoutPreset> presets;
  final String? activeName;
  final ValueChanged<String> onApply;
  final ValueChanged<String> onSave;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.dashboard_customize_outlined),
      tooltip: 'Layout presets',
      onSelected: (value) {
        if (value == '__save__') {
          _promptSave(context);
        } else {
          onApply(value);
        }
      },
      itemBuilder: (context) => [
        ...presets.map(
          (p) => PopupMenuItem<String>(
            value: p.name,
            child: Row(
              children: [
                Expanded(child: Text(p.name)),
                if (p.name == activeName) const Icon(Icons.check, size: 16),
                InkWell(
                  key: Key('delete-preset-${p.name}'),
                  onTap: () {
                    Navigator.of(context).pop();
                    onDelete(p.name);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: '__save__',
          child: Text('Save current layout'),
        ),
      ],
    );
  }

  Future<void> _promptSave(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save layout'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Layout name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      onSave(name);
    }
  }
}
