import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../projects/presentation/project_persistence_providers.dart';
import '../data/wardrobe_repository_impl.dart';
import '../domain/wardrobe_model.dart';

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
