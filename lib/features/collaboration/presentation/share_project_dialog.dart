import 'package:flutter/material.dart';

import '../domain/collaborator.dart';

/// Dialog to invite a collaborator with a role (Step 29.17).
class ShareProjectDialog extends StatefulWidget {
  const ShareProjectDialog({super.key, required this.onInvite});

  final void Function(String email, CollaboratorRole role) onInvite;

  @override
  State<ShareProjectDialog> createState() => _ShareProjectDialogState();
}

class _ShareProjectDialogState extends State<ShareProjectDialog> {
  final _controller = TextEditingController();
  CollaboratorRole _role = CollaboratorRole.viewer;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Share Project'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<CollaboratorRole>(
            initialValue: _role,
            decoration: const InputDecoration(labelText: 'Role'),
            items: CollaboratorRole.values
                .map(
                  (role) =>
                      DropdownMenuItem(value: role, child: Text(role.name)),
                )
                .toList(),
            onChanged: (value) => setState(() => _role = value ?? _role),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onInvite(_controller.text.trim(), _role);
            Navigator.of(context).pop();
          },
          child: const Text('Invite'),
        ),
      ],
    );
  }
}
