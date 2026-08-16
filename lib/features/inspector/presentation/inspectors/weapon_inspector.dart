import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../projects/presentation/project_persistence_providers.dart';
import '../../../weapon/data/weapon_repository_impl.dart';
import '../widgets/relation_section.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

final weaponInspectorProvider =
    FutureProvider.family<WeaponInspectorData?, String>((ref, weaponId) async {
      final session = ref.watch(projectSessionProvider).valueOrNull;
      if (session == null) return null;
      final model = await WeaponRepositoryImpl(
        database: session.database,
        projectId: session.manifest.id,
      ).getWeapon(weaponId);
      if (model == null) return null;
      final variants = await session.database.weaponDao.getVariants(weaponId);
      final incoming = await session.database.relationDao.getIncomingRelations(
        weaponId,
      );
      return WeaponInspectorData(
        name: model.name,
        weaponType: model.weaponType,
        material: model.primaryMaterial,
        length: model.lengthMm == null ? '—' : '${model.lengthMm} mm',
        energy: model.energyType,
        core: model.coreType,
        variant:
            variants
                .where((item) => item.isDefault)
                .map((item) => item.name)
                .firstOrNull ??
            '—',
        incomingRelationCount: incoming.length,
      );
    });

class WeaponInspectorData {
  const WeaponInspectorData({
    required this.name,
    required this.weaponType,
    required this.material,
    required this.length,
    required this.energy,
    required this.core,
    required this.variant,
    required this.incomingRelationCount,
  });
  final String name;
  final String weaponType;
  final String material;
  final String length;
  final String energy;
  final String core;
  final String variant;
  final int incomingRelationCount;
}

class WeaponInspector extends ConsumerWidget {
  const WeaponInspector({super.key, required this.weaponId});
  final String weaponId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(weaponInspectorProvider(weaponId)).valueOrNull;
    return Container(
      color: context.palette.panel,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data?.name ?? weaponId,
              style:  TextStyle(
                color: context.palette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
             Text('Weapon', style: TextStyle(color: context.palette.textMuted)),
            const SizedBox(height: 20),
            _Section(
              title: 'Properties',
              rows: [
                ('Type', data?.weaponType ?? '—'),
                ('Material', data?.material ?? '—'),
                ('Length', data?.length ?? '—'),
                ('Energy', data?.energy ?? '—'),
                ('Core', data?.core ?? '—'),
                ('Variant', data?.variant ?? '—'),
              ],
            ),
            RelationSection(assetId: weaponId),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});
  final String title;
  final List<(String, String)> rows;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:  TextStyle(color: context.palette.primaryBright, fontSize: 13),
        ),
        const SizedBox(height: 8),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              children: [
                SizedBox(
                  width: 78,
                  child: Text(
                    row.$1,
                    style:  TextStyle(color: context.palette.textMuted),
                  ),
                ),
                Expanded(
                  child: Text(
                    row.$2,
                    style:  TextStyle(color: context.palette.textPrimary),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
