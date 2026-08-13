import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class CredentialStore {
  Future<void> write({required String key, required String value});
  Future<String?> read(String key);
  Future<void> delete(String key);
}

class SecureCredentialStore implements CredentialStore {
  const SecureCredentialStore(this.storage);
  final FlutterSecureStorage storage;
  @override
  Future<void> write({required String key, required String value}) =>
      storage.write(key: key, value: value);
  @override
  Future<String?> read(String key) => storage.read(key: key);
  @override
  Future<void> delete(String key) => storage.delete(key: key);
}

class MemoryCredentialStore implements CredentialStore {
  final Map<String, String> _values = {};
  @override
  Future<void> write({required String key, required String value}) async =>
      _values[key] = value;
  @override
  Future<String?> read(String key) async => _values[key];
  @override
  Future<void> delete(String key) async => _values.remove(key);
}
