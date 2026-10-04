import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../projects/presentation/project_persistence_providers.dart';
import '../application/reference_repository.dart';
import '../domain/reference_models.dart';
import 'reference_library_screen.dart';

final projectReferencesProvider = FutureProvider<List<ReferenceModel>>((
  ref,
) async {
  final session = ref.watch(projectSessionProvider).value;
  if (session == null) return const [];
  final projectDir = await ref
      .watch(projectPathsProvider)
      .project(session.manifest.id);
  final rows = await session.database.referenceDao.list(
    projectId: session.manifest.id,
  );
  return rows
      .map(
        (row) => ReferenceModel(
          id: row.id,
          projectId: row.projectId,
          ownerAssetId: row.ownerAssetId,
          type: referenceTypeFromStorage(row.type),
          source: referenceSourceFromStorage(row.source),
          name: row.name,
          filePath: p.isAbsolute(row.filePath)
              ? row.filePath
              : p.join(projectDir.path, row.filePath),
          description: row.description,
          priority: row.priority,
          primary: row.primaryReference,
          enabled: row.enabled,
          contentHash: row.contentHash,
          createdAt: row.createdAt,
          updatedAt: row.updatedAt,
        ),
      )
      .toList(growable: false);
});

class ProjectReferenceLibraryScreen extends ConsumerWidget {
  const ProjectReferenceLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(projectSessionProvider).value;
    final references = ref.watch(projectReferencesProvider);
    return references.when(
      loading: () => const Scaffold(
        appBar: ReferenceLibraryAppBar(),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: const ReferenceLibraryAppBar(),
        body: Center(child: Text('Reference Library error: $error')),
      ),
      data: (items) => ReferenceLibraryScreen(
        references: items,
        onImport: session == null
            ? null
            : (draft) async {
                await ReferenceImportService(
                  database: session.database,
                  paths: ref.read(projectPathsProvider),
                ).importFile(
                  projectId: session.manifest.id,
                  referenceId: const Uuid().v4(),
                  sourcePath: draft.sourcePath,
                  name: draft.name,
                  ownerAssetId: draft.ownerAssetId,
                  type: draft.type,
                  priority: draft.priority,
                  primary: draft.primary,
                  description: draft.description,
                );
                ref.invalidate(projectReferencesProvider);
              },
        onSetPrimary: session == null
            ? null
            : (reference) async {
                await session.database.referenceDao.setPrimary(
                  projectId: reference.projectId,
                  ownerAssetId: reference.ownerAssetId,
                  type: reference.type,
                  referenceId: reference.id,
                );
                ref.invalidate(projectReferencesProvider);
              },
      ),
    );
  }
}

class ReferenceLibraryAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const ReferenceLibraryAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) =>
      AppBar(title: const Text('Reference Library'));
}
