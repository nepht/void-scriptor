import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../projects/presentation/project_persistence_providers.dart';
import '../data/wardrobe_repository_impl.dart';
import '../domain/wardrobe_model.dart';
import '../domain/wardrobe_workspace_data.dart';

final wardrobeWorkspaceProvider = FutureProvider.family<WardrobeModel?, String>(
  (ref, wardrobeId) async {
    final session = ref.watch(projectSessionProvider).valueOrNull;
    if (session == null) return null;
    return WardrobeRepositoryImpl(
      database: session.database,
      projectId: session.manifest.id,
    ).getWardrobe(wardrobeId);
  },
);

/// Persisted child rows for the Wardrobe workspace detail cards
/// (vs-hunt-20260914-wardrobe-weapon WBUG-5). Null session or missing
/// wardrobe resolves to an empty [WardrobeWorkspaceData] so the cards can
/// show honest empty states instead of the previous hardcoded sample chips.
final wardrobeWorkspaceDetailsProvider =
    FutureProvider.family<WardrobeWorkspaceData, String>((
      ref,
      wardrobeId,
    ) async {
      final session = ref.watch(projectSessionProvider).valueOrNull;
      if (session == null) return const WardrobeWorkspaceData();
      return WardrobeRepositoryImpl(
        database: session.database,
        projectId: session.manifest.id,
      ).getWorkspaceData(wardrobeId);
    });
