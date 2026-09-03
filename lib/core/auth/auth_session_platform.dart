import 'auth_session_store.dart';

/// Composition-root factory (desktop/mobile): builds the disk-backed store.
/// Selected through conditional import; the stub throws so a missing
/// platform backend surfaces loudly instead of silently not persisting.
Future<AuthSessionStore> createDiskAuthSessionStore() {
  throw UnsupportedError(
    'No disk auth session store backend for this platform',
  );
}
