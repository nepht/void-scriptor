import 'package:drift/drift.dart';

/// Snapshot naskah draf per scene (Step 145.24 Novel Workspace Core).
///
/// Persistensi lintas restart: capture/restore/retensi mengikuti kontrak
/// domain DraftSnapshotStore (Step 109.22) — konten verbatim, restore
/// SELALU membuat cadangan teks kini, retensi memangkas yang tertua.
class SceneDraftSnapshots extends Table {
  TextColumn get id => text()();
  TextColumn get sceneId => text()();
  TextColumn get projectId => text()();
  TextColumn get kind => text()();
  TextColumn get content => text()();
  TextColumn get label => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
