import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'auth_session.dart';
import 'auth_session_store.dart';

/// File-backed [AuthSessionStore] with atomic writes
/// (`session.json.tmp` → rename) so a crash mid-write never leaves a torn
/// session file behind.
class AuthSessionStoreIo implements AuthSessionStore {
  AuthSessionStoreIo({required this.file});

  AuthSessionStoreIo.inDirectory(Directory directory)
    : this(file: File(p.join(directory.path, 'session.json')));

  final File file;

  File get _tempFile => File('${file.path}.tmp');

  @override
  Future<void> save(AuthSession session) async {
    final temp = _tempFile;
    await temp.parent.create(recursive: true);
    await temp.writeAsString(jsonEncode(session.toJson()), flush: true);
    await temp.rename(file.path);
  }

  @override
  Future<AuthSession?> load() async {
    if (!file.existsSync()) return null;
    try {
      final contents = await file.readAsString();
      final map = jsonDecode(contents) as Map<String, dynamic>;
      return AuthSessionJson.fromMap(map);
    } on FormatException {
      return null;
    } on FileSystemException {
      return null;
    }
  }

  @override
  Future<void> clear() async {
    if (file.existsSync()) {
      await file.delete();
    }
  }
}
