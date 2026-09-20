import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../assets/presentation/supporting_asset_workspace_screen.dart';
import '../widgets/reference_inspector_panel.dart';

class ItemInspector extends ConsumerWidget {
  const ItemInspector({super.key, required this.itemId});
  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = ref.watch(supportingAssetProvider(itemId)).valueOrNull;
    if (asset == null) {
      return const ReferenceInspectorPanel(
        properties: [InspectorProperty('Status', 'Loading')],
      );
    }
    return ReferenceInspectorPanel(
      properties: [
        InspectorProperty('Name', asset.name),
        InspectorProperty('ID', asset.id),
        const InspectorProperty('Type', 'Item'),
        InspectorProperty('Status', asset.version),
      ],
      quickNotes: asset.description,
      linkedAssets: const [
        InspectorAssetCount('States', '—', Icons.change_circle_outlined),
        InspectorAssetCount('References', '—', Icons.description_outlined),
      ],
    );
  }
}
