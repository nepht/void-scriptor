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
  const WeaponWorkspaceScreen({super.key, required this.weaponId});
  final String weaponId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(weaponWorkspaceProvider(weaponId)).valueOrNull;
    // vs-hunt-20260914-wardrobe-weapon WBUG-6: child rows come from the
    // repository; detail cards are data-driven with honest empty states.
    final details =
        ref.watch(weaponWorkspaceDetailsProvider(weaponId)).valueOrNull ??
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
                      ? _WeaponDesktop(
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
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 300,
            child: AssetThumbnailCard(
              assetId: weaponId,
              title: 'Technical View',
              placeholderIcon: Icons.auto_fix_high_outlined,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: WeaponSpecificationCard(model: specification)),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: WeaponComponentsCard(components: details.components)),
          const SizedBox(width: 16),
          Expanded(
            child: WeaponDimensionsCard(
              length: specification.length,
              weight: specification.weight,
              measurements: details.measurements,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: WeaponEnergyCard(
              energy: specification.energy,
              core: weaponValue(model?.coreType),
              profile: details.energy,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      WeaponVariantsCard(variants: details.variants),
      const SizedBox(height: 16),
      WeaponReferencesCard(references: details.references),
    ],
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
