import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/platform/platform_capabilities.dart';

void main() {
  test('desktop menyediakan full studio', () {
    final capabilities = PlatformCapabilities.forTarget(AppTarget.windows);

    expect(capabilities.studioMode, StudioMode.full);
    expect(capabilities.supportsPersistentInspector, isTrue);
    expect(capabilities.supportsDesktopPlugins, isTrue);
  });

  test('mobile menyediakan adaptive studio tanpa desktop plugins', () {
    final capabilities = PlatformCapabilities.forTarget(AppTarget.android);

    expect(capabilities.studioMode, StudioMode.adaptive);
    expect(capabilities.supportsPersistentInspector, isFalse);
    expect(capabilities.supportsDesktopPlugins, isFalse);
  });

  test('web memakai adaptive studio dengan capability terbatas', () {
    final capabilities = PlatformCapabilities.forTarget(AppTarget.web);

    expect(capabilities.studioMode, StudioMode.adaptive);
    expect(capabilities.supportsLocalFileSystem, isFalse);
    expect(capabilities.supportsDesktopPlugins, isFalse);
  });
}
