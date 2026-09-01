import 'package:flutter/material.dart';

import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';

/// Private, project-local notes for a character (145.25 Character Workspace
/// Core). Edits stay local until Save is pressed; the parent wires onSave to
/// the scoped identity update command.
class CharacterPrivateNotesCard extends StatefulWidget {
  const CharacterPrivateNotesCard({
    super.key,
    required this.initialNotes,
    required this.onSave,
  });

  final String initialNotes;
  final Future<void> Function(String notes) onSave;

  @override
  State<CharacterPrivateNotesCard> createState() =>
      _CharacterPrivateNotesCardState();
}

class _CharacterPrivateNotesCardState extends State<CharacterPrivateNotesCard> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialNotes,
  );
  String _lastSynced = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _lastSynced = widget.initialNotes;
  }

  @override
  void didUpdateWidget(CharacterPrivateNotesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Adopt external updates (e.g. provider reload) only when the user has
    // no unsaved local edits, so typing is never clobbered mid-edit.
    if (widget.initialNotes != _lastSynced &&
        _controller.text.trim() == _lastSynced) {
      _controller.text = widget.initialNotes;
      _lastSynced = widget.initialNotes;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(_controller.text.trim());
      _lastSynced = _controller.text.trim();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => VoidCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Character Private Notes',
          style: VoidTypography.headingMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Private project notes; never sent to AI providers.',
          style: VoidTypography.caption,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Place your private notes here',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
