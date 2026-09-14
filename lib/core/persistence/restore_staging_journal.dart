import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../project_package/project_package.dart';

/// Journal for a two-phase backup restore (145.42 interrupted_restore,
/// 145.34 failure recovery). A restore stages every payload area of the
/// backup inside the package, records the staged bytes here, and only then
/// swaps each staged copy into its live position. A hard kill can therefore
/// land in exactly one of two recoverable states:
///
/// * before any placement — live payload untouched; journal + staging are
///   provable scratch and are discarded;
/// * inside a swap window — the journal names the still-verified staged
///   copy, so the next recovery rolls the restore forward instead of
///   leaving the live area half-gone.
///
/// This file is deliberately free of Flutter imports: a real Dart child
/// process can journal and place staged trees exactly like production does,
/// which is what lets the process-kill harness reproduce the OS-level crash
/// window without the Flutter engine.
class StagedArea {
  const StagedArea({
    required this.relativePath,
    required this.isDirectory,
    this.sha256,
    this.files = const {},
  });

  /// Staged entity path relative to the package root (posix separators).
  final String relativePath;
  final bool isDirectory;

  /// Content fingerprint of a staged file area.
  final String? sha256;

  /// Content fingerprints of every file under a staged directory area.
  final Map<String, String> files;

  Map<String, Object?> toJson() => {
    'path': relativePath,
    'kind': isDirectory ? 'directory' : 'file',
    if (!isDirectory) 'sha256': sha256,
    if (isDirectory) 'files': files,
  };

  static StagedArea? fromJson(Object? decoded) {
    if (decoded is! Map) return null;
    final pathValue = decoded['path'];
    final kind = decoded['kind'];
    if (pathValue is! String) return null;
    if (kind == 'file') {
      final digest = decoded['sha256'];
      if (digest is! String) return null;
      return StagedArea(
        relativePath: pathValue,
        isDirectory: false,
        sha256: digest,
      );
    }
    if (kind == 'directory') {
      final rawFiles = decoded['files'];
      if (rawFiles is! Map) return null;
      final files = <String, String>{};
      for (final entry in rawFiles.entries) {
        if (entry.key is! String || entry.value is! String) return null;
        files[entry.key as String] = entry.value as String;
      }
      return StagedArea(
        relativePath: pathValue,
        isDirectory: true,
        files: files,
      );
    }
    return null;
  }
}

/// The `recovery/restore-staging.json` journal and its staged-placement
/// primitives. Fingerprints are computed from the staged bytes at journal
/// time, so a later verify proves the corpse on disk is still the exact
/// copy the restore was about to place.
class RestoreStagingJournal {
  RestoreStagingJournal._(this.package, this.areas);

  static const manifestArea = 'manifest';
  static const databaseArea = 'database';
  static const assetsArea = 'assets';
  static const workspacesArea = 'workspaces';

  /// Fixed processing order: identity areas first, directory areas last.
  static const areaOrder = <String>[
    manifestArea,
    databaseArea,
    assetsArea,
    workspacesArea,
  ];

  final ProjectPackage package;
  final Map<String, StagedArea> areas;

  File get journalFile => File(journalPathFor(package));

  static String journalPathFor(ProjectPackage package) =>
      p.join(package.recoveryDirectory.path, 'restore-staging.json');

  /// Records the [staged] entities (area -> entity that already exists on
  /// disk) under [package].
  static Future<RestoreStagingJournal> create(
    ProjectPackage package, {
    required Map<String, FileSystemEntity> staged,
  }) async {
    final areas = <String, StagedArea>{};
    for (final area in areaOrder) {
      final entity = staged[area];
      if (entity == null) continue;
      final relative = p
          .relative(entity.path, from: package.root.path)
          .replaceAll('\\', '/');
      if (entity is Directory) {
        areas[area] = StagedArea(
          relativePath: relative,
          isDirectory: true,
          files: await directoryFingerprints(entity),
        );
      } else if (entity is File) {
        areas[area] = StagedArea(
          relativePath: relative,
          isDirectory: false,
          sha256: await fileDigest(entity),
        );
      } else {
        throw ArgumentError.value(
          entity.path,
          'staged[$area]',
          'must be an existing File or Directory',
        );
      }
    }
    final journal = RestoreStagingJournal._(package, areas);
    final file = journal.journalFile;
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
      jsonEncode({
        'version': 1,
        'projectId': package.projectId,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'areas': areas.map(
          (area, stagedArea) => MapEntry(area, stagedArea.toJson()),
        ),
      }),
      flush: true,
    );
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
    return journal;
  }

  /// Loads the journal, or null when absent or structurally invalid. An
  /// invalid journal cannot direct a roll-forward; recovery then falls back
  /// to the conservative scratch sweep.
  static Future<RestoreStagingJournal?> load(ProjectPackage package) async {
    final file = File(journalPathFor(package));
    if (!await file.exists()) return null;
    final Object? decoded;
    try {
      decoded = jsonDecode(await file.readAsString());
    } on Object {
      return null;
    }
    if (decoded is! Map) return null;
    final rawAreas = decoded['areas'];
    if (rawAreas is! Map) return null;
    final areas = <String, StagedArea>{};
    for (final entry in rawAreas.entries) {
      if (entry.key is! String) return null;
      final area = StagedArea.fromJson(entry.value);
      if (area == null) return null;
      areas[entry.key as String] = area;
    }
    return RestoreStagingJournal._(package, areas);
  }

  /// Absolute path of the staged entity recorded for [area].
  String stagedPath(String area) {
    final staged = areas[area];
    if (staged == null) {
      throw ArgumentError.value(area, 'area', 'not journaled');
    }
    return p.joinAll(<String>[
      package.root.path,
      ...p.posix.split(staged.relativePath),
    ]);
  }

  FileSystemEntity stagedEntity(String area) {
    final staged = areas[area];
    if (staged == null) {
      throw ArgumentError.value(area, 'area', 'not journaled');
    }
    final path = stagedPath(area);
    return staged.isDirectory ? Directory(path) : File(path);
  }

  /// True only when the staged entity still exists and matches every
  /// fingerprint recorded at staging time (divergent scratch is provably
  /// not what the restore was about to place).
  Future<bool> stagedMatches(String area) async {
    final staged = areas[area];
    if (staged == null) return false;
    final entity = stagedEntity(area);
    if (staged.isDirectory) {
      if (entity is! Directory) return false;
      final actual = await directoryFingerprints(entity);
      if (actual.length != staged.files.length) return false;
      for (final entry in staged.files.entries) {
        if (actual[entry.key] != entry.value) return false;
      }
      return true;
    }
    if (entity is! File) return false;
    return await fileDigest(entity) == staged.sha256;
  }

  Future<void> consume() async {
    if (await journalFile.exists()) await journalFile.delete();
  }
}

