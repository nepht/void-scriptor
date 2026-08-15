import 'package:flutter/material.dart';

import '../domain/ai_provider.dart';

/// Dropdown for selecting a model (Step 28.11), showing model capabilities.
class ModelPicker extends StatelessWidget {
  const ModelPicker({
    super.key,
    required this.models,
    required this.selected,
    required this.onChanged,
  });

  final List<AiModelInfo> models;
  final String? selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = models.where((m) => m.id == selected).firstOrNull;
    return DropdownButton<String>(
      value: current?.id,
      hint: const Text('Select model'),
      onChanged: (id) {
        if (id != null) onChanged(id);
      },
      items: models
          .map(
            (model) => DropdownMenuItem<String>(
              value: model.id,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(model.displayName),
                  const SizedBox(width: 8),
                  if (model.capabilities.contains(AiCapability.visionInput))
                    const Icon(Icons.visibility, size: 14),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
