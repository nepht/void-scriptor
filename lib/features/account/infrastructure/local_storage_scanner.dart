/// Sprint 115.20 (adapter) — Local storage scanner.
///
/// The one thing this product knows for certain about its own disk usage is
/// what is on its own disk. [LocalStorageSummary] has been complete and
/// tested since 115.20 and nothing ever called it: there was no scanner, so
/// `StorageUsageCard` renders with no `data` and reports "Usage unavailable"
/// forever.
///
/// This is that scanner, and it is deliberately cautious, because it walks a
/// user's real filesystem.
///
/// **It never leaves the roots it was given.** Every entry is checked against
/// the scan roots, and [LocalScanPolicy.followLinks] defaults to false: a
/// Windows junction or a symlink can point anywhere, including outside the
/// project, and following it would let a scan of a 200 MB folder walk a whole
/// drive, double-count a subtree, or - through a link cycle - never terminate.
/// A user who opts in gets that choice explicitly.
///
/// **A file it cannot read is counted as unread, not as zero.** Failing to read
/// a directory is a fact worth reporting; silently returning 0 for it would make
/// a permission problem look like an empty folder and turn an unknown into a
/// measured result.
///
/// **It measures, it does not delete, move, or write.** Nothing here mutates the
/// filesystem. It reads names and lengths.
///
/// Cloud bytes stay absent. 115.20's contract keeps local accounting separate
/// from provider quota on purpose, and a local scan must not be laundered into
/// a cloud reading: [LocalStorageSummary.cloudBytes] is still null, and
/// [LocalScanResult.asCardData] refuses to invent a quota it does not have.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import '../domain/account_center_local_storage_summary.dart';
import '../domain/account_center_storage_usage_card.dart';

/// How a scan treats links, cycles, and unreadable paths.
final class LocalScanPolicy {
  const LocalScanPolicy({
    this.followLinks = false,
    this.maxDepth = 24,
    this.maxEntries = 400000,
  });

  /// Default posture: do not follow symlinks or Windows junctions. A link can
  /// leave the scan roots, revisit a subtree, or point at a device, so the
  /// safe answer is to not walk it and to say that it was skipped.
  final bool followLinks;

  /// Depth cap so a pathological tree cannot recurse without bound. 24 is far
  /// beyond any real project layout.
  final int maxDepth;

  /// Entry cap. A scan that hits it reports truncation rather than returning a
  /// partial total as if it were complete.
  final int maxEntries;

  /// How many entries to descend into before refusing. Guards a cycle even
  /// when a caller opts into following links.
  static const int defaultMaxDescents = 20000;
}

/// Why a path was not counted.
enum LocalScanSkipReason {
  /// Outside every configured scan root.
  outsideRoots,

  /// A symlink or junction that policy declined to follow.
  link,

  /// Deeper than [LocalScanPolicy.maxDepth].
  tooDeep,

  /// Beyond [LocalScanPolicy.maxEntries].
  truncated,

  /// The OS refused to read it.
  unreadable,

  /// A directory whose identity was already visited on this path, which is what
  /// a link cycle looks like from inside the scan.
  cycle,
}

/// One path the scan declined to count, and why.
final class LocalScanSkip {
  const LocalScanSkip(this.path, this.reason, [this.detail]);

  final String path;
  final LocalScanSkipReason reason;

  /// Short, non-identifying detail (an OS error message), never a full path to
  /// user data beyond what the caller already supplied.
  final String? detail;

  @override
  String toString() =>
      '${reason.name}@${p.basename(path)}${detail == null ? '' : ': $detail'}';
}

/// What a scan observed, including everything it could not read.
final class LocalScanResult {
  LocalScanResult._({
    required this.summary,
    required this.skips,
    required this.truncated,
    required this.bytesOutsideRoots,
  });

  final LocalStorageSummary summary;

  /// Every path not counted, so a partial scan is visibly partial.
  final List<LocalScanSkip> skips;

  /// True when the entry cap stopped the walk.
  final bool truncated;

