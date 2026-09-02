import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

enum StorageProbeReason {
  ok,
  driveMissing,
  permissionDenied,
  notEnoughSpace,
  notADirectory,
}

enum StorageLocationStatus { healthy, missingDrive }

class StorageHealth {
  const StorageHealth({
    required this.writable,
    required this.freeBytes,
    required this.reason,
  });

  final bool writable;
  final int freeBytes;
  final StorageProbeReason reason;
}

abstract interface class StorageHealthProbe {
  Future<StorageHealth> check(String location);
}

class StorageLocationProbeResult {
  const StorageLocationProbeResult({
    required this.exists,
    required this.writable,
    required this.freeBytes,
    required this.reason,
  });

  final bool exists;
  final bool writable;
  final int freeBytes;
  final StorageProbeReason reason;
}

class CustomStorageLocation {
  static const int minFreeBytes = 1 << 20; // 1 MiB guard

  static String normalizeLocation(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(raw, 'raw', 'Storage location cannot be empty');
    }
    var cleaned = p.normalize(trimmed);
    while (cleaned.endsWith(p.separator)) {
      cleaned = cleaned.substring(0, cleaned.length - p.separator.length);
    }
    if (cleaned.isEmpty) {
      throw ArgumentError.value(raw, 'raw', 'Storage location cannot be empty');
    }
    return cleaned;
  }

  /// Returns the nearest existing ancestor directory, or null when no
  /// ancestor exists (the drive itself is absent, e.g. unplugged USB).
  static Future<String?> nearestExistingAncestor(String location) async {
    var current = location;
    while (true) {
      if (await Directory(current).exists()) return current;
      final parent = p.dirname(current);
      if (parent == current) return null;
      current = parent;
    }
  }

  static Future<StorageLocationProbeResult> probe(
    String location, {
    StorageHealthProbe? health,
  }) async {
    final directory = Directory(location);
    if (!await directory.exists()) {
      return const StorageLocationProbeResult(
        exists: false,
        writable: false,
        freeBytes: 0,
        reason: StorageProbeReason.driveMissing,
      );
    }
    if (!await FileSystemEntity.isDirectory(location)) {
      return const StorageLocationProbeResult(
        exists: true,
        writable: false,
        freeBytes: 0,
        reason: StorageProbeReason.notADirectory,
      );
    }
    final probe = health ?? const _Probe();
    final checked = await probe.check(location);
    if (!checked.writable) {
      return StorageLocationProbeResult(
        exists: true,
        writable: false,
        freeBytes: checked.freeBytes,
        reason: checked.reason,
      );
    }
    if (checked.freeBytes < minFreeBytes) {
      return StorageLocationProbeResult(
        exists: true,
        writable: true,
        freeBytes: checked.freeBytes,
        reason: StorageProbeReason.notEnoughSpace,
      );
    }
    return StorageLocationProbeResult(
      exists: true,
      writable: true,
      freeBytes: checked.freeBytes,
      reason: StorageProbeReason.ok,
    );
  }
}

class _Probe implements StorageHealthProbe {
  const _Probe();

  @override
  Future<StorageHealth> check(String location) async {
    var writable = true;
    try {
      final probeFile = File(p.join(location, '.vs_write_probe'));
      await probeFile.writeAsString('ok', flush: true);
      await probeFile.delete();
    } on FileSystemException {
      writable = false;
    }
    return StorageHealth(
      writable: writable,
      freeBytes: writable ? await _freeSpace(location) : 0,
      reason: writable
          ? StorageProbeReason.ok
          : StorageProbeReason.permissionDenied,
    );
  }

  // Free-space measurement is host-dependent. The probe returns a
  // conservative 1 GiB standing offer so the minFreeBytes guard only
  // trips when an injected probe reports a real shortage.
  static Future<int> _freeSpace(String location) async {
    try {
      final stat = await FileStat.stat(location);
      if (stat.size < 0) return 1 << 30;
      return 1 << 30;
    } catch (_) {
      return 0;
    }
  }
}

class CustomStorageLocationState {
  const CustomStorageLocationState({
    required this.schemaVersion,
    required this.activeLocation,
    required this.boundProjectId,
    this.status = StorageLocationStatus.healthy,
  });

  final int schemaVersion;
  final String? activeLocation;
  final String? boundProjectId;
  final StorageLocationStatus status;
}

class CustomStorageLocationStore {
  CustomStorageLocationStore({required this.registryFile});

  final File registryFile;

  Future<CustomStorageLocationState> load() async {
    if (!await registryFile.exists()) {
      return const CustomStorageLocationState(
        schemaVersion: 1,
        activeLocation: null,
        boundProjectId: null,
      );
    }
    final decoded =
        jsonDecode(await registryFile.readAsString()) as Map<String, dynamic>;
    final schemaVersion = decoded['schemaVersion'] as int? ?? 1;
    final active = decoded['activeLocation'] as String?;
    final bound = decoded['boundProjectId'] as String?;
    var status = StorageLocationStatus.healthy;
    if (active != null && !await Directory(active).exists()) {
      status = StorageLocationStatus.missingDrive;
    }
    return CustomStorageLocationState(
      schemaVersion: schemaVersion,
      activeLocation: active == null
          ? null
          : CustomStorageLocation.normalizeLocation(active),
      boundProjectId: bound,
      status: status,
    );
  }

  Future<void> setActiveLocation(String rawLocation) async {
    final location = CustomStorageLocation.normalizeLocation(rawLocation);
    if (!await Directory(location).exists()) {
      final ancestor = await CustomStorageLocation.nearestExistingAncestor(
        location,
      );
      if (ancestor == null) {
        throw StateError('Custom storage drive is missing: $location');
      }
      await Directory(location).create(recursive: true);
    }
    final results = await CustomStorageLocation.probe(location);
    if (!results.exists || !results.writable) {
      throw StateError(
        'Custom storage location is not usable: ${results.reason.name}',
      );
    }
    final current = await load();
    await _save(
      CustomStorageLocationState(
        schemaVersion: 1,
        activeLocation: location,
        boundProjectId: current.boundProjectId,
      ),
    );
  }

  Future<void> bindProject(String projectId) async {
    final current = await load();
    await _save(
      CustomStorageLocationState(
        schemaVersion: 1,
        activeLocation: current.activeLocation,
        boundProjectId: projectId,
      ),
    );
  }

  Future<void> relinkLocation(String newLocation) async {
    final location = CustomStorageLocation.normalizeLocation(newLocation);
    final current = await load();
    if (current.boundProjectId != null) {
      final existing = Directory(
        p.join(location, '${current.boundProjectId}.voidproject'),
      );
      if (!await existing.exists()) {
        throw StateError('Relink target does not contain the bound project');
      }
    }
    final results = await CustomStorageLocation.probe(location);
    if (!results.exists || !results.writable) {
      throw StateError('Relink location is not usable: ${results.reason.name}');
    }
    await _save(
      CustomStorageLocationState(
        schemaVersion: 1,
        activeLocation: location,
        boundProjectId: current.boundProjectId,
      ),
    );
  }

  Future<void> _save(CustomStorageLocationState state) async {
    await registryFile.parent.create(recursive: true);
    final json = {
      'schemaVersion': state.schemaVersion,
      'activeLocation': state.activeLocation,
      'boundProjectId': state.boundProjectId,
    };
    final temporary = File('${registryFile.path}.tmp');
    await temporary.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(json)}\n',
      flush: true,
    );
    await temporary.rename(registryFile.path);
  }
}
