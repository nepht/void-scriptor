import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/custom_storage_location.dart';

void main() {
  late Directory tempRoot;
  late File registryFile;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('core-hunt-20260906-');
    registryFile = File(
      '${tempRoot.path}${Platform.pathSeparator}storage_locations.json',
    );
  });

  tearDown(() async {
    try {
      await tempRoot.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  File bakOf(File target) => File('${target.path}.bak');

  group('core-hunt-20260906 storage registry corrupt recovery', () {
    test(
      'corrupt registry with no .bak throws the typed unreadable exception '
      'and preserves the corrupt file for inspection',
      () async {
        const corrupt = '{broken json not an object';
        await registryFile.writeAsString(corrupt, flush: true);

        final store = CustomStorageLocationStore(registryFile: registryFile);

        await expectLater(
          store.load(),
          throwsA(isA<CustomStorageRegistryUnreadableException>()),
        );
        expect(await registryFile.exists(), isTrue);
        expect(await registryFile.readAsString(), corrupt);
      },
    );

    test(
      'corrupt registry with a valid .bak restores it and reads the '
      'last durable state',
      () async {
        const durable = <String, Object?>{
          'schemaVersion': 1,
          'activeLocation': null,
          'boundProjectId': 'bound-project',
        };
        await bakOf(
          registryFile,
        ).writeAsString('${jsonEncode(durable)}\n', flush: true);
        await registryFile.writeAsString('{corrupted', flush: true);

        final store = CustomStorageLocationStore(registryFile: registryFile);
        final state = await store.load();

        expect(state.boundProjectId, 'bound-project');
        expect(state.activeLocation, isNull);
        // restoreBackup renames .bak back onto the target.
        expect(await registryFile.exists(), isTrue);
        expect(jsonDecode(await registryFile.readAsString()), durable);
      },
    );

    test(
      'missing target after an interrupted atomic write recovers the .bak '
      'window instead of reporting the default empty state',
      () async {
        const durable = <String, Object?>{
          'schemaVersion': 1,
          'activeLocation': null,
          'boundProjectId': 'power-loss-project',
        };
        await bakOf(
          registryFile,
        ).writeAsString('${jsonEncode(durable)}\n', flush: true);
        // Crash-window leftovers: target gone, stale .tmp never renamed in.
        await File('${registryFile.path}.tmp').writeAsString('{truncat');

        final store = CustomStorageLocationStore(registryFile: registryFile);
        final state = await store.load();

        expect(state.boundProjectId, 'power-loss-project');
        expect(await registryFile.exists(), isTrue);
      },
    );

    test(
      'saves are routed through the shared atomic writer so the previous '
      'durable copy survives as .bak',
      () async {
        const previous = <String, Object?>{
          'schemaVersion': 1,
          'activeLocation': null,
          'boundProjectId': 'older-binding',
        };
        await registryFile.writeAsString('${jsonEncode(previous)}\n');

        final store = CustomStorageLocationStore(registryFile: registryFile);
        await store.setActiveLocation(tempRoot.path);

        expect(await bakOf(registryFile).exists(), isTrue);
        expect(jsonDecode(await bakOf(registryFile).readAsString()), previous);
        final state = await store.load();
        expect(state.activeLocation, isNotNull);
        // setActiveLocation deliberately preserves the binding (documented
        // re-link semantics); the point of this test is the .bak durability.
        expect(state.boundProjectId, 'older-binding');
      },
    );
  });
}
