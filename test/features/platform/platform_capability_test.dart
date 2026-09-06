import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/platform/domain/platform_capability.dart';

void main() {
  group('PlatformCapabilitySet', () {
    test('native desktop set declares local persistence honestly', () {
      final caps = resolvePlatformCapabilities(isWeb: false);
      expect(caps.supports(PlatformCapability.localFileSystem), isTrue);
      expect(caps.supports(PlatformCapability.projectSqliteDatabase), isTrue);
      expect(caps.supports(PlatformCapability.readOnlySqlite), isTrue);
    });

    test('web set does not claim project persistence', () {
      final caps = resolvePlatformCapabilities(isWeb: true);
      expect(caps.supports(PlatformCapability.localFileSystem), isFalse);
      expect(caps.supports(PlatformCapability.projectSqliteDatabase), isFalse);
      // Read-only SQLite is explicitly unavailable on web
      // (project_database_platform_web.dart throws UnsupportedError).
      expect(caps.supports(PlatformCapability.readOnlySqlite), isFalse);
    });

    test('require throws an actionable typed error when unsupported', () {
      final caps = resolvePlatformCapabilities(isWeb: true);
      final error = catchUnsupported(
        () => caps.require(
          PlatformCapability.localFileSystem,
          action: 'Membuat proyek baru',
        ),
      );
      expect(error, isA<UnsupportedPlatformCapabilityError>());
      expect(
        error.message,
        contains('Membuat proyek baru'),
        reason: 'error harus menyebut aksi pengguna',
      );
      expect(
        error.message,
        contains('Web'),
        reason: 'error harus menyebut platform',
      );
    });

    test('require passes silently when supported', () {
      final caps = resolvePlatformCapabilities(isWeb: false);
      expect(
        () => caps.require(
          PlatformCapability.localFileSystem,
          action: 'Membuat proyek baru',
        ),
        returnsNormally,
      );
    });
  });
}

UnsupportedPlatformCapabilityError catchUnsupported(void Function() body) {
  try {
    body();
  } on UnsupportedPlatformCapabilityError catch (e) {
    return e;
  }
  fail('expected UnsupportedPlatformCapabilityError');
}
