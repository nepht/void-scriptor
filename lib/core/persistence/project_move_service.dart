import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'project_recovery_service.dart';

/// Moves a project package between directories of one volume behind a
/// durable journal so an interrupted rename (process kill / power loss) is
/// recoverable instead of silently losing the package (145.42).
///
/// The journal (`move-pending.marker`) is written and flushed BEFORE the
/// rename opens the crash window. Recovery contract:
/// - rename completed  -> the marker is stale journal state at the
///   destination and is consumed by the registry once the project entry
///   points at the new location, or by the next roll-forward scan;
/// - rename never ran  -> [ProjectRecoveryService.recoverInterruptedMoves]
///   rolls the package forward to the recorded destination;
/// - rename failed     -> the package is still at the source, the journal
///   is consumed, and the error surfaces to the caller.
/// Cross-volume moves are out of scope for this service: `Directory.rename`
/// does not cross volume boundaries.
class ProjectMoveService {
  const ProjectMoveService();

  Future<Directory> movePackage({
    required Directory package,
    required Directory destinationRoot,
  }) async {
    final name = p.basename(package.path);
    final destination = p.join(destinationRoot.path, name);
    await destinationRoot.create(recursive: true);
    final marker = File(
      p.join(package.path, ProjectRecoveryService.movePendingMarkerName),
    );
    final projectId = name.endsWith('.voidproject')
        ? name.substring(0, name.length - '.voidproject'.length)
        : name;
    await marker.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'projectId': projectId,
        'source': package.path,
        'destination': destination,
        'writtenAt': DateTime.now().toUtc().toIso8601String(),
      }),
      flush: true,
    );
    try {
      await package.rename(destination);
    } on FileSystemException {
      // The rename failed: the package never left the source. Consume the
      // journal so a later scan cannot roll a move that must not happen.
      try {
        await marker.delete();
      } on FileSystemException {
        // Best effort: recovery treats an unmoveable source+occupied
        // destination as untouched state and leaves the journal in place.
      }
      rethrow;
    }
    // The marker travelled with the package into the destination; the move
    // is complete, so consume it there. A crash before this delete leaves
    // the landed-marker state, which the registry consumes on next load.
    await File(
      p.join(destination, ProjectRecoveryService.movePendingMarkerName),
    ).delete();
    return Directory(destination);
  }
}