  /// Bytes found outside the scan roots. Non-zero means a link escaped the
  /// roots and was followed anyway - which policy forbids by default, so this
  /// staying at zero is an invariant worth asserting.
  final int bytesOutsideRoots;

  /// Whether the scan is complete enough to present as a measurement.
  ///
  /// A scan with skips or truncation is not a smaller number, it is a less
  /// known one, and the UI must be able to say which it has.
  bool get isComplete => skips.isEmpty && !truncated;

  /// Total bytes actually observed.
  int get observedBytes => summary.totalBytes;

  /// The categories the scan actually reached, so a caller can tell an absent
  /// category from one that was visited and genuinely measured zero.
  ///
  /// Taken from the keys the walk produced, not from a `> 0` filter over the
  /// bytes: an empty file is a real measurement of zero, and deriving the
  /// answer from the byte values would report it as absent.
  late final Set<LocalStorageCategory> observedCategories = Set.unmodifiable(
    summary.observedCategoryKeys,
  );
}

/// Maps a scanned file to the 115.20 category set.
///
/// [relativePath] is the file's path beneath its scan root, so a rule can
/// match on the directory it sits in; [basename] is the leaf name.
typedef LocalStorageCategoryResolver =
    LocalStorageCategory Function(String relativePath, String basename);

/// Walks the given roots and produces a [LocalStorageSummary].
///
/// Roots are explicit and never inferred. A caller who wants the project folder
/// passes the project folder; this class will not go looking for a home
/// directory, a documents folder, or a registry.
final class LocalStorageScanner {
  const LocalStorageScanner({
    this.policy = const LocalScanPolicy(),
    this.categoryResolver,
    this.onProgress,
  });

  final LocalScanPolicy policy;

  /// Decides which category a file belongs to. Defaults to a name-based
  /// classification so the scanner is useful without configuration, and so a
  /// caller with real knowledge can replace the guess with the truth.
  final LocalStorageCategoryResolver? categoryResolver;

  /// Called with the running byte total so a UI can show a scan progressing
  /// rather than frozen.
  final void Function(int observedBytes)? onProgress;

