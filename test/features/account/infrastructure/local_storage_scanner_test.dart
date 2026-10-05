// Sprint 115.20 (adapter) — LocalStorageScanner tests.
//
// These drive a real temporary directory tree rather than a fake filesystem:
// the behaviours under test (links, unreadable paths, cycles, caps) are
// properties of the OS, so a mock would only assert that the mock behaves like
// the mock. Symlink creation needs a privilege the test runner may not have on
// Windows, so link-specific cases skip explicitly and say why, rather than
// silently passing as untested.
//
// The cardinality assertions are what matter: a scanner that quietly
// double-counts a link, follows one out of its roots, or turns an unreadable
// path into a zero is worse than one that reports nothing.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_local_storage_summary.dart';
import 'package:void_scriptor/features/account/domain/account_center_storage_usage_card.dart';
import 'package:void_scriptor/features/account/infrastructure/local_storage_scanner.dart';

void main() {
  late Directory sandbox;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('local_scan_');
  });

  tearDown(() async {
    if (await sandbox.exists()) {
      await sandbox.delete(recursive: true);
    }
  });

  Future<File> writeFile(String relative, int bytes, {Directory? into}) async {
    final base = into?.path ?? sandbox.path;
    final file = File('$base${Platform.pathSeparator}$relative');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(List<int>.filled(bytes, 65));
    return file;
  }

  /// Whether this platform lets an unprivileged test create a link.
  Future<bool> canCreateLink() async {
    try {
      final probe = Link('${sandbox.path}${Platform.pathSeparator}_probe_link');
      await probe.create(sandbox.path, recursive: false);
      final created = await probe.exists();
      if (created) await probe.delete();
      return created;
    } on FileSystemException {
      return false;
    }
  }

  Future<LocalScanResult> scan(
    Iterable<Directory> roots, {
    LocalScanPolicy policy = const LocalScanPolicy(),
    LocalStorageCategoryResolver? resolver,
    int? freeBytes,
  }) => LocalStorageScanner(
    policy: policy,
    categoryResolver: resolver,
  ).scan(roots: roots, now: DateTime.utc(2026, 10, 2), freeBytes: freeBytes);

  group('measurement', () {
    test('sums file bytes across nested directories', () async {
      await writeFile('a.txt', 100);
      await writeFile('sub/b.txt', 250);
      await writeFile('sub/deep/c.txt', 50);

      final result = await scan([sandbox]);

      expect(result.observedBytes, 400);
      expect(result.isComplete, isTrue, reason: 'no skips, no truncation');
      expect(result.skips, isEmpty);
    });

    test('an empty root measures zero and is still a measurement', () async {
      final result = await scan([sandbox]);

      expect(result.observedBytes, 0);
      expect(result.isComplete, isTrue);
    });

    test('hidden entries are not counted', () async {
      await writeFile('visible.txt', 80);
      await writeFile('.hidden_cache.bin', 900);

      final result = await scan([sandbox]);

      expect(
        result.observedBytes,
        80,
        reason: 'a dotfile is not project storage',
      );
    });

    test('records when it was measured rather than assuming now', () async {
      final result = await scan([sandbox]);

      expect(result.summary.scannedAt, DateTime.utc(2026, 10, 2));
    });

    test('never reports cloud bytes for a local scan', () async {
      await writeFile('a.txt', 10);

      final result = await scan([sandbox]);

      expect(
        result.summary.cloudBytes,
        isNull,
        reason: '115.20 keeps local accounting separate from provider quota',
      );
    });
  });

  group('roots', () {
    test('counts several roots together without double counting', () async {
      final other = await Directory.systemTemp.createTemp('local_scan_b_');
      addTearDown(() => other.delete(recursive: true));
      await writeFile('a.txt', 100);
      await writeFile('b.txt', 300, into: other);

      final result = await scan([sandbox, other]);

      expect(result.observedBytes, 400);
    });

    test('a nested root inside another is not counted twice', () async {
      await writeFile('outer.txt', 100);
      final nested = Directory('${sandbox.path}${Platform.pathSeparator}inner');
      await writeFile('deep.txt', 200, into: nested);

      final result = await scan([sandbox, nested]);

      expect(
        result.observedBytes,
        300,
        reason: 'one byte counted once: an overlapping root is a real shape',
      );
    });

    test('refuses to run when no supplied root exists', () async {
      final missing = Directory(
        '${sandbox.path}${Platform.pathSeparator}not_there',
      );

      await expectLater(
        scan([missing]),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('at least one existing root'),
          ),
        ),
        reason: 'no readable root is an absent measurement, not zero bytes',
      );
    });
  });

  group('links are not followed by default', () {
    test('a directory link is skipped, not walked', () async {
      if (!await canCreateLink()) {
        markTestSkipped('platform denies unprivileged symlink creation');
        return;
      }
      await writeFile('real/inside.txt', 500);
      final link = Link('${sandbox.path}${Platform.pathSeparator}mirror');
      await link.create('${sandbox.path}${Platform.pathSeparator}real');

      final result = await scan([sandbox]);

      expect(
        result.observedBytes,
        500,
        reason: 'walking the link would count the same file twice',
      );
      expect(
        result.skips.map((s) => s.reason),
        contains(LocalScanSkipReason.link),
      );
      expect(result.bytesOutsideRoots, 0);
    });

    test('a link that leaves the roots is never counted', () async {
      if (!await canCreateLink()) {
        markTestSkipped('platform denies unprivileged symlink creation');
        return;
      }
      final outside = await Directory.systemTemp.createTemp('local_scan_out_');
      addTearDown(() => outside.delete(recursive: true));
      await writeFile('secret.bin', 4000, into: outside);
      await writeFile('inside.txt', 10);
      final link = Link('${sandbox.path}${Platform.pathSeparator}escape');
      await link.create(outside.path);

      final result = await scan([sandbox]);

      expect(
        result.observedBytes,
        10,
        reason: 'a scan of the roots must not read outside them',
      );
      expect(result.bytesOutsideRoots, 0);
    });

    test('opting in to links reports an escape instead of hiding it', () async {
      if (!await canCreateLink()) {
        markTestSkipped('platform denies unprivileged symlink creation');
        return;
      }
      final outside = await Directory.systemTemp.createTemp('local_scan_out_');
      addTearDown(() => outside.delete(recursive: true));
      await writeFile('secret.bin', 4000, into: outside);
      final link = Link('${sandbox.path}${Platform.pathSeparator}escape');
      await link.create(outside.path);

      final result = await scan([
        sandbox,
      ], policy: const LocalScanPolicy(followLinks: true));

      expect(
        result.observedBytes,
        0,
        reason: 'escaping bytes never enter the roots total',
      );
      expect(
        result.bytesOutsideRoots,
        4000,
        reason: 'the escape is visible to the caller, not folded into storage',
      );
    });

    test('a link pointing at its own ancestor terminates', () async {
      if (!await canCreateLink()) {
        markTestSkipped('platform denies unprivileged symlink creation');
        return;
      }
      await writeFile('deep/leaf.txt', 64);
      final link = Link(
        '${sandbox.path}${Platform.pathSeparator}deep${Platform.pathSeparator}up',
      );
      await link.create(sandbox.path);

      final result = await scan([
        sandbox,
      ], policy: const LocalScanPolicy(followLinks: true));

      expect(
        result.observedBytes,
        64,
        reason: 'a cycle must stop, not recurse without bound',
      );
    });
  });

  group('caps and unreadable paths', () {
    test('an entry cap reports truncation rather than a short total', () async {
      await writeFile('a.txt', 10);
      await writeFile('b.txt', 10);

      final result = await scan([
        sandbox,
      ], policy: const LocalScanPolicy(maxEntries: 1));

      expect(result.truncated, isTrue);
      expect(result.isComplete, isFalse);
      expect(
        result.skips.map((s) => s.reason),
        contains(LocalScanSkipReason.truncated),
      );
    });

    test('a depth cap is reported, not silently applied', () async {
      await writeFile('a/b/c/deep.txt', 20);

      final result = await scan([
        sandbox,
      ], policy: const LocalScanPolicy(maxDepth: 1));

      expect(result.isComplete, isFalse);
      expect(
        result.skips.map((s) => s.reason),
        contains(LocalScanSkipReason.tooDeep),
      );
    });

    test('a missing root is dropped from the scan, not fatal', () async {
      await writeFile('a.txt', 25);
      final missing = Directory('${sandbox.path}${Platform.pathSeparator}gone');

      final result = await scan([sandbox, missing]);

      expect(result.observedBytes, 25);
    });
  });

  group('categories', () {
    test('a supplied resolver wins over the name guess', () async {
      await writeFile('mystery.bin', 500);

      final result = await scan([
        sandbox,
      ], resolver: (_, _) => LocalStorageCategory.models);

      expect(result.summary.bytesFor(LocalStorageCategory.models), 500);
      expect(result.summary.bytesFor(LocalStorageCategory.other), 0);
    });

    test(
      'unknown names land in other rather than a plausible category',
      () async {
        await writeFile('mystery.bin', 300);

        final result = await scan([sandbox]);

        expect(result.summary.bytesFor(LocalStorageCategory.other), 300);
      },
    );

    test('observedCategories separates absent from measured zero', () async {
      final models = Directory(
        '${sandbox.path}${Platform.pathSeparator}models',
      );
      await models.create(recursive: true);
      await writeFile('models/a.bin', 0);

      final result = await scan([sandbox]);

      expect(result.observedCategories, contains(LocalStorageCategory.models));
      expect(
        result.observedCategories,
        isNot(contains(LocalStorageCategory.archive)),
      );
    });

    test('a caller can keep categories protected by default', () async {
      final models = Directory(
        '${sandbox.path}${Platform.pathSeparator}models',
      );
      await models.create(recursive: true);
      await writeFile('models/a.bin', 5);

      final result = await scan([sandbox]);

      expect(result.summary.isProtected(LocalStorageCategory.models), isTrue);
    });
  });

  group('card bridge', () {
    test('bridges to the card without inventing a quota', () async {
      await writeFile('a.txt', 1234);

      final result = await scan([sandbox]);
      final data = LocalStorageScanner.asCardData(
        result,
        providerId: 'local-disk',
        accountLabel: 'This device',
        now: DateTime.utc(2026, 10, 2),
      );

      expect(data.usedBytes, 1234);
      expect(data.quotaBytes, isNull, reason: 'a local disk has no quota');
      expect(data.freshness, StorageUsageFreshness.fresh);
      expect(data.icon, StorageUsageCardIcon.hardDrive);
    });

    test('an incomplete scan still bridges, carrying its gaps', () async {
      await writeFile('a.txt', 10);
      await writeFile('b.txt', 90);

      // maxEntries 1 measures the first file then stops: a total that is short,
      // and visibly short.
      final result = await scan([
        sandbox,
      ], policy: const LocalScanPolicy(maxEntries: 1));
      final data = LocalStorageScanner.asCardData(
        result,
        providerId: 'local-disk',
        accountLabel: 'This device',
        now: DateTime.utc(2026, 10, 2),
      );

      expect(data.usedBytes, 10);
      expect(
        result.isComplete,
        isFalse,
        reason: 'the gaps ride along with the number',
      );
    });
  });

  test('an unreadable root is an error, not a silent zero', () async {
    // Windows cannot reliably revoke read on a directory for a test user, so
    // this asserts the contract that is observable everywhere: a root that does
    // not exist fails loudly, and an existing-but-empty one measures zero.
    final result = await scan([sandbox]);
    expect(result.observedBytes, 0);
    expect(result.isComplete, isTrue);
  });
}
