import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../assets/presentation/widgets/asset_thumbnail_card.dart';
import '../domain/wardrobe_model.dart';
import '../domain/wardrobe_workspace_data.dart';
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
    // vs-hunt-20260914-wardrobe-weapon WBUG-5: child rows come from the
    // repository; the detail cards are data-driven with honest empty states.
    final details =
        ref.watch(wardrobeWorkspaceDetailsProvider(wardrobeId)).valueOrNull ??
        const WardrobeWorkspaceData();
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
                      ? _DesktopWardrobe(
                          wardrobeId: wardrobeId,
                          model: model,
                          details: details,
                        )
                      : _CompactWardrobe(
                          wardrobeId: wardrobeId,
                          model: model,
                          details: details,
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Widget _wardrobeSpecification(WardrobeModel? model) =>
    WardrobeSpecificationCard(
      category: wardrobeValue(model?.category),
      material: wardrobeValue(model?.primaryMaterial),
      fabric: wardrobeValue(model?.fabric),
      fit: wardrobeValue(model?.fit),
      style: wardrobeValue(model?.style),
    );

class _DesktopWardrobe extends StatelessWidget {
  const _DesktopWardrobe({
    required this.wardrobeId,
    required this.model,
    required this.details,
  });
  final String wardrobeId;
  final WardrobeModel? model;
  final WardrobeWorkspaceData details;

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
          Expanded(child: _wardrobeSpecification(model)),
        ],
      ),
      const SizedBox(height: 16),
      WardrobeComponentsCard(components: details.components),
      const SizedBox(height: 16),
      WardrobeColorPaletteCard(colors: details.colors),
      const SizedBox(height: 16),
      WardrobeMaterialCard(components: details.components),
      const SizedBox(height: 16),
      WardrobeVariantsCard(variants: details.variants),
      const SizedBox(height: 16),
      WardrobeReferencesCard(references: details.references),
    ],
  );
}

class _CompactWardrobe extends StatelessWidget {
  const _CompactWardrobe({
    required this.wardrobeId,
    required this.model,
    required this.details,
  });
  final String wardrobeId;
  final WardrobeModel? model;
  final WardrobeWorkspaceData details;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AssetThumbnailCard(
        assetId: wardrobeId,
        title: 'Product View',
        placeholderIcon: Icons.checkroom_outlined,
      ),
      _wardrobeSpecification(model),
      WardrobeComponentsCard(components: details.components),
      WardrobeColorPaletteCard(colors: details.colors),
      WardrobeMaterialCard(components: details.components),
      WardrobeVariantsCard(variants: details.variants),
      WardrobeReferencesCard(references: details.references),
    ],
  );
}
