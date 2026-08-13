import 'package:flutter/material.dart';

class SceneAssetPanel extends StatelessWidget {
  const SceneAssetPanel({
    super.key,
    required this.groups,
    required this.onAddAsset,
  });
  final Map<String, List<String>> groups;
  final VoidCallback onAddAsset;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'SCENE ASSETS',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              FilledButton.icon(
                onPressed: onAddAsset,
                icon: const Icon(Icons.add),
                label: const Text('Add Asset'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final group in groups.entries) ...[
            Text(group.key, style: Theme.of(context).textTheme.titleSmall),
            if (group.value.isEmpty)
              const Text('None')
            else
              Wrap(
                spacing: 8,
                children: [
                  for (final item in group.value) Chip(label: Text(item)),
                ],
              ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    ),
  );
}
