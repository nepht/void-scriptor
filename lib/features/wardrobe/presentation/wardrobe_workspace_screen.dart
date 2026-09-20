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
  const WardrobeWorkspaceScreen({
    super.key,
    required this.wardrobeId,
    this.activeSection,
  });
  final String wardrobeId;
  final String? activeSection;

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
                      ? _WardrobeSection(
                          section: activeSection,
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

class _WardrobeSection extends StatelessWidget {
  const _WardrobeSection({
    required this.section,
    required this.wardrobeId,
    required this.model,
    required this.details,
  });

  final String? section;
  final String wardrobeId;
  final WardrobeModel? model;
  final WardrobeWorkspaceData details;

  @override
  Widget build(BuildContext context) {
    switch (section) {
      case 'References':
        final closeUps = details.references.where((reference) {
          final type = reference.referenceType.toLowerCase();
          return type.contains('detail') ||
              type.contains('close') ||
              type.contains('texture');
        }).toList();
        final orthographic = details.references
            .where((reference) => !closeUps.contains(reference))
            .toList();
        return Column(
          children: [
            WardrobeReferenceGalleryCard(
              title: 'Orthographic Garment Views',
              references: orthographic,
              emptyText: 'Belum ada referensi tersimpan.',
            ),
            const SizedBox(height: 12),
            WardrobeReferenceGalleryCard(
              title: 'Close Up Detail',
              references: closeUps,
              emptyText: 'Belum ada referensi close-up yang ditautkan.',
            ),
          ],
        );
      case 'Variants':
        return WardrobeVariantsCard(variants: details.variants);
      default:
        return _DesktopWardrobe(
          wardrobeId: wardrobeId,
          model: model,
          details: details,
        );
    }
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
  Widget build(BuildContext context) {
    final closeUps = details.references.where((reference) {
      final type = reference.referenceType.toLowerCase();
      return type.contains('detail') ||
          type.contains('close') ||
          type.contains('texture');
    }).toList();
    final orthographic = details.references
        .where((reference) => !closeUps.contains(reference))
        .toList();
    final accessories = details.components.where((component) {
      final type = component.componentType.toLowerCase();
      return type.contains('accessory') ||
          type.contains('jewel') ||
          type.contains('ornament');
    }).toList();

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: WardrobeSpecificationCard(
                title: 'Outfit Concept',
                description: model?.description,
                category: wardrobeValue(model?.category),
                material: wardrobeValue(model?.primaryMaterial),
                fabric: wardrobeValue(model?.fabric),
                fit: wardrobeValue(model?.fit),
                style: wardrobeValue(model?.style),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 320,
              child: AssetThumbnailCard(
                assetId: wardrobeId,
                title: 'Product View',
                placeholderIcon: Icons.checkroom_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: WardrobeReferenceGalleryCard(
                title: 'Orthographic Garment Views',
                references: orthographic,
                emptyText: details.references.isEmpty
                    ? 'Belum ada referensi tersimpan.'
                    : 'Belum ada tampak front, side, back, atau inside yang ditautkan.',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: WardrobeComponentsCard(
                title: 'Wardrobe Components',
                components: details.components,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: WardrobeMaterialCard(
                title: 'Material & Fabric',
                components: details.components,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: WardrobeColorPaletteCard(colors: details.colors)),
            const SizedBox(width: 12),
            Expanded(
              child: WardrobeComponentsCard(
                title: 'Accessories',
                components: accessories,
                emptyText: 'Belum ada aksesori tersimpan.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: WardrobeBoardPanel(
                title: 'Dimensions & Construction Notes',
                child: Text(
                  model?.notes.isNotEmpty == true
                      ? model!.notes
                      : 'Belum ada dimensi atau catatan konstruksi tersimpan.',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: WardrobeVariantsCard(variants: details.variants)),
          ],
        ),
        const SizedBox(height: 12),
        WardrobeReferenceGalleryCard(
          title: 'Close Up Detail',
          references: closeUps,
          emptyText: 'Belum ada referensi close-up yang ditautkan.',
        ),
      ],
    );
  }
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
