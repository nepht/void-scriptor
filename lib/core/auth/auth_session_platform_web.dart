import 'auth_session_store.dart';

Future<AuthSessionStore> createDiskAuthSessionStore() async =>
    InMemoryAuthSessionStore();
