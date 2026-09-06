import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/project/project_database.dart' hide LayoutPreset;
import '../../projects/presentation/project_persistence_providers.dart';
import '../domain/layout_model.dart';
import '../domain/layout_preset.dart';

/// Layout preset persistence contract (Step 27.6).
abstract interface class LayoutPresetRepository {
  Future<List<LayoutPreset>> list(String projectId);
  Future<void> save(String projectId, LayoutPreset preset);
  Future<void> delete(String projectId, String name);
  Future<PanelLayout?> restore(String projectId);
  Future<void> persist(String projectId, PanelLayout layout);
}

class DriftLayoutPresetRepository implements LayoutPresetRepository {
  DriftLayoutPresetRepository(this._db);

  final ProjectDatabase _db;

  @override
  Future<List<LayoutPreset>> list(String projectId) async {
    final rows = await (_db.select(
      _db.layoutPresets,
    )..where((r) => r.projectId.equals(projectId))).get();
    return rows
        .map((r) => LayoutPreset(name: r.name, layout: _decode(r.json)))
        .toList(growable: false);
  }

  @override
  Future<void> save(String projectId, LayoutPreset preset) async {
    await _db
        .into(_db.layoutPresets)
        .insertOnConflictUpdate(
          LayoutPresetsCompanion.insert(
            id: '${projectId}_${preset.name}',
            projectId: projectId,
            name: preset.name,
            json: _encode(preset.layout),
          ),
        );
  }

  @override
  Future<void> delete(String projectId, String name) async {
    await (_db.delete(
      _db.layoutPresets,
    )..where((r) => r.projectId.equals(projectId) & r.name.equals(name))).go();
  }

  @override
  Future<PanelLayout?> restore(String projectId) async {
    final row = await (_db.select(
      _db.projectLayoutStates,
    )..where((r) => r.projectId.equals(projectId))).getSingleOrNull();
    return row == null ? null : _decode(row.json);
  }

  @override
  Future<void> persist(String projectId, PanelLayout layout) async {
    await _db
        .into(_db.projectLayoutStates)
        .insertOnConflictUpdate(
          ProjectLayoutStatesCompanion.insert(
            projectId: projectId,
            json: _encode(layout),
          ),
        );
  }

  static String _encode(PanelLayout layout) => jsonEncode({
    'leftWidth': layout.leftWidth,
    'rightWidth': layout.rightWidth,
    'leftCollapsed': layout.leftCollapsed,
    'rightCollapsed': layout.rightCollapsed,
    'splitRatio': layout.splitRatio,
    'activeTabIndex': layout.activeTabIndex,
  });

  static PanelLayout _decode(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return PanelLayout(
      leftWidth: (map['leftWidth'] as num).toDouble(),
      rightWidth: (map['rightWidth'] as num).toDouble(),
      leftCollapsed: map['leftCollapsed'] as bool,
      rightCollapsed: map['rightCollapsed'] as bool,
      splitRatio: (map['splitRatio'] as num).toDouble(),
      activeTabIndex: (map['activeTabIndex'] as num?)?.toInt() ?? 0,
    );
  }
}

class UnavailableLayoutPresetRepository implements LayoutPresetRepository {
  const UnavailableLayoutPresetRepository();

  @override
  Future<void> delete(String projectId, String name) async {}

  @override
  Future<List<LayoutPreset>> list(String projectId) async => const [];

  @override
  Future<void> persist(String projectId, PanelLayout layout) async {}

  @override
  Future<PanelLayout?> restore(String projectId) async => null;

  @override
  Future<void> save(String projectId, LayoutPreset preset) async {}
}

/// Follows the active project session and exposes its database-backed layout
/// repository. Before a project opens, callers receive a safe empty repository
/// so startup and non-project routes never fail on layout persistence.
final layoutPresetRepositoryProvider = Provider<LayoutPresetRepository>((ref) {
  final session = ref.watch(projectSessionProvider).valueOrNull;
  if (session == null) return const UnavailableLayoutPresetRepository();
  return DriftLayoutPresetRepository(session.database);
});
