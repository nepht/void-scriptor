import 'package:flutter/material.dart';

import '../domain/reference_models.dart';
import 'reference_library_screen.dart';

class ReferenceImportDialog extends StatefulWidget {
  const ReferenceImportDialog({super.key});

  @override
  State<ReferenceImportDialog> createState() => _ReferenceImportDialogState();
}

class _ReferenceImportDialogState extends State<ReferenceImportDialog> {
  final path = TextEditingController();
  final name = TextEditingController();
  final owner = TextEditingController();
  final description = TextEditingController();
  final priority = TextEditingController(text: '0');
  ReferenceType type = ReferenceType.face;
  bool primary = false;

  @override
  void dispose() {
    path.dispose();
    name.dispose();
    owner.dispose();
    description.dispose();
    priority.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Import Reference'),
    content: SingleChildScrollView(
      child: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: path,
              decoration: const InputDecoration(labelText: 'Source file path'),
            ),
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: owner,
              decoration: const InputDecoration(
                labelText: 'Owner asset ID (optional)',
              ),
            ),
            DropdownButtonFormField<ReferenceType>(
              initialValue: type,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Reference type'),
              items: ReferenceType.values
                  .map(
                    (item) =>
                        DropdownMenuItem(value: item, child: Text(item.name)),
                  )
                  .toList(growable: false),
              onChanged: (value) => setState(() => type = value ?? type),
            ),
            TextField(
              controller: priority,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Priority'),
            ),
            TextField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Set as primary'),
              value: primary,
              onChanged: (value) => setState(() => primary = value),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => _submit(context),
        child: const Text('Import'),
      ),
    ],
  );

  void _submit(BuildContext context) {
    if (path.text.trim().isEmpty || name.text.trim().isEmpty) return;
    Navigator.pop(
      context,
      ReferenceImportDraft(
        sourcePath: path.text.trim(),
        name: name.text.trim(),
        ownerAssetId: owner.text.trim().isEmpty ? null : owner.text.trim(),
        type: type,
        priority: int.tryParse(priority.text.trim()) ?? 0,
        primary: primary,
        description: description.text.trim(),
      ),
    );
  }
}
