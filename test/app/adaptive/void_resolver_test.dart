// Test untuk VoidDeviceType resolver.
// Kontrak breakpoint resmi: <600 phone, 600-1023 tablet, 1024-1439 compactDesktop, >=1440 desktop.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/adaptive/void_resolver.dart';
import 'package:void_scriptor/app/adaptive/void_device_type.dart';
import 'package:void_scriptor/app/adaptive/void_breakpoints.dart';

void main() {
  group('resolveDeviceType', () {
    test('returns phone for width < 600', () {
      expect(resolveDeviceType(599.9), VoidDeviceType.phone);
    });

    test('returns tablet for width 600', () {
      expect(resolveDeviceType(VoidBreakpoints.phone), VoidDeviceType.tablet);
    });

    test('returns tablet for width < 1024 (boundary 1023.9)', () {
      expect(resolveDeviceType(1023.9), VoidDeviceType.tablet);
    });

    test('returns compactDesktop for width 1024', () {
      expect(
        resolveDeviceType(VoidBreakpoints.tablet),
        VoidDeviceType.compactDesktop,
      );
    });

    test('returns compactDesktop for width < 1440 (boundary 1439.9)', () {
      expect(resolveDeviceType(1439.9), VoidDeviceType.compactDesktop);
    });

    test('returns desktop for width 1440', () {
      expect(
        resolveDeviceType(VoidBreakpoints.desktop),
        VoidDeviceType.desktop,
      );
    });

    test('returns desktop for width > 1440 (e.g. 1920)', () {
      expect(resolveDeviceType(1920), VoidDeviceType.desktop);
    });
  });
}
