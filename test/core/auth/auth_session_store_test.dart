import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/auth/auth_session.dart';
import 'package:void_scriptor/core/auth/auth_session_store_io.dart';
import 'package:void_scriptor/core/auth/auth_status.dart';

void main() {
  late Directory tempDir;
  late File sessionFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('vs_auth_store_test');
    sessionFile = File('${tempDir.path}${Platform.pathSeparator}session.json');
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } on FileSystemException catch (_) {}
  });

  test(
    'save writes a JSON file with status and metadata, no credentials',
    () async {
      final store = AuthSessionStoreIo(file: sessionFile);
      await store.save(const AuthSession.guest());

      expect(sessionFile.existsSync(), isTrue);
      final Map<String, dynamic> json =
          jsonDecode(sessionFile.readAsStringSync()) as Map<String, dynamic>;
      expect(json['status'], 'guest');
      expect(json.containsKey('userId'), isTrue);
      expect(json.containsKey('email'), isTrue);
      expect(json['userId'], isNull);
      expect(json['email'], isNull);
    },
  );

  test('load restores a guest session from disk', () async {
    final store = AuthSessionStoreIo(file: sessionFile);
    await store.save(const AuthSession.guest());

    final restored = await store.load();
    expect(restored, isNotNull);
    expect(restored!.status, AuthStatus.guest);
  });

  test('load returns null on corrupted JSON instead of crashing', () async {
    sessionFile.writeAsStringSync('{ not valid json');
    final store = AuthSessionStoreIo(file: sessionFile);

    final restored = await store.load();
    expect(restored, isNull);
  });

  test('clear removes the persisted session file', () async {
    final store = AuthSessionStoreIo(file: sessionFile);
    await store.save(const AuthSession.guest());
    expect(sessionFile.existsSync(), isTrue);

    await store.clear();
    expect(sessionFile.existsSync(), isFalse);
  });

  test('load returns null for a missing file (fresh install)', () async {
    final store = AuthSessionStoreIo(file: sessionFile);
    final restored = await store.load();
    expect(restored, isNull);
  });
}
