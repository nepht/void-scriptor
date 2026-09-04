import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../domain/asset_type.dart';
import '../project_package/project_package.dart';

/// Schema version of the selection-memory snapshot file. Bumping it must be
/// accompanied by a migration decision; unknown versions load as empty.
const int selectionMemorySchemaVersion = 1;

/// File name inside the active project package cache directory.
const String kSelectionMemoryFileName = 'selection_memory.json';

/// Per-workspace navigation memory: (projectId, assetType) -> assetId.
typedef SelectionMemorySnapshot = Map<(String, AssetType), String>;

Map<String, dynamic> _encode(SelectionMemorySnapshot snapshot) {
  final workspaces = <String, Map<String, String>>{};
  snapshot.forEach((key, value) {
    (workspaces[key.$1] ??= <String, String>{})[key.$2.name] = value;
  });
  return <String, dynamic>{
    'version': selectionMemorySchemaVersion,
    'workspaces': workspaces,
  };
}

/// Loads the persisted selection memory. Missing, corrupt, or unknown
/// content never throws and yields no entries: navigation memory is a
/// convenience and must never block a project from opening.
Future<SelectionMemorySnapshot> loadSelectionMemorySnapshot(File file) async {
  try {
    if (!await file.exists()) return <(String, AssetType), String>{};
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic> ||
        decoded['version'] != selectionMemorySchemaVersion) {
      return <(String, AssetType), String>{};
    }
    final workspaces = decoded['workspaces'];
    if (workspaces is! Map<String, dynamic>) {
      return <(String, AssetType), String>{};
    }
    final snapshot = <(String, AssetType), String>{};
    workspaces.forEach((projectId, types) {
      if (types is! Map<String, dynamic>) return;
      types.forEach((typeName, assetId) {
        final type = AssetType.values.asNameMap()[typeName];
        if (type == null || assetId is! String) return;
        snapshot[(projectId, type)] = assetId;
      });
    });
    return snapshot;
  } on Object {
    return <(String, AssetType), String>{};
  }
}

/// Synchronous variant used by the debounced persistence callback so the
/// write completes inside the timer callback even under a fake-async test
/// zone (real IO futures must never dangle there). The file is tiny and the
/// write is debounced off the interaction hot path.
void persistSelectionMemorySnapshotSync(
  File file,
  SelectionMemorySnapshot snapshot,
) {
  file.parent.createSync(recursive: true);
  final tmp = File('${file.path}.tmp');
  tmp.writeAsStringSync(jsonEncode(_encode(snapshot)), flush: true);
  tmp.renameSync(file.path);
}

File selectionMemoryFileFor(ProjectPackage package) =>
    File(p.join(package.cacheDirectory.path, kSelectionMemoryFileName));

final Map<String, Future<void>> _pendingWrites = <String, Future<void>>{};

/// Synchronous variant used to hydrate memory the moment a provider
/// mounts with an active session. Same failure contract: never throws.
SelectionMemorySnapshot loadSelectionMemorySnapshotSync(File file) {
  try {
    if (!file.existsSync()) return <(String, AssetType), String>{};
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map<String, dynamic> ||
        decoded['version'] != selectionMemorySchemaVersion) {
      return <(String, AssetType), String>{};
    }
    final workspaces = decoded['workspaces'];
    if (workspaces is! Map<String, dynamic>) {
      return <(String, AssetType), String>{};
    }
    final snapshot = <(String, AssetType), String>{};
    workspaces.forEach((projectId, types) {
      if (types is! Map<String, dynamic>) return;
      types.forEach((typeName, assetId) {
        final type = AssetType.values.asNameMap()[typeName];
        if (type == null || assetId is! String) return;
        snapshot[(projectId, type)] = assetId;
      });
    });
    return snapshot;
  } on Object {
    return <(String, AssetType), String>{};
  }
}

/// Atomically persists the snapshot: write `<file>.tmp`, flush, then rename
/// over the destination so a crash mid-write never leaves a torn file.
/// Writes to the same file are serialized so concurrent callers (the
/// provider is mounted by more than one surface) never race the rename.
Future<void> persistSelectionMemorySnapshot(
  File file,
  SelectionMemorySnapshot snapshot,
) {
  final previous = _pendingWrites[file.path] ?? Future<void>.value();
  final operation = previous.then((_) => _writeNow(file, snapshot));
  _pendingWrites[file.path] = operation.whenComplete(() {
    if (identical(_pendingWrites[file.path], operation)) {
      _pendingWrites.remove(file.path);
    }
  });
  return operation;
}

Future<void> _writeNow(File file, SelectionMemorySnapshot snapshot) async {
  await file.parent.create(recursive: true);
  final tmp = File('${file.path}.tmp');
  await tmp.writeAsString(jsonEncode(_encode(snapshot)), flush: true);
  await tmp.rename(file.path);
}
