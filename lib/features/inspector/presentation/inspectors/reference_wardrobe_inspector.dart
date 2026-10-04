import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/reference_inspector_panel.dart';
import 'wardrobe_inspector.dart';

class ReferenceWardrobeInspector extends ConsumerWidget {
  const ReferenceWardrobeInspector({super.key, required this.wardrobeId});
  final String wardrobeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(wardrobeInspectorProvider(wardrobeId)).value;
    if (data == null) {
      return const ReferenceInspectorPanel(
        properties: [InspectorProperty('Status', 'Loading')],
      );
    }
    return ReferenceInspectorPanel(
      properties: [
        InspectorProperty('Name', data.name),
        InspectorProperty('ID', wardrobeId),
        InspectorProperty('Category', data.category),
        InspectorProperty('Material', data.material),
        InspectorProperty('Fabric', data.fabric),
        InspectorProperty('Fit', data.fit),
        InspectorProperty('Style', data.style),
      ],
      linkedAssets: [
        InspectorAssetCount(
          'Variants',
          data.variants.length.toString(),
          Icons.layers_outlined,
        ),
        InspectorAssetCount(
          'Relations',
          data.incomingRelationCount.toString(),
          Icons.link_outlined,
        ),
      ],
    );
  }
}
