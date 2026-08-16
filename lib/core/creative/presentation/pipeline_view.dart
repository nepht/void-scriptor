import 'package:flutter/material.dart';

/// Pipeline stage view (Step 40.18).
class PipelineView extends StatelessWidget {
  const PipelineView({super.key, required this.stages});

  final List<String> stages;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final stage in stages)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(stage),
          ),
      ],
    );
  }
}