  Future<LocalScanResult> scan({
    required Iterable<Directory> roots,
    required DateTime now,
    int? freeBytes,
    Set<LocalStorageCategory> protectedCategories = const {
      LocalStorageCategory.projects,
      LocalStorageCategory.assets,
      LocalStorageCategory.models,
    },
  }) async {
    final resolvedRoots = <Directory>[];
    for (final root in roots) {
      if (await root.exists()) resolvedRoots.add(root);
    }
    if (resolvedRoots.isEmpty) {
      // No readable root is not zero bytes. It is an absent measurement.
      throw StateError(
        'LocalStorageScanner.scan requires at least one existing root; '
        'none of ${roots.length} supplied roots exists.',
      );
    }

    final rootPaths = {
      for (final root in resolvedRoots) _normalize(root.absolute.path),
    };
    final bytes = <LocalStorageCategory, int>{};
    final skips = <LocalScanSkip>[];
    final visited = <String>{};
    var truncated = false;
    var outsideBytes = 0;
    var visitedEntries = 0;
    var descents = 0;

    Future<void> walk(
      Directory directory, {
      required int depth,
      required String relative,
    }) async {
      if (depth > policy.maxDepth) {
        skips.add(LocalScanSkip(directory.path, LocalScanSkipReason.tooDeep));
        return;
      }
      if (descents >= LocalScanPolicy.defaultMaxDescents) {
        truncated = true;
        skips.add(LocalScanSkip(directory.path, LocalScanSkipReason.truncated));
        return;
      }

      List<FileSystemEntity> entries;
      try {
        entries = await directory.list(followLinks: false).toList();
      } on FileSystemException catch (error) {
        skips.add(
          LocalScanSkip(
            directory.path,
            LocalScanSkipReason.unreadable,
            error.osError?.message,
          ),
        );
        return;
      }

      for (final entity in entries) {
        if (visitedEntries >= policy.maxEntries) {
          // Truncation with no skip would be indistinguishable from a smaller
          // measurement: the caller would see a number with no reason attached.
          // The boundary that stopped the walk is itself the skip.
          truncated = true;
          skips.add(
            LocalScanSkip(directory.path, LocalScanSkipReason.truncated),
          );
          return;
        }
        visitedEntries += 1;

        final name = p.basename(entity.path);
        if (name.startsWith('.')) continue;
        final childRelative = relative.isEmpty ? name : p.join(relative, name);

        if (entity is Link) {
          if (!policy.followLinks) {
            skips.add(LocalScanSkip(entity.path, LocalScanSkipReason.link));
            continue;
          }
          final target = await entity.target();
          final targetPath = _normalize(Directory(target).absolute.path);
          if (!rootPaths.any((r) => _isUnder(targetPath, r))) {
            // Following an escaping link is exactly what the default policy
            // refuses. Counted separately so it can never be mistaken for
            // storage the roots own.
            outsideBytes += await _sizeOfEscaping(entity, skips);
            continue;
          }
          if (!visited.add(targetPath)) {
            skips.add(LocalScanSkip(entity.path, LocalScanSkipReason.cycle));
            continue;
          }
          final linked = Directory(target);
          if (await linked.exists()) {
            descents += 1;
            await walk(linked, depth: depth + 1, relative: childRelative);
          }
          continue;
        }

        if (entity is Directory) {
          final key = _normalize(entity.absolute.path);
          if (!visited.add(key)) {
            skips.add(LocalScanSkip(entity.path, LocalScanSkipReason.cycle));
            continue;
          }
          if (!_underAnyRoot(entity.absolute.path, rootPaths)) {
            skips.add(
              LocalScanSkip(entity.path, LocalScanSkipReason.outsideRoots),
            );
            outsideBytes += await _sizeOfEscaping(entity, skips);
            continue;
          }
          descents += 1;
          await walk(entity, depth: depth + 1, relative: childRelative);
          continue;
        }

        if (entity is File) {
          if (!_underAnyRoot(entity.absolute.path, rootPaths)) {
            skips.add(
              LocalScanSkip(entity.path, LocalScanSkipReason.outsideRoots),
            );
            outsideBytes += await _sizeOfEscaping(entity, skips);
            continue;
          }
          final category = _categoryFor(childRelative, name);
          // Measured once, not inside both closures: `length()` is an I/O call
          // and the two-closure form would read the file twice for every entry.
          final size = await _sizeOf(entity, skips);
          bytes.update(category, (value) => value + size, ifAbsent: () => size);
        }
      }
      onProgress?.call(bytes.values.fold(0, (a, b) => a + b));
    }

    for (final root in resolvedRoots) {
      // Each root is claimed before it is walked. Without this, a root nested
      // inside another root is walked twice and its bytes counted twice: the
      // `visited` set is what makes "counted once" true, and it has to include
      // the starting points, not only the entries discovered beneath them.
      if (!visited.add(_normalize(root.absolute.path))) {
        skips.add(LocalScanSkip(root.path, LocalScanSkipReason.cycle));
        continue;
      }
      descents += 1;
      await walk(root, depth: 0, relative: '');
    }

    final scannedAt = now.toUtc();
    return LocalScanResult._(
      summary: LocalStorageSummary.fromScan(
        scannedAt: scannedAt,
        // freeBytes is a caller fact about the volume, not a scan finding; the
        // scanner never guesses it, so it stays absent unless supplied.
        freeBytes: freeBytes ?? 0,
        categories: bytes,
        protectedCategories: protectedCategories,
      ),
      skips: List.unmodifiable(skips),
      truncated: truncated,
      bytesOutsideRoots: outsideBytes,
    );
  }

  /// Classifies by the file's path relative to its scan root, not by its bare
  /// name. A file at `models/ref.safetensors` belongs with the models whether
  /// or not its own name says so, and classifying on the basename alone would
  /// file the entire contents of a category directory under `other`.
  LocalStorageCategory _categoryFor(String relative, String basename) =>
      categoryResolver?.call(relative, basename) ??
      _defaultCategory(relative.isEmpty ? basename : relative);

