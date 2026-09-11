import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/domain/project_model.dart';
import 'package:void_scriptor/core/persistence/project_registry_service.dart';

/// Bug-hunt run197 BUG-19 (Referee REAL BUG, Low) - registry deletion
/// resurrection.
///
/// `remove()` rewrite the registry through `atomicWrite`, which archives the
/// PRE-remove content as `.bak`. `_decodeProjectsWithBackupRecovery` then
/// restores that `.bak` unconditionally whenever the live registry is corrupt
/// (or `recoverIfInterrupted` rolls it forward after a power loss), so an
/// unrelated corruption event silently reverses the user's delete decision:
/// the removed project reappears in the listing.
///
/// Contract of this slice (per the Referee's fix direction): `remove()`
/// durably records deletion intent (a tombstone beside the registry) BEFORE
/// rewriting the registry, and every backup-derived listing filters restored
/// entries against the tombstone. A normal (non-restored) decode is never
/// filtered, and persisting a listing that still contains an id clears its
/// tombstone (re-creating under the same id is a newer decision).
ProjectModel _model(String id, String name, Directory root) => ProjectModel(
  id: id,
  name: name,
  description: '',
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 2),
  lastOpenedAt: DateTime.utc(2026, 1, 2),
  localPath: root.path,
  version: '0.1.0',
);

void main() {
  late Directory root;
  late File registryFile;
  late File tombstoneFile;
  late ProjectRegistryService service;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('vs-bug19-tombstone-');
    registryFile = File('${root.path}${Platform.pathSeparator}projects.json');
    tombstoneFile = File('${registryFile.path}.removed.json');
    service = ProjectRegistryService(rootDirectory: root);
  });

  tearDown(() async {
    try {
      await root.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  Future<void> corruptRegistry() async {
    // Byte-level corruption of the live registry (not a missing file),
    // exactly the run94 BUG-04 trigger that makes backup recovery run.
    await registryFile.writeAsBytes(
      utf8.encode('{"schemaVersion": 1, "proj'),
      flush: true,
    );
  }

  test(
    'run197 BUG-19: corrupt-registry .bak restore does not resurrect a removed project',
    () async {
      await service.save([
        _model('alpha', 'Alpha', root),
        _model('beta', 'Beta', root),
      ]);
      await service.remove('alpha');
      expect(
        tombstoneFile.existsSync(),
        isTrue,
        reason: 'remove() must durably record deletion intent',
      );

      await corruptRegistry();
      final projects = await service.load();

      // RED (pre-fix): the .bak holds the PRE-remove [alpha, beta] listing
      // and is restored verbatim, so Alpha comes back from the dead.
      expect(projects.map((p) => p.name), ['Beta']);
      final healed = await registryFile.readAsString();
      expect(healed, contains('Beta'));
      expect(healed, isNot(contains('Alpha')));
      // The healed registry is durable: a second load never re-resurrects.
      expect((await service.load()).map((p) => p.name), ['Beta']);
    },
  );

  test(
    'run197 BUG-19: power-loss .bak roll-forward does not resurrect a removed project',
    () async {
      await service.save([
        _model('alpha', 'Alpha', root),
        _model('beta', 'Beta', root),
      ]);
      await service.remove('alpha');

      // Crash window of atomicWrite: the live target vanished while the
      // last durable copy (.bak, PRE-remove content) survived.
      await registryFile.delete();
      expect(File('${registryFile.path}.bak').existsSync(), isTrue);

      final projects = await service.load();
      expect(projects.map((p) => p.name), ['Beta']);
    },
  );

  test(
    'run197 BUG-19: re-registering a removed id clears its tombstone',
    () async {
      await service.save([
        _model('alpha', 'Alpha', root),
        _model('beta', 'Beta', root),
      ]);
      await service.remove('alpha');
      expect(tombstoneFile.existsSync(), isTrue);

      // The user re-creates the project under the same id: a deliberate,
      // newer decision must win over the old deletion intent.
      await service.upsert(_model('alpha', 'Alpha Baru', root));
      expect(
        tombstoneFile.existsSync(),
        isFalse,
        reason:
            'persisting a listing that contains the id supersedes the '
            'deletion intent',
      );

      // The live listing shows the re-registered project (the cleared
      // tombstone filters nothing anymore; an older `.bak` restored by a
      // LATER unrelated corruption event follows the documented
      // last-durable-copy semantics, not resurrection).
      final projects = await service.load();
      expect(projects.map((p) => p.name), containsAll(['Alpha Baru', 'Beta']));
      expect(projects, hasLength(2));
    },
  );

  test(
    'run197 BUG-19: an intact registry listing is never filtered by tombstones',
    () async {
      await service.save([_model('beta', 'Beta', root)]);
      await service.remove('beta');
      expect(tombstoneFile.existsSync(), isTrue);

      // A newer durable registry (restored by hand, synced externally,
      // re-added by a future flow) that still lists beta, written straight
      // to disk so the service clear-rule does not consume the tombstone.
      // The healthy decode path must NOT filter this listing.
      await registryFile.writeAsString(
        '${const JsonEncoder.withIndent('  ').convert({
          'schemaVersion': 1,
          'projects': [_model('beta', 'Beta', root).toJson()],
        })}\n',
        flush: true,
      );

      final projects = await service.load();
      expect(projects.map((p) => p.name), ['Beta']);
    },
  );
}
