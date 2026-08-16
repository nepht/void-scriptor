import 'package:flutter/material.dart';

/// Idea list (Step 40.17).
class IdeaList extends StatelessWidget {
  const IdeaList({super.key, required this.ideas});

  final List<String> ideas;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final idea in ideas)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(idea),
          ),
      ],
    );
  }
}
