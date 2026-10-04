import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/typography/void_typography.dart';
import '../../../wardrobe/data/wardrobe_repository_impl.dart';
import '../../../projects/presentation/project_persistence_providers.dart';
import '../widgets/relation_section.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

final wardrobeInspectorProvider =
    FutureProvider.family<WardrobeInspectorData?, String>((
      ref,
      wardrobeId,
    ) async {
      final session = ref.watch(projectSessionProvider).value;
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
    // vs-hunt-20260913-inspector INS-BUG-02: never surface the raw id token.
    // Loading shows a real indicator, errors are visible, and an
    // unresolvable wardrobe reads 'Unknown asset' (loadout UX contract),
    // matching the .when pattern used by supporting_asset_workspace_screen.
    return ref
        .watch(wardrobeInspectorProvider(wardrobeId))
        .when(
          loading: () => _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Loading wardrobe...',
                      style: TextStyle(color: context.palette.textMuted),
                    ),
                  ],
                ),
                Text(
                  'Wardrobe',
                  style: TextStyle(color: context.palette.textMuted),
                ),
              ],
            ),
          ),
          error: (error, _) => _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$error',
                  style: TextStyle(color: context.palette.textMuted),
                ),
                Text(
                  'Wardrobe',
                  style: TextStyle(color: context.palette.textMuted),
                ),
              ],
            ),
          ),
          data: (data) {
            if (data == null) {
              return const _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Unknown asset', style: VoidTypography.title),
                    Text('Wardrobe', style: VoidTypography.caption),
                  ],
                ),
              );
            }
            return _Panel(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.name, style: VoidTypography.title),
                    Text(
                      'Wardrobe',
                      style: TextStyle(color: context.palette.textMuted),
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
                    RelationSection(assetId: wardrobeId),
                  ],
                ),
              ),
            );
          },
        );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    color: context.palette.panel,
    padding: const EdgeInsets.all(16),
    child: child,
  );
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
          style: TextStyle(color: context.palette.primaryBright, fontSize: 13),
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
                    style: TextStyle(color: context.palette.textMuted),
                  ),
                ),
                Expanded(
                  child: Text(
                    row.$2,
                    style: TextStyle(color: context.palette.textPrimary),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
