import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../assets/presentation/widgets/asset_thumbnail_card.dart';
import '../domain/weapon_model.dart';
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
    final specification = WeaponSpecificationData(
      type: _value(model?.weaponType, 'Weapon'),
      length: model?.lengthMm == null ? '420 mm' : '${model!.lengthMm} mm',
      weight: model?.weightKg == null ? '0.82 kg' : '${model!.weightKg} kg',
      material: _value(model?.primaryMaterial, 'Void Alloy'),
      energy: _value(model?.energyType, 'Void Energy'),
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
                        )
                      : _WeaponCompact(
                          weaponId: weaponId,
                          model: model,
                          specification: specification,
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
  });
  final String weaponId;
  final WeaponModel? model;
  final WeaponSpecificationData specification;

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
          const Expanded(child: WeaponComponentsCard()),
          const SizedBox(width: 16),
          Expanded(
            child: WeaponDimensionsCard(
              length: specification.length,
              weight: specification.weight,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: WeaponEnergyCard(
              energy: specification.energy,
              core: WeaponWorkspaceScreen._value(
                model?.coreType,
                'Crystalline Void Core',
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      const WeaponVariantsCard(),
      const SizedBox(height: 16),
      const WeaponReferencesCard(),
    ],
  );
}

class _WeaponCompact extends StatelessWidget {
  const _WeaponCompact({
    required this.weaponId,
    required this.model,
    required this.specification,
  });
  final String weaponId;
  final WeaponModel? model;
  final WeaponSpecificationData specification;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AssetThumbnailCard(
        assetId: weaponId,
        title: 'Technical View',
        placeholderIcon: Icons.auto_fix_high_outlined,
      ),
      WeaponSpecificationCard(model: specification),
      const WeaponComponentsCard(),
      WeaponDimensionsCard(
        length: specification.length,
        weight: specification.weight,
      ),
      WeaponEnergyCard(
        energy: specification.energy,
        core: WeaponWorkspaceScreen._value(
          model?.coreType,
          'Crystalline Void Core',
        ),
      ),
      const WeaponVariantsCard(),
      const WeaponReferencesCard(),
    ],
  );
}
