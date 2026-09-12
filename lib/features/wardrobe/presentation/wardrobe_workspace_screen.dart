import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../assets/presentation/widgets/asset_thumbnail_card.dart';
import '../domain/wardrobe_model.dart';
import 'wardrobe_workspace_controller.dart';
import 'widgets/wardrobe_detail_cards.dart';
import 'widgets/wardrobe_header.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class WardrobeWorkspaceScreen extends ConsumerWidget {
  const WardrobeWorkspaceScreen({super.key, required this.wardrobeId});
  final String wardrobeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wardrobeWorkspaceProvider(wardrobeId));
    final model = state.valueOrNull;
    return Container(
      color: context.palette.backgroundSecondary,
      child: Column(
        children: [
          WardrobeHeader(
            name: model?.name ?? wardrobeId,
            category: model?.category.isNotEmpty == true
                ? model!.category
                : 'Wardrobe Detail',
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1000;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: wide
                      ? _DesktopWardrobe(wardrobeId: wardrobeId, model: model)
                      : _CompactWardrobe(wardrobeId: wardrobeId, model: model),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopWardrobe extends StatelessWidget {
  const _DesktopWardrobe({required this.wardrobeId, required this.model});
  final String wardrobeId;
  final WardrobeModel? model;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 300,
            child: AssetThumbnailCard(
              assetId: wardrobeId,
              title: 'Product View',
              placeholderIcon: Icons.checkroom_outlined,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: WardrobeSpecificationCard(
              category: model?.category ?? 'Outerwear',
              material: model?.primaryMaterial ?? 'Technical Synthetic',
              fabric: model?.fabric ?? 'Waterproof Fabric',
              fit: model?.fit ?? 'Oversized',
              style: model?.style ?? 'Futuristic Tactical',
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      const WardrobeComponentsCard(),
      const SizedBox(height: 16),
      const WardrobeColorPaletteCard(),
      const SizedBox(height: 16),
      const WardrobeMaterialCard(),
      const SizedBox(height: 16),
      const WardrobeVariantsCard(),
      const SizedBox(height: 16),
      const WardrobeReferencesCard(),
    ],
  );
}

class _CompactWardrobe extends StatelessWidget {
  const _CompactWardrobe({required this.wardrobeId, required this.model});
  final String wardrobeId;
  final WardrobeModel? model;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AssetThumbnailCard(
        assetId: wardrobeId,
        title: 'Product View',
        placeholderIcon: Icons.checkroom_outlined,
      ),
      WardrobeSpecificationCard(
        category: model?.category ?? 'Outerwear',
        material: model?.primaryMaterial ?? 'Technical Synthetic',
        fabric: model?.fabric ?? 'Waterproof Fabric',
        fit: model?.fit ?? 'Oversized',
        style: model?.style ?? 'Futuristic Tactical',
      ),
      const WardrobeComponentsCard(),
      const WardrobeColorPaletteCard(),
      const WardrobeMaterialCard(),
      const WardrobeVariantsCard(),
      const WardrobeReferencesCard(),
    ],
  );
}
