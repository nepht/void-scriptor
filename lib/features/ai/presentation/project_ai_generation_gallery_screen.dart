import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../../app/routing/app_routes.dart';
import '../../projects/presentation/project_persistence_providers.dart';
import '../../references/domain/reference_models.dart';
import '../application/generation_reference_service.dart';
import '../application/generation_repository.dart';
import 'ai_generation_gallery_screen.dart';

final projectGenerationOutputsProvider =
    FutureProvider<List<GenerationGalleryItem>>((ref) async {
      final session = ref.watch(projectSessionProvider).valueOrNull;
      if (session == null) return const [];
      final rows = await GenerationRepository(
        session.database,
      ).getProjectOutputs(session.manifest.id);
      return rows
          .where((row) => row.localPath != null)
          .map(
            (row) => GenerationGalleryItem(
              id: row.id,
              path: row.localPath!,
              outputType: row.outputType,
            ),
          )
          .toList(growable: false);
    });

class ProjectAiGenerationGalleryScreen extends ConsumerWidget {
  const ProjectAiGenerationGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(projectSessionProvider).valueOrNull;
    final outputs = ref.watch(projectGenerationOutputsProvider);
    return outputs.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(body: Center(child: Text('Gallery error: $error'))),
      data: (items) => AiGenerationGalleryScreen(
        outputs: items,
        onUseAsReference: session == null
            ? null
            : (output) async {
                final draft = await showDialog<_PromotionDraft>(
                  context: context,
                  builder: (_) => _PromotionDialog(outputId: output.id),
                );
                if (draft == null) return;
                await GenerationReferenceService(
                  database: session.database,
                  paths: ref.read(projectPathsProvider),
                ).useAsReference(
                  projectId: session.manifest.id,
                  outputId: output.id,
                  ownerAssetId: draft.ownerId,
                  type: draft.type,
                  name: draft.name,
                  primary: draft.primary,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Generation promoted to Reference Library'),
                    ),
                  );
                }
              },
        onCompareWithPrimary: session == null
            ? null
            : (output) async {
                final draft = await showDialog<_PromotionDraft>(
                  context: context,
                  builder: (_) => _PromotionDialog(
                    outputId: output.id,
                    comparisonOnly: true,
                  ),
                );
                if (draft == null) return;
                final references = await session.database.referenceDao.list(
                  projectId: session.manifest.id,
                  ownerAssetId: draft.ownerId,
                  type: draft.type,
                );
                final primary = references
                    .where((row) => row.primaryReference)
                    .firstOrNull;
                if (primary == null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'No primary reference for this owner/type',
                        ),
                      ),
                    );
                  }
                  return;
                }
                final projectDirectory = await ref
                    .read(projectPathsProvider)
                    .project(session.manifest.id);
                final referencePath = p.isAbsolute(primary.filePath)
                    ? primary.filePath
                    : p.join(projectDirectory.path, primary.filePath);
                if (context.mounted) {
                  context.push(
                    '${AppRoutes.references}/compare?reference=${Uri.encodeQueryComponent(referencePath)}&generated=${Uri.encodeQueryComponent(output.path)}',
                  );
                }
              },
      ),
    );
  }
}

class _PromotionDraft {
  const _PromotionDraft({
    required this.ownerId,
    required this.type,
    required this.name,
    required this.primary,
  });
  final String ownerId;
  final ReferenceType type;
  final String name;
  final bool primary;
}

class _PromotionDialog extends StatefulWidget {
  const _PromotionDialog({required this.outputId, this.comparisonOnly = false});
  final String outputId;
  final bool comparisonOnly;

  @override
  State<_PromotionDialog> createState() => _PromotionDialogState();
}

class _PromotionDialogState extends State<_PromotionDialog> {
  final owner = TextEditingController();
  final name = TextEditingController();
  ReferenceType type = ReferenceType.face;
  bool primary = false;

  @override
  void initState() {
    super.initState();
    name.text = 'Generated ${widget.outputId}';
  }

  @override
  void dispose() {
    owner.dispose();
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.comparisonOnly ? 'Compare with Primary' : 'Use as Reference',
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: owner,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'Owner asset ID'),
        ),
        if (!widget.comparisonOnly)
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Reference name'),
          ),
        DropdownButtonFormField<ReferenceType>(
          initialValue: type,
          isExpanded: true,
          items: ReferenceType.values
              .map(
                (item) => DropdownMenuItem(value: item, child: Text(item.name)),
              )
              .toList(growable: false),
          onChanged: (value) => setState(() => type = value ?? type),
          decoration: const InputDecoration(labelText: 'Reference type'),
        ),
        if (!widget.comparisonOnly)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Set as primary'),
            value: primary,
            onChanged: (value) => setState(() => primary = value),
          ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: owner.text.trim().isEmpty
            ? null
            : () => Navigator.pop(
                context,
                _PromotionDraft(
                  ownerId: owner.text.trim(),
                  type: type,
                  name: name.text.trim(),
                  primary: primary,
                ),
              ),
        child: Text(widget.comparisonOnly ? 'Compare' : 'Promote'),
      ),
    ],
  );
}
