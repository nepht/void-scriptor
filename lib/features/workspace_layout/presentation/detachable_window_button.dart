import 'package:flutter/material.dart';

/// Detachable-window affordance (Step 27.19).
///
/// True multi-window requires the plugin-based windowing service which is not
/// part of Sprint 27; this scaffold shows an honest "not yet available" message
/// rather than a silent no-op.
class DetachableWindowButton extends StatelessWidget {
  const DetachableWindowButton({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('detach-window'),
      icon: const Icon(Icons.open_in_new, size: 16),
      tooltip: 'Detach $label to a new window',
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Detached windows are coming in a later sprint. '
              '$label stays in the main window for now.',
            ),
          ),
        );
      },
    );
  }
}
