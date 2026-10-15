/// Local, fail-closed storage connector interface contract for roadmap step
/// 119.12.
///
/// This file defines opaque root handles, canonicalized entry paths,
/// provider-neutral entry metadata, permission-gated operations, a
/// deterministic delta plan, confirmed-only deletion, and deterministic
/// health reporting. It does not talk to a live storage provider, transfer
/// bytes, enumerate real directories, or claim provider quota enforcement.
library;

import 'dart:convert';
import 'dart:io';

/// Opaque, non-secret storage root handle.
///
/// Roots are references only: diagnostics never echo the raw value.
final class StorageRootId {
  const StorageRootId(this.value);

  static final RegExp _pattern = RegExp(
    r'^storageref:[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}$',
  );

  final String value;

  /// Returns a handle for a well-formed `storageref:` value, otherwise `null`.
  static StorageRootId? tryParse(String raw) =>
      _pattern.hasMatch(raw) ? StorageRootId(raw) : null;

  @override
  String toString() => '[REDACTED]';
}

/// Provider-neutral, UTC-normalized entry metadata.
final class StorageEntry {
  const StorageEntry({
    required this.path,
    required this.isDirectory,
    required this.sizeBytes,
    required this.revision,
    required this.modifiedUtc,
  });

  final String path;
  final bool isDirectory;
  final int sizeBytes;

  /// Opaque provider revision token; never a clock value and never trusted as
  /// ordering evidence on its own.
  final String revision;

  final DateTime modifiedUtc;

  Map<String, Object?> toJson() => <String, Object?>{
    'path': path,
    'is_directory': isDirectory,
    'size_bytes': sizeBytes,
    'revision': revision,
    'modified_utc': modifiedUtc.toUtc().toIso8601String(),
  };
}

/// Permissions a storage connector must declare before use.
enum StoragePermission {
  readRoots,
  readEntries,
  readMetadata,
  writeUpload,
  readDownload,
  readDelta,
  writeDelete,
}

/// Deterministic health of a storage connection.
enum StorageHealthStatus { ok, degraded, unavailable }

/// Result of a gated storage operation.
enum StorageOperationResult {
  ok,
  deniedMissingPermission,
  deniedUnconfirmed,
  deniedInvalidPath,
  unsupported,
}

/// A deterministic delta between local and remote revisions.
///
/// Revision conflicts are surfaced instead of silently overwritten, so a
/// caller must resolve them before any transfer is planned.
final class StorageDeltaPlan {
  const StorageDeltaPlan({
    required this.uploads,
    required this.downloads,
    required this.deletes,
    required this.conflicts,
  });

  final List<String> uploads;
  final List<String> downloads;
  final List<String> deletes;
  final List<String> conflicts;

  bool get isEmpty =>
      uploads.isEmpty &&
      downloads.isEmpty &&
      deletes.isEmpty &&
      conflicts.isEmpty;

  bool get requiresResolution => conflicts.isNotEmpty;

  String toRedactedJson() => jsonEncode(<String, Object?>{
    'uploads': uploads,
    'downloads': downloads,
    'deletes': deletes,
    'conflicts': conflicts,
  });
}

/// Manifest validation and fail-closed helpers for the 119.12 contract.
abstract final class StorageConnectorInterface {
  static const String canonicalStep = '119.12';
  static const String manifestPath =
      'docs/planning/v1.3/sprint_119_storage_connector_interface.json';

  /// Canonical required methods for this step.
  static const List<String> requiredMethods = <String>[
    'list_roots',
    'list_entries',
    'metadata',
    'upload',
    'download',
    'delta',
    'delete',
    'health',
  ];

  /// Acceptance keys: the declared permissions plus every required method.
  static const List<String> requiredAcceptance = <String>[
    'permissions',
    ...requiredMethods,
  ];

  static final RegExp _opaqueReference = RegExp(
    r'\b(?:storageref|jobref|credref):[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}',
  );

  static final RegExp _driveLetter = RegExp(r'^[A-Za-z]:');

  /// Returns only well-formed root handles, dropping anything else.
  static List<StorageRootId> listRoots(Iterable<String> rawHandles) =>
      rawHandles
          .map(StorageRootId.tryParse)
          .whereType<StorageRootId>()
          .toList(growable: false);

