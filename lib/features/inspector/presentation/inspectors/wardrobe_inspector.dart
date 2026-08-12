import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/colors/void_colors.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../wardrobe/data/wardrobe_repository_impl.dart';
import '../../../projects/presentation/project_persistence_providers.dart';

final wardrobeInspectorProvider =
    FutureProvider.family<WardrobeInspectorData?, String>((
      ref,
      wardrobeId,
    ) async {
      final session = ref.watch(projectSessionProvider).valueOrNull;
      if (session == null) return null;
      final repository = WardrobeRepositoryImpl(
        database: session.database,
        projectId: session.manifest.id,
      );
      final model = await repository.getWardrobe(wardrobeId);
      if (model == null) return null;
      final variants = await session.database.wardrobeDao.getVariants(
        wardrobeId,
      );
      final incoming = await session.database.relationDao.getIncomingRelations(
        wardrobeId,
      );
      return WardrobeInspectorData(
        name: model.name,
        category: model.category,
        material: model.primaryMaterial,
        fabric: model.fabric,
        fit: model.fit,
        style: model.style,
        variants: variants
            .map((variant) => variant.name)
            .toList(growable: false),
        incomingRelationCount: incoming.length,
      );
    });

class WardrobeInspectorData {
  const WardrobeInspectorData({
    required this.name,
    required this.category,
    required this.material,
    required this.fabric,
    required this.fit,
    required this.style,
    required this.variants,
    required this.incomingRelationCount,
  });
  final String name;
  final String category;
  final String material;
  final String fabric;
  final String fit;
  final String style;
  final List<String> variants;
  final int incomingRelationCount;
}

class WardrobeInspector extends ConsumerWidget {
  const WardrobeInspector({super.key, required this.wardrobeId});
  final String wardrobeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wardrobeInspectorProvider(wardrobeId));
    final data = state.valueOrNull;
    if (data == null) {
      return Container(
        color: VoidColors.panel,
        padding: const EdgeInsets.all(16),
        child: Text(wardrobeId, style: VoidTypography.title),
      );
    }
    return Container(
      color: VoidColors.panel,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.name, style: VoidTypography.title),
            const Text(
              'Wardrobe',
              style: TextStyle(color: VoidColors.textMuted),
            ),
            const SizedBox(height: 20),
            _Section(
              title: 'Properties',
              rows: [
                ('Category', data.category),
                ('Material', data.material),
                ('Fabric', data.fabric),
                ('Fit', data.fit),
                ('Style', data.style),
              ],
            ),
            _Section(
              title: 'Variants',
              rows: [('Available', data.variants.join(', '))],
            ),
            _Section(
              title: 'Relations',
              rows: [('Worn by', '${data.incomingRelationCount} asset(s)')],
            ),
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
          style: const TextStyle(color: VoidColors.primaryBright, fontSize: 13),
        ),
        const SizedBox(height: 8),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 78,
                  child: Text(
                    row.$1,
                    style: const TextStyle(color: VoidColors.textMuted),
                  ),
                ),
                Expanded(
                  child: Text(
                    row.$2,
                    style: const TextStyle(color: VoidColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