Future<String> fileDigest(File file) async =>
    sha256.convert(await file.readAsBytes()).toString();

/// Sorted relative-path -> sha256 map for every file under [directory].
Future<Map<String, String>> directoryFingerprints(Directory directory) async {
  if (!await directory.exists()) return const {};
  final files = <File>[];
  await for (final entity in directory.list(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is File) files.add(entity);
  }
  files.sort((left, right) => left.path.compareTo(right.path));
  final fingerprints = <String, String>{};
  for (final file in files) {
    final relative = p
        .relative(file.path, from: directory.path)
        .replaceAll('\\', '/');
    fingerprints[relative] = await fileDigest(file);
  }
  return fingerprints;
}

Future<void> _deleteEntity(FileSystemEntity entity) async {
  if (entity is Directory) {
    await entity.delete(recursive: true);
  } else if (entity is File) {
    await entity.delete();
  }
}

FileSystemEntity _entityAt(String path) {
  switch (FileSystemEntity.typeSync(path)) {
    case FileSystemEntityType.directory:
      return Directory(path);
    case FileSystemEntityType.file:
      return File(path);
    default:
      return File(path);
  }
}

Future<void> _renameTo(FileSystemEntity entity, String destination) async {
  if (entity is Directory) {
    await Directory(entity.path).rename(destination);
  } else {
    await File(entity.path).rename(destination);
  }
}

/// Swaps a verified staged entity into its live position through a
/// rename-on-rename window. The live target is renamed out of the way first
/// (Windows renames cannot land on an occupied name), the staged copy
/// renames in, and only then is the displaced original deleted. A kill
/// inside the window leaves EITHER the staged copy in place of a missing
/// live area (roll-forward) OR the displaced original (undo) — never a
/// half-written live area.
Future<void> placeStagedEntity({
  required FileSystemEntity staged,
  required FileSystemEntity live,
}) async {
  final displacedPath = '${live.path}.restore-old';
  if (await _entityExists(displacedPath)) {
    // Orphan of an earlier interrupted swap: this attempt replaces the
    // staged copy anyway, so move the orphan out of the swap name first.
    await _deleteEntity(_entityAt(displacedPath));
  }
  if (await _entityExists(live.path)) {
    await _renameTo(_entityAt(live.path), displacedPath);
  }
  try {
    await _renameTo(staged, live.path);
  } on Object {
    if (await _entityExists(displacedPath) && !await _entityExists(live.path)) {
      // Never leave the live area missing because of a placement failure.
      await _renameTo(_entityAt(displacedPath), live.path);
    }
    rethrow;
  }
  if (await _entityExists(displacedPath)) {
    await _deleteEntity(_entityAt(displacedPath));
  }
}

Future<bool> _entityExists(String path) async =>
    FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;

/// The live payload entity for a journaled restore area.
FileSystemEntity restoreLiveEntityFor(ProjectPackage package, String area) {
  switch (area) {
    case RestoreStagingJournal.manifestArea:
      return package.manifestFile;
    case RestoreStagingJournal.databaseArea:
      return package.databaseFile;
    case RestoreStagingJournal.assetsArea:
      return package.assetsDirectory;
    case RestoreStagingJournal.workspacesArea:
      return Directory(p.join(package.root.path, 'workspaces'));
  }
  throw ArgumentError.value(area, 'area', 'unknown restore area');
}

/// Undoes a not-yet-placed swap: the displaced original returns to the live
/// path. Used when a restore fails AFTER a placement and must roll back to
/// the emergency snapshot instead.
Future<void> restoreDisplacedOriginal({required String livePath}) async {
  final displacedPath = '$livePath.restore-old';
  if (!await _entityExists(displacedPath)) return;
  if (await _entityExists(livePath)) {
    await _deleteEntity(_entityAt(livePath));
  }
  await _renameTo(_entityAt(displacedPath), livePath);
}
