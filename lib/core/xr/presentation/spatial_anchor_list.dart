import 'package:flutter/material.dart';

/// Spatial anchor list (Step 41.17).
class SpatialAnchorList extends StatelessWidget {
  const SpatialAnchorList({super.key, required this.anchors});

  final List<String> anchors;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final anchor in anchors)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(anchor),
          ),
      ],
    );
  }
}
