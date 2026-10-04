import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../assets/presentation/widgets/asset_thumbnail_card.dart';
import '../domain/weapon_model.dart';
import '../domain/weapon_workspace_data.dart';
import 'weapon_workspace_controller.dart';
import 'widgets/weapon_detail_cards.dart';
import 'widgets/weapon_header.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class WeaponWorkspaceScreen extends ConsumerWidget {
  const WeaponWorkspaceScreen({
    super.key,
    required this.weaponId,
    this.activeSection,
  });
  final String weaponId;
  final String? activeSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(weaponWorkspaceProvider(weaponId)).value;
    // vs-hunt-20260914-wardrobe-weapon WBUG-6: child rows come from the
    // repository; detail cards are data-driven with honest empty states.
    final details =
        ref.watch(weaponWorkspaceDetailsProvider(weaponId)).value ??
        const WeaponWorkspaceData();
    // WBUG-6: while a session/model is still resolving, scalar fields render
    // the dash placeholder — never invented sample numbers like '420 mm'.
    final specification = WeaponSpecificationData(
      type: weaponValue(model?.weaponType),
      length: weaponNumber(model?.lengthMm, 'mm'),
      weight: weaponNumber(model?.weightKg, 'kg'),
      material: weaponValue(model?.primaryMaterial),
      energy: weaponValue(model?.energyType),
    );
    return Container(
      color: context.palette.backgroundSecondary,
      child: Column(
        children: [
          WeaponHeader(
            name: model?.name ?? weaponId,
            type: _value(model?.weaponType, 'Weapon Detail'),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1000;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: wide
                      ? _WeaponSection(
                          section: activeSection,
                          weaponId: weaponId,
                          model: model,
                          specification: specification,
                          details: details,
                        )
                      : _WeaponCompact(
                          weaponId: weaponId,
                          model: model,
                          specification: specification,
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

  static String _value(String? value, String fallback) =>
      value == null || value.isEmpty ? fallback : value;
}

class _WeaponSection extends StatelessWidget {
  const _WeaponSection({
    required this.section,
    required this.weaponId,
    required this.model,
    required this.specification,
    required this.details,
  });

  final String? section;
  final String weaponId;
  final WeaponModel? model;
  final WeaponSpecificationData specification;
  final WeaponWorkspaceData details;

  @override
  Widget build(BuildContext context) {
    switch (section) {
      case 'Variants':
        return WeaponVariantsCard(variants: details.variants);
      case 'References':
        final detailReferences = details.references.where((reference) {
          final type = reference.referenceType.toLowerCase();
          return type.contains('detail') ||
              type.contains('close') ||
              type.contains('texture');
        }).toList();
        final explodedReferences = details.references.where((reference) {
          final type = reference.referenceType.toLowerCase();
          return type.contains('exploded') || type.contains('component');
        }).toList();
        final orthographic = details.references
            .where(
              (reference) =>
                  !detailReferences.contains(reference) &&
                  !explodedReferences.contains(reference),
            )
            .toList();
        return Column(
          children: [
            WeaponReferenceGalleryCard(
              title: 'Orthographic Views',
              references: orthographic,
              emptyText: 'Belum ada referensi tersimpan.',
            ),
            const SizedBox(height: 12),
            WeaponReferenceGalleryCard(
              title: 'Exploded View',
              references: explodedReferences,
              emptyText: 'Belum ada exploded reference yang ditautkan.',
            ),
            const SizedBox(height: 12),
            WeaponReferenceGalleryCard(
              title: 'Detail Panels',
              references: detailReferences,
              emptyText:
                  'Belum ada close-up component reference yang ditautkan.',
            ),
          ],
        );
      default:
        return _WeaponDesktop(
          weaponId: weaponId,
          model: model,
          specification: specification,
          details: details,
        );
    }
  }
}

class _WeaponDesktop extends StatelessWidget {
  const _WeaponDesktop({
    required this.weaponId,
    required this.model,
    required this.specification,
    required this.details,
  });
  final String weaponId;
  final WeaponModel? model;
  final WeaponSpecificationData specification;
  final WeaponWorkspaceData details;

  @override
  Widget build(BuildContext context) {
    final detailsReferences = details.references.where((reference) {
      final type = reference.referenceType.toLowerCase();
      return type.contains('detail') ||
          type.contains('close') ||
          type.contains('texture');
    }).toList();
    final explodedReferences = details.references.where((reference) {
      final type = reference.referenceType.toLowerCase();
      return type.contains('exploded') || type.contains('component');
    }).toList();
    final orthographic = details.references
        .where(
          (reference) =>
              !detailsReferences.contains(reference) &&
              !explodedReferences.contains(reference),
        )
        .toList();

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: WeaponSpecificationCard(
                title: 'Concept',
                description: model?.description,
                model: specification,
                showTechnicalFields: false,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 320,
              child: AssetThumbnailCard(
                assetId: weaponId,
                title: 'Technical View',
                placeholderIcon: Icons.auto_fix_high_outlined,
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
              child: WeaponReferenceGalleryCard(
                title: 'Orthographic Views',
                references: orthographic,
                emptyText: details.references.isEmpty
                    ? 'Belum ada referensi tersimpan.'
                    : 'Belum ada tampak front, side, back, atau 3/4 yang ditautkan.',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: WeaponReferenceGalleryCard(
                title: 'Exploded View',
                references: explodedReferences,
                emptyText: 'Belum ada exploded reference yang ditautkan.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        WeaponReferenceGalleryCard(
          title: 'Detail Panels',
          references: detailsReferences,
          emptyText: 'Belum ada close-up component reference yang ditautkan.',
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: WeaponBoardPanel(
                title: 'Material & Texture',
                child: Column(
                  children: [
                    _BoardValue(
                      label: 'Primary',
                      value: weaponValue(model?.primaryMaterial),
                    ),
                    _BoardValue(
                      label: 'Secondary',
                      value: weaponValue(model?.secondaryMaterial),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: WeaponColorPaletteCard(colors: details.colors)),
            const SizedBox(width: 12),
            Expanded(
              child: WeaponComponentsCard(
                title: 'Components',
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
              child: WeaponDimensionsCard(
                title: 'Dimensions & Construction',
                length: specification.length,
                weight: specification.weight,
                measurements: details.measurements,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: WeaponEnergyCard(
                title: 'Function / Combat Mode',
                energy: specification.energy,
                core: weaponValue(model?.coreType),
                profile: details.energy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: WeaponBoardPanel(
                title: 'Technical Notes',
                child: Text(
                  model?.notes.isNotEmpty == true
                      ? model!.notes
                      : 'Belum ada technical notes tersimpan.',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: WeaponVariantsCard(variants: details.variants)),
          ],
        ),
      ],
    );
  }
}

class _BoardValue extends StatelessWidget {
  const _BoardValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: TextStyle(color: context.palette.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: context.palette.textPrimary),
          ),
        ),
      ],
    ),
  );
}

class _WeaponCompact extends StatelessWidget {
  const _WeaponCompact({
    required this.weaponId,
    required this.model,
    required this.specification,
    required this.details,
  });
  final String weaponId;
  final WeaponModel? model;
  final WeaponSpecificationData specification;
  final WeaponWorkspaceData details;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AssetThumbnailCard(
        assetId: weaponId,
        title: 'Technical View',
        placeholderIcon: Icons.auto_fix_high_outlined,
      ),
      WeaponSpecificationCard(model: specification),
      WeaponComponentsCard(components: details.components),
      WeaponDimensionsCard(
        length: specification.length,
        weight: specification.weight,
        measurements: details.measurements,
      ),
      WeaponEnergyCard(
        energy: specification.energy,
        core: weaponValue(model?.coreType),
        profile: details.energy,
      ),
      WeaponVariantsCard(variants: details.variants),
      WeaponReferencesCard(references: details.references),
    ],
  );
}
