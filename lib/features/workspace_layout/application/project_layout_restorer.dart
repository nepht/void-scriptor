import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/layout_controller.dart';
import '../application/layout_preset_repository.dart';

/// Loads the persisted layout for a project and applies it (Step 27.20).
///
/// The repository is injected via `layoutPresetRepositoryProvider`; on failure
/// the default layout is kept.
Future<void> restoreProjectLayout(WidgetRef ref, String projectId) async {
  final repo = ref.read(layoutPresetRepositoryProvider);
  try {
    final layout = await repo.restore(projectId);
    if (layout != null) {
      ref.read(layoutProvider.notifier).applyLayout(layout);
    }
  } catch (_) {
    // Persistence failure must not break startup; keep defaults.
  }
}

/// Persists the current layout for a project (fire-and-forget).
Future<void> persistProjectLayout(WidgetRef ref, String projectId) async {
  final repo = ref.read(layoutPresetRepositoryProvider);
  final layout = ref.read(layoutProvider);
  try {
    await repo.persist(projectId, layout);
  } catch (_) {
    // Best-effort persistence.
  }
}
