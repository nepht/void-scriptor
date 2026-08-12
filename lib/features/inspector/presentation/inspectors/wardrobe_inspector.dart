import 'package:flutter/material.dart';
import 'inspector_body.dart';

class WardrobeInspector extends StatelessWidget {
  const WardrobeInspector({super.key, required this.wardrobeId});
  final String wardrobeId;
  @override
  Widget build(BuildContext context) => InspectorBody(
    name: wardrobeId,
    type: 'Wardrobe',
    sections: const ['Properties', 'Material', 'Color', 'Relations'],
  );
}