  /// Canonicalizes a root-relative path, or returns `null` when the path
  /// escapes the root or is otherwise malformed.
  ///
  /// Traversal, absolute paths, drive letters, and backslash separators all
  /// fail closed rather than being normalized into a valid-looking path.
  static String? canonicalPath(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.contains(r'\')) return null;
    if (trimmed.startsWith('/')) return null;
    if (_driveLetter.hasMatch(trimmed)) return null;

    final segments = <String>[];
    for (final segment in trimmed.split('/')) {
      if (segment.isEmpty || segment == '.') continue;
      if (segment == '..') return null;
      segments.add(segment);
    }
    return segments.isEmpty ? null : segments.join('/');
  }

  /// Every operation is denied unless its declared permission is granted.
  static StorageOperationResult authorize(
    StoragePermission permission,
    Set<StoragePermission> granted,
  ) => granted.contains(permission)
      ? StorageOperationResult.ok
      : StorageOperationResult.deniedMissingPermission;

  /// Plans the delta between local and remote revisions deterministically.
  ///
  /// Paths present on both sides with different revisions become conflicts and
  /// are never auto-merged. Paths in [removedLocally] that still exist remotely
  /// become deletions.
  static StorageDeltaPlan planDelta({
    required Map<String, String> localRevisions,
    required Map<String, String> remoteRevisions,
    Set<String> removedLocally = const <String>{},
  }) {
    final uploads = <String>[];
    final downloads = <String>[];
    final deletes = <String>[];
    final conflicts = <String>[];

    for (final entry in localRevisions.entries) {
      final remoteRevision = remoteRevisions[entry.key];
      if (remoteRevision == null) {
        uploads.add(entry.key);
      } else if (remoteRevision != entry.value) {
        conflicts.add(entry.key);
      }
    }
    for (final path in remoteRevisions.keys) {
      if (!localRevisions.containsKey(path)) downloads.add(path);
    }
    for (final path in removedLocally) {
      if (remoteRevisions.containsKey(path)) deletes.add(path);
    }

    return StorageDeltaPlan(
      uploads: _sorted(uploads),
      downloads: _sorted(downloads),
      deletes: _sorted(deletes),
      conflicts: _sorted(conflicts),
    );
  }

  /// Deletion is destructive: invalid paths are denied first, then anything
  /// short of an explicit confirmation is denied.
  static StorageOperationResult delete(String path, {required bool confirmed}) {
    if (canonicalPath(path) == null) {
      return StorageOperationResult.deniedInvalidPath;
    }
    return confirmed
        ? StorageOperationResult.ok
        : StorageOperationResult.deniedUnconfirmed;
  }

  /// Deterministic health from caller-supplied local signals.
  static StorageHealthStatus health({
    required bool reachable,
    required bool authorized,
    required bool withinQuota,
  }) {
    if (!reachable) return StorageHealthStatus.unavailable;
    if (!authorized || !withinQuota) return StorageHealthStatus.degraded;
    return StorageHealthStatus.ok;
  }

  /// Redacts opaque references from diagnostics.
  static String redact(String message) =>
      message.replaceAll(_opaqueReference, '[REDACTED]');

  static List<String> validateManifest(Map<String, dynamic> manifest) {
    final diagnostics = <String>[];
    if (manifest['canonical_step'] != canonicalStep) {
      diagnostics.add('canonical_step_invalid');
    }
    if (manifest['unknown_field_policy'] != 'REJECT') {
      diagnostics.add('unknown_field_policy_invalid');
    }

    final declared = manifest['required_methods'];
    final declaredSet = declared is List
        ? declared.whereType<String>().toSet()
        : <String>{};
    for (final method in requiredMethods) {
      if (!declaredSet.contains(method)) {
        diagnostics.add('method_missing:$method');
      }
    }

    final acceptance = manifest['acceptance'];
    if (acceptance is! Map<String, dynamic>) {
      for (final key in requiredAcceptance) {
        diagnostics.add('acceptance_missing:$key');
      }
      return diagnostics;
    }
    for (final key in requiredAcceptance) {
      if (!acceptance.containsKey(key)) {
        diagnostics.add('acceptance_missing:$key');
      }
    }
    return diagnostics;
  }

  static List<String> validateCanonicalManifest() {
    final file = File(manifestPath);
    if (!file.existsSync()) return <String>['manifest_missing'];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, dynamic>
          ? validateManifest(decoded)
          : <String>['manifest_root_invalid'];
    } on Object {
      return <String>['manifest_unreadable'];
    }
  }

  static List<String> _sorted(List<String> values) =>
      List<String>.unmodifiable(values..sort());
}
