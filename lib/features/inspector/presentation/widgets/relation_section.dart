import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/selection/selection_controller.dart';
import '../../../../core/selection/selection_model.dart';
import '../../../assets/domain/asset_type.dart';
import '../../../../database/project/project_database.dart';
import '../../../projects/presentation/project_persistence_providers.dart';
import '../../../relations/application/relation_display_service.dart';
import '../../../relations/application/relation_command.dart';
import '../../../relations/data/relation_repository_impl.dart';
import '../../../assets/domain/asset_relation_type.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

final relationDisplayProvider =
    FutureProvider.family<List<RelationDisplayItem>, String>((
      ref,
      assetId,
    ) async {
      final session = ref.watch(projectSessionProvider).valueOrNull;
      if (session == null) return const [];
      return RelationDisplayService(session.database).forAsset(assetId);
    });

Future<bool> confirmRelationDeletion(
  BuildContext context, {
  required String targetName,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete relation?'),
        content: Text(
          'This removes only the relation. $targetName will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete relation'),
          ),
        ],
      ),
    ) ??
    false;

class RelationSection extends ConsumerWidget {
  const RelationSection({super.key, required this.assetId});
  final String assetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relations = ref.watch(relationDisplayProvider(assetId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Relations',
                style: TextStyle(
                  color: context.palette.primaryBright,
                  fontSize: 13,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _addRelation(context, ref),
              icon: const Icon(Icons.add, size: 15),
              label: const Text('Add Relation'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        relations.when(
          loading: () => Text(
            'Loading...',
            style: TextStyle(color: context.palette.textMuted),
          ),
          error: (error, _) => Text(
            '$error',
            style: TextStyle(color: context.palette.textMuted),
          ),
          data: (items) => items.isEmpty
              ? Text(
                  'No relations yet',
                  style: TextStyle(color: context.palette.textMuted),
                )
              : Column(
                  children: items
                      .map(
                        (item) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            item.incoming
                                ? Icons.arrow_back_outlined
                                : Icons.arrow_forward_outlined,
                            size: 16,
                            color: context.palette.primaryBright,
                          ),
                          title: Text(
                            item.label,
                            style: TextStyle(color: context.palette.textMuted),
                          ),
                          subtitle: Text(
                            item.assetName,
                            style: TextStyle(
                              color: context.palette.textPrimary,
                            ),
                          ),
                          trailing: IconButton(
                            tooltip: 'Delete relation',
                            icon: const Icon(Icons.delete_outline, size: 16),
                            color: context.palette.textMuted,
                            onPressed: () async {
                              final confirmed = await confirmRelationDeletion(
                                context,
                                targetName: item.assetName,
                              );
                              if (!confirmed || !context.mounted) return;
                              final session = ref
                                  .read(projectSessionProvider)
                                  .valueOrNull;
                              if (session == null) return;
                              final repository = RelationRepositoryImpl(
                                database: session.database,
                              );
                              final snapshotRepository = repository;
                              final relation = await snapshotRepository.getById(
                                item.relationId,
                              );
                              if (relation == null) return;
                              await session.mutationRuntime.bus.execute(
                                RelationCommand.delete(
                                  id: 'relation.delete:${item.relationId}:${DateTime.now().microsecondsSinceEpoch}',
                                  projectId: session.manifest.id,
                                  repository: repository,
                                  relation: relation,
                                ),
                              );
                              ref.invalidate(relationDisplayProvider(assetId));
                            },
                          ),
                          onTap: () async {
                            final session = ref
                                .read(projectSessionProvider)
                                .valueOrNull;
                            if (session == null) return;
                            final asset = await session.database.assetDao
                                .getById(item.assetId);
                            if (!context.mounted || asset == null) return;
                            final type = switch (asset.type) {
                              'character' => AssetType.character,
                              'wardrobe' => AssetType.wardrobe,
                              'weapon' => AssetType.weapon,
                              _ => AssetType.reference,
                            };
                            ref
                                .read(selectionProvider.notifier)
                                .select(
                                  SelectionModel(
                                    assetId: asset.id,
                                    assetType: type,
                                    projectId: asset.projectId,
                                  ),
                                );
                          },
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  Future<void> _addRelation(BuildContext context, WidgetRef ref) async {
    final session = ref.read(projectSessionProvider).valueOrNull;
    if (session == null) return;
    final assets = (await session.database.assetDao.getAllAssets())
        .where((asset) => asset.id != assetId)
        .toList(growable: false);
    if (!context.mounted) return;
    final result = await showDialog<(String, AssetRelationType)>(
      context: context,
      builder: (dialogContext) => _AddRelationDialog(assets: assets),
    );
    if (result == null || !context.mounted) return;
    final repository = RelationRepositoryImpl(database: session.database);
    await session.mutationRuntime.bus.execute(
      RelationCommand.create(
        id: 'relation.create:$assetId:${DateTime.now().microsecondsSinceEpoch}',
        projectId: session.manifest.id,
        repository: repository,
        sourceAssetId: assetId,
        targetAssetId: result.$1,
        type: result.$2,
      ),
    );
    ref.invalidate(relationDisplayProvider(assetId));
  }
}

class _AddRelationDialog extends StatefulWidget {
  const _AddRelationDialog({required this.assets});
  final List<Asset> assets;

  @override
  State<_AddRelationDialog> createState() => _AddRelationDialogState();
}

class _AddRelationDialogState extends State<_AddRelationDialog> {
  Asset? _target;
  AssetRelationType _type = AssetRelationType.relatedTo;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add Relation'),
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<Asset>(
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Target asset'),
            items: widget.assets
                .map(
                  (asset) => DropdownMenuItem(
                    value: asset,
                    child: Text('${asset.name} · ${asset.type}'),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _target = value),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AssetRelationType>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Relation type'),
            items: AssetRelationType.values
                .map(
                  (type) =>
                      DropdownMenuItem(value: type, child: Text(type.value)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _type = value);
            },
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _target == null
            ? null
            : () => Navigator.of(context).pop((_target!.id, _type)),
        child: const Text('Create Relation'),
      ),
    ],
  );
}
