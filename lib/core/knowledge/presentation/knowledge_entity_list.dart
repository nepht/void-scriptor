import 'package:flutter/material.dart';

/// Knowledge entity list (Step 38.17).
class KnowledgeEntityList extends StatelessWidget {
  const KnowledgeEntityList({super.key, required this.entities});

  final List<String> entities;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final entity in entities)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(entity),
          ),
      ],
    );
  }
}
