import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/adaptive/void_device_type.dart';
import 'package:void_scriptor/app/adaptive/void_resolver.dart';

void main() {
  group('resolveDeviceType', () {
    test('resolves phone for width < 600', () {
      expect(resolveDeviceType(320), VoidDeviceType.phone);
      expect(resolveDeviceType(599), VoidDeviceType.phone);
    });

    test('resolves tablet for width 600 to 899', () {
      expect(resolveDeviceType(600), VoidDeviceType.tablet);
      expect(resolveDeviceType(899), VoidDeviceType.tablet);
    });

    test('resolves compact desktop for width 900 to 1199', () {
      expect(resolveDeviceType(900), VoidDeviceType.compactDesktop);
      expect(resolveDeviceType(1199), VoidDeviceType.compactDesktop);
    });

    test('resolves desktop for width 1200 to 1919', () {
      // Perbarui rentang untuk desktop
      expect(resolveDeviceType(1200), VoidDeviceType.desktop);
      expect(resolveDeviceType(1919), VoidDeviceType.desktop);
    });

    test('resolves large desktop for width >= 1920', () {
      // Perbarui rentang untuk large desktop
      expect(resolveDeviceType(1920), VoidDeviceType.largeDesktop);
      expect(resolveDeviceType(3840), VoidDeviceType.largeDesktop);
    });
  });
}
