import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_recovery_services.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';

Future<void> _writeSessionMarker(
  File file, {
  required Duration age,
}) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(
    jsonEncode({
      'sessionId': 'stale-marker-session',
      'projectId': 'stale-marker-project',
      'openedAt': DateTime.now().toUtc().toIso8601String(),
    }),
  );
  await file.setLastModified(DateTime.now().subtract(age));
}

void main() {
  test('acquire recovers a stale session marker into recovery snapshot', () async {
    final root = await Directory.systemTemp.createTemp('void-lock-stale-');
    addTearDown(() => root.delete(recursive: true));
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Stale');
    await _writeSessionMarker(
      package.sessionFile,
      age: const Duration(seconds: 120),
    );

    await ProjectSessionLock(package).acquire();

    final recoveryRoot = package.recoveryDirectory;
    expect(await recoveryRoot.exists(), isTrue);
    final staleDirs =
        (await recoveryRoot.list().toList())
            .whereType<Directory>()
            .where((dir) => p.basename(dir.path).startsWith('stale-session-'))
            .toList();
    expect(staleDirs, hasLength(1));
    final kept = File(p.join(staleDirs.single.path, 'session.lock'));
    expect(await kept.exists(), isTrue);
    final keptMarker =
        jsonDecode(await kept.readAsString()) as Map<String, dynamic>;
    expect(keptMarker['sessionId'], 'stale-marker-session');
    final note = File(p.join(staleDirs.single.path, 'recovered.json'));
    expect(await note.exists(), isTrue);
    final recovered =
        jsonDecode(await note.readAsString()) as Map<String, dynamic>;
    expect(recovered['markerAgeSeconds'], greaterThanOrEqualTo(60));
    // The lock now owns a fresh marker; the stale one only lives in the
    // snapshot.
    final live = jsonDecode(
      await package.sessionFile.readAsString(),
    ) as Map<String, dynamic>;
    expect(live['sessionId'], isNot('stale-marker-session'));
  });

  test('acquire still blocks while the session marker is fresh', () async {
    final root = await Directory.systemTemp.createTemp('void-lock-fresh-');
    addTearDown(() => root.delete(recursive: true));
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Fresh');
    await _writeSessionMarker(
      package.sessionFile,
      age: const Duration(seconds: 10),
    );

    await expectLater(
      ProjectSessionLock(package).acquire(),
      throwsA(isA<StateError>()),
    );
    final live = await package.sessionFile.readAsString();
    expect(live, contains('stale-marker-session'));
    final staleDirs =
        (await package.recoveryDirectory.list().toList())
            .whereType<Directory>()
            .where((dir) => p.basename(dir.path).startsWith('stale-session-'))
            .toList();
    expect(staleDirs, isEmpty);
  });

  test('a project left with stale markers opens and closes cleanly', () async {
    final root = await Directory.systemTemp.createTemp('void-lock-open-');
    addTearDown(() => root.delete(recursive: true));
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Reopen Journey');
    await _writeSessionMarker(
      package.sessionFile,
      age: const Duration(seconds: 120),
    );
    await package.lockFile.writeAsString(
      jsonEncode({'sessionId': 'stale-marker-session'}),
    );

    final session = await ProjectSessionManager().open(package);
    expect(await package.sessionFile.exists(), isTrue);
    await session.close();

    expect(await package.sessionFile.exists(), isFalse);
    expect(await package.lockFile.exists(), isFalse);
    final staleDirs =
        (await package.recoveryDirectory.list().toList())
            .whereType<Directory>()
            .where((dir) => p.basename(dir.path).startsWith('stale-session-'))
            .toList();
    expect(staleDirs, hasLength(1));
    expect(
      await File(p.join(staleDirs.single.path, 'session.lock')).exists(),
      isTrue,
    );
  });
}
