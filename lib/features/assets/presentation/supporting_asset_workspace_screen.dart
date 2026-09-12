import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/project/project_database.dart';
import '../../projects/presentation/project_persistence_providers.dart';
import 'widgets/asset_thumbnail_card.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

final supportingAssetProvider = FutureProvider.family<Asset?, String>((
  ref,
  assetId,
) async {
  final session = ref.watch(projectSessionProvider).valueOrNull;
  return session?.database.assetDao.getById(assetId);
});

class SupportingAssetWorkspaceScreen extends ConsumerWidget {
  const SupportingAssetWorkspaceScreen({
    super.key,
    required this.assetId,
    this.activeSection,
  });

  final String assetId;
  final String? activeSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(supportingAssetProvider(assetId));
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _MessageState(
        icon: Icons.error_outline,
        title: 'Asset could not be loaded',
        message: '$error',
        actionLabel: 'Try again',
        onAction: () => ref.invalidate(supportingAssetProvider(assetId)),
      ),
      data: (asset) => asset == null
          ? const _MessageState(
              icon: Icons.inventory_2_outlined,
              title: 'Asset not found',
              message: 'It may have been moved or removed from this project.',
            )
          : _AssetDetails(
              asset: asset,
              section: activeSection ?? 'Details',
              onChanged: () => ref.invalidate(supportingAssetProvider(assetId)),
            ),
    );
  }
}

class _AssetDetails extends ConsumerWidget {
  const _AssetDetails({
    required this.asset,
    required this.section,
    required this.onChanged,
  });

  final Asset asset;
  final String section;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (section == 'References') {
      return const _MessageState(
        icon: Icons.collections_bookmark_outlined,
        title: 'Reference board',
        message:
            'Attach visual references from Assets to keep this design consistent.',
      );
    }
    if (section == 'Variants' || section == 'States') {
      return _MessageState(
        icon: section == 'Variants'
            ? Icons.layers_outlined
            : Icons.change_circle_outlined,
        title: section,
        message: section == 'Variants'
            ? 'Variants are managed from the specialized editor for this asset.'
            : 'Item states are stored with the item and can be expanded without changing the project structure.',
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: constraints.maxWidth >= 760
                      ? 560
                      : constraints.maxWidth,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _TypeIcon(type: asset.type),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  asset.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                              ),
                              IconButton(
                                tooltip: asset.favorite
                                    ? 'Remove from favorites'
                                    : 'Add to favorites',
                                onPressed: () async {
                                  final session = ref
                                      .read(projectSessionProvider)
                                      .valueOrNull;
                                  await session?.database.assetDao.setFavorite(
                                    asset.id,
                                    !asset.favorite,
                                  );
                                  onChanged();
                                },
                                icon: Icon(
                                  asset.favorite
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            asset.description.isEmpty
                                ? 'No description yet.'
                                : asset.description,
                            style: TextStyle(
                              color: context.palette.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () => _edit(context, ref),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit details'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: constraints.maxWidth >= 760
                      ? 300
                      : constraints.maxWidth,
                  child: Column(
                    children: [
                      AssetThumbnailCard(
                        assetId: asset.id,
                        title: 'Design View',
                        placeholderIcon: Icons.inventory_2_outlined,
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ASSET INFO',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              const SizedBox(height: 14),
                              _InfoRow(
                                label: 'Type',
                                value: _labelForType(asset.type),
                              ),
                              _InfoRow(label: 'Version', value: asset.version),
                              _InfoRow(
                                label: 'Updated',
                                value: _date(asset.updatedAt),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController(text: asset.name);
    final descriptionController = TextEditingController(
      text: asset.description,
    );
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit ${_labelForType(asset.type)}'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    nameController.dispose();
    descriptionController.dispose();
    if (save != true || name.isEmpty) return;
    final session = ref.read(projectSessionProvider).valueOrNull;
    if (session == null) return;
    await (session.database.update(
      session.database.assets,
    )..where((row) => row.id.equals(asset.id))).write(
      AssetsCompanion(
        name: Value(name),
        description: Value(description),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    onChanged();
  }
}

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.type});
  final String type;
  @override
  Widget build(BuildContext context) => CircleAvatar(
    backgroundColor: context.palette.primary.withValues(alpha: 0.14),
    child: Icon(_iconForType(type), color: context.palette.primaryBright),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: context.palette.textMuted),
          ),
        ),
        Flexible(child: Text(value, textAlign: TextAlign.end)),
      ],
    ),
  );
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: context.palette.textMuted),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(message, textAlign: TextAlign.center),
          ),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}

String _labelForType(String type) => switch (type) {
  'armor' => 'Armor',
  'accessory' => 'Accessory',
  'prop' => 'Item',
  'hair_variant' => 'Hair Variation',
  _ => type.replaceAll('_', ' '),
};

IconData _iconForType(String type) => switch (type) {
  'armor' => Icons.shield_outlined,
  'accessory' => Icons.watch_outlined,
  'prop' => Icons.inventory_2_outlined,
  'hair_variant' => Icons.content_cut_outlined,
  _ => Icons.category_outlined,
};

String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