  /// Bytes of a subtree reached through a link that left the scan roots.
  ///
  /// Counted separately from [LocalStorageSummary] so an escaping link can
  /// never inflate the roots' own total. Default policy never calls this,
  /// because it refuses to follow such a link at all; it exists so opting in
  /// reports the escape rather than hiding it.
  static Future<int> _sizeOfEscaping(
    FileSystemEntity entity,
    List<LocalScanSkip> skips,
  ) async {
    if (entity is! Link) return 0;
    try {
      final target = Directory(await entity.target());
      if (!await target.exists()) return 0;
      var total = 0;
      await for (final child in target.list(
        recursive: true,
        followLinks: false,
      )) {
        if (child is File) total += await _sizeOf(child, skips);
      }
      return total;
    } on FileSystemException catch (error) {
      skips.add(
        LocalScanSkip(
          entity.path,
          LocalScanSkipReason.unreadable,
          error.osError?.message,
        ),
      );
      return 0;
    }
  }

  static Future<int> _sizeOf(File file, List<LocalScanSkip> skips) async {
    try {
      return await file.length();
    } on FileSystemException catch (error) {
      // An unreadable file is a fact, not a zero. Recording it keeps a
      // permission problem from being rendered as an empty folder.
      skips.add(
        LocalScanSkip(
          file.path,
          LocalScanSkipReason.unreadable,
          error.osError?.message,
        ),
      );
      return 0;
    }
  }

  /// A deliberately simple path-based classification.
  ///
  /// It is a starting point, not an authority: the product's real category
  /// rules belong behind [categoryResolver], and a caller that does not supply
  /// one gets a guess that is at least visible rather than a fabricated
  /// breakdown. Unknown names land in `other` rather than being assigned to a
  /// category that would read as measured.
  static LocalStorageCategory _defaultCategory(String relativePath) {
    // Normalized separators so a Windows-authored relative path and a
    // POSIX-authored one classify identically.
    final lower = relativePath.replaceAll('\\', '/').toLowerCase();
    if (lower == 'projects' || lower.contains('project')) {
      return LocalStorageCategory.projects;
    }
    if (lower == 'assets' || lower.contains('asset')) {
      return LocalStorageCategory.assets;
    }
    if (lower == 'models' || lower.contains('model')) {
      return LocalStorageCategory.models;
    }
    if (lower == 'archive' || lower == 'backups' || lower.contains('backup')) {
      return LocalStorageCategory.archive;
    }
    if (lower == 'cache' || lower.contains('cache')) {
      return LocalStorageCategory.cache;
    }
    if (lower == 'temp' || lower == 'tmp' || lower.contains('temp')) {
      return LocalStorageCategory.temp;
    }
    return LocalStorageCategory.other;
  }

  static String _normalize(String path) =>
      p.normalize(p.absolute(path)).toLowerCase();

  static bool _isUnder(String child, String root) =>
      child == root || p.isWithin(root, child);

  static bool _underAnyRoot(String path, Set<String> roots) =>
      roots.any((root) => _isUnder(_normalize(path), root));

  /// Bridges a completed scan to the cloud-facing card.
  ///
  /// It refuses to pretend: a local scan has no quota, so this produces
  /// [StorageUsageCardData.unknownQuota] rather than inventing a denominator.
  /// A card that shows "used, quota unavailable" is honest; one that shows a
  /// percentage it computed from a local disk and a cloud total would not be.
  static StorageUsageCardData asCardData(
    LocalScanResult result, {
    required String providerId,
    required String accountLabel,
    required DateTime now,
    StorageUsageCardIcon icon = StorageUsageCardIcon.hardDrive,
  }) {
    final summary = result.summary;
    return StorageUsageCardData.unknownQuota(
      providerId: providerId,
      accountLabel: accountLabel,
      usedBytes: summary.totalBytes,
      measuredAt: summary.scannedAt,
      now: now,
      icon: icon,
    );
  }
}
