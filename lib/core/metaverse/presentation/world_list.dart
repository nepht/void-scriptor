import 'package:flutter/material.dart';

/// World list (Step 42.17).
class WorldList extends StatelessWidget {
  const WorldList({super.key, required this.worlds});

  final List<String> worlds;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final world in worlds)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(world),
          ),
      ],
    );
  }
}
