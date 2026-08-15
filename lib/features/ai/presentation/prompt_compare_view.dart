import 'package:flutter/material.dart';

import '../application/prompt_differ.dart';

/// Split-pane prompt version compare with restore (Step 28.20–28.21).
class PromptCompareView extends StatelessWidget {
  const PromptCompareView({
    super.key,
    required this.before,
    required this.after,
    required this.onRestore,
  });

  final String before;
  final String after;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final diff = const PromptDiffer().diff(before, after);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text('Changes'),
            const Spacer(),
            if (diff.changed)
              IconButton(
                onPressed: onRestore,
                icon: const Icon(Icons.restore),
                tooltip: 'Restore previous version',
              ),
          ],
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _Pane(label: 'Before', text: before),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: _Pane(
                  label: 'After',
                  text: after,
                  highlights: diff.added.toSet(),
                ),
              ),
            ],
          ),
        ),
        if (!diff.changed)
          const Padding(padding: EdgeInsets.all(8), child: Text('No changes')),
      ],
    );
  }
}

class _Pane extends StatelessWidget {
  const _Pane({
    required this.label,
    required this.text,
    this.highlights = const {},
  });

  final String label;
  final String text;
  final Set<String> highlights;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: SelectableText(text),
          ),
        ),
      ],
    );
  }
}
