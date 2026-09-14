import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// 145.42 interrupted-import claim sentinel.
///
/// [PortableProjectImportCoordinator] writes a hidden
/// `.import-claim-<projectId>.json` into the import destination BEFORE the
/// destination-collision stash rename, and releases it only after the import
/// fully succeeds or fully rolls back. While the claim exists and the stash
/// it names is still on disk, the import provably never reached its final
/// discard — so ANY package content sitting at the canonical
/// `<projectId>.voidproject` path is in-progress scratch from that attempt,
/// not an ambiguous completed package. Recovery can then restore the user's
/// buried original instead of refusing forever (and instead of letting a
/// retry rename the half-extracted corpse).
///
/// Deliberately Flutter-free (like the restore staging journal) so the real
/// process-kill harness can replay the production order in a plain Dart
/// child process.
class ImportClaim {
  ImportClaim._(this.file, this.projectId, this.stashPath);

  final File file;
  final String projectId;
  final String stashPath;

  /// Project ids whose import is running inside THIS process right now.
  /// Recovery must never quarantine the destination a live extraction owns.
  static final Set<String> _activeProjectIds = <String>{};

  static bool isActiveInProcess(String projectId) =>
      _activeProjectIds.contains(projectId);

  static void markActive(String projectId) {
    _activeProjectIds.add(projectId);
  }

  static void clearActive(String projectId) {
    _activeProjectIds.remove(projectId);
  }

  static String _fileNameFor(String projectId) =>
      '.import-claim-$projectId.json';

  static File fileFor({
    required Directory destination,
    required String projectId,
  }) => File(p.join(destination.path, _fileNameFor(projectId)));

  /// Writes the claim for [projectId] and marks it active in this process.
  static Future<ImportClaim> create({
    required Directory destination,
    required String projectId,
    required String stashPath,
  }) async {
    final file = fileFor(destination: destination, projectId: projectId);
    await file.writeAsString(
      jsonEncode(<String, Object?>{
        'version': 1,
        'projectId': projectId,
        'stashPath': stashPath,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      }),
      flush: true,
    );
    markActive(projectId);
    return ImportClaim._(file, projectId, stashPath);
  }

  /// Loads the claim at [file], or null when absent or structurally invalid.
  static Future<ImportClaim?> load(File file) async {
    if (!await file.exists()) return null;
    final Object? decoded;
    try {
      decoded = jsonDecode(await file.readAsString());
    } on Object {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;
    final projectId = decoded['projectId'];
    final stashPath = decoded['stashPath'];
    if (projectId is! String || stashPath is! String) return null;
    return ImportClaim._(file, projectId, stashPath);
  }

  /// True when the stashed package this claim names is still on disk.
  Future<bool> stashStillExists() async {
    try {
      return FileSystemEntity.typeSync(stashPath) !=
          FileSystemEntityType.notFound;
    } on Object {
      return false;
    }
  }

  /// Drops THIS process's ownership marker without touching the sentinel
  /// file: exactly the state a later process sees after the importing
  /// process died. Harnesses and tests use it to simulate the dead owner.
  void disposeLocalOwnership() {
    clearActive(projectId);
  }

  /// Best-effort release: clear the in-process marker and delete the file.
  /// A failed delete is inert — recovery only ever acts when the named
  /// stash also still exists.
  Future<void> release() async {
    clearActive(projectId);
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Scratch cleanup only; the import outcome never depends on it.
    }
  }
}
