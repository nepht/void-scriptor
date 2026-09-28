import 'dart:collection';

/// Local, fail-closed evidence contract for Sprint 116.20.
final class CrossStorageSyncBackupCertification {
  CrossStorageSyncBackupCertification({
    required this.queue,
    required this.retryResume,
    required this.conflictResolution,
    required this.encryptedBackup,
    required this.restore,
    required List<String> workspaceBoundaries,
    required this.largeAssets,
    required List<String> limitations,
  }) : workspaceBoundaries = List.unmodifiable(workspaceBoundaries),
       limitations = List.unmodifiable(limitations) {
    if (queue.isEmpty ||
        retryResume.isEmpty ||
        conflictResolution.isEmpty ||
        encryptedBackup.isEmpty ||
        restore.isEmpty ||
        largeAssets.isEmpty ||
        this.workspaceBoundaries.isEmpty ||
        this.limitations.isEmpty) {
      throw ArgumentError('All certification outputs must be non-empty.');
    }
  }

  factory CrossStorageSyncBackupCertification.fromJson(
    Map<String, Object?> json,
  ) {
    const keys = {
      'queue',
      'retry_resume',
      'conflict_resolution',
      'encrypted_backup',
      'restore',
      'workspace_boundaries',
      'large_assets',
      'limitations',
    };
    if (!keys.containsAll(json.keys) || json.keys.length != keys.length) {
      throw ArgumentError('Unknown or missing certification output.');
    }

    List<String> listValue(String key) {
      final value = json[key];
      if (value is! List || value.any((item) => item is! String)) {
        throw ArgumentError.value(value, key, 'must be a string list');
      }
      return List<String>.from(value);
    }

    String stringValue(String key) {
      final value = json[key];
      if (value is! String) throw ArgumentError.value(value, key);
      return value;
    }

    return CrossStorageSyncBackupCertification(
      queue: stringValue('queue'),
      retryResume: stringValue('retry_resume'),
      conflictResolution: stringValue('conflict_resolution'),
      encryptedBackup: stringValue('encrypted_backup'),
      restore: stringValue('restore'),
      workspaceBoundaries: listValue('workspace_boundaries'),
      largeAssets: stringValue('large_assets'),
      limitations: listValue('limitations'),
    );
  }

  final String queue;
  final String retryResume;
  final String conflictResolution;
  final String encryptedBackup;
  final String restore;
  final List<String> workspaceBoundaries;
  final String largeAssets;
  final List<String> limitations;

  bool get isComplete => true;

  Map<String, Object?> toJson() => UnmodifiableMapView({
    'queue': queue,
    'retry_resume': retryResume,
    'conflict_resolution': conflictResolution,
    'encrypted_backup': encryptedBackup,
    'restore': restore,
    'workspace_boundaries': workspaceBoundaries,
    'large_assets': largeAssets,
    'limitations': limitations,
  });
}
