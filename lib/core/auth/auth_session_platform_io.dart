import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'auth_session_store.dart';
import 'auth_session_store_io.dart';

/// Mirrors `BootstrapDirectories.resolve()`: prefer the application support
/// directory, degrade to the system temp root when the platform channel is
/// unavailable. Defers `path_provider` until called from `main()`.
Future<AuthSessionStore> createDiskAuthSessionStore() async {
  Directory base;
  try {
    base = await getApplicationSupportDirectory();
  } on Object {
    base = Directory(Directory.systemTemp.path);
  }
  return AuthSessionStoreIo.inDirectory(
    Directory(p.join(base.path, 'VoidScriptor', 'state')),
  );
}
