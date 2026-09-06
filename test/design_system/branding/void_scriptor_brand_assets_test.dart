import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/design_system/widgets/branding/brand_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Void Scriptor brand asset paths are declared and loadable', () async {
    const paths = <String>[
      BrandAssets.voidScriptorEmblem,
      BrandAssets.voidScriptorEmblemPurple,
      BrandAssets.voidScriptorEmblemWhite,
      BrandAssets.voidScriptorInk,
      BrandAssets.voidScriptorIcon16,
      BrandAssets.voidScriptorIcon32,
      BrandAssets.voidScriptorIcon64,
      BrandAssets.voidScriptorIcon128,
      BrandAssets.voidScriptorIcon256,
      BrandAssets.voidScriptorIcon512,
      BrandAssets.voidScriptorLockupDark,
      BrandAssets.voidScriptorLockupLight,
      BrandAssets.webWix,
      BrandAssets.webSquarespace,
      BrandAssets.webWeebly,
    ];

    expect(paths.length, 15);
    for (final path in paths) {
      expect(
        path.startsWith('assets/brands/own_brands/void_scriptor/') ||
            path.startsWith('assets/brands/web_platforms/'),
        isTrue,
      );
      await rootBundle.load(path); // Throws if missing from the bundle.
    }
  });

  test('Void Scriptor SVG traces are bundled and parseable', () async {
    const svgPaths = <String>[
      BrandAssets.voidScriptorSvg,
      BrandAssets.voidScriptorSvgColor,
      BrandAssets.voidScriptorSvgPurple,
      BrandAssets.voidScriptorSvgWhite,
      BrandAssets.voidScriptorSvgInk,
    ];
    for (final path in svgPaths) {
      expect(path, endsWith('.svg'));
      final raw = await rootBundle.loadString(path);
      expect(raw, contains('<svg'));
      expect(raw, contains('<path'));
      expect(raw, contains('viewBox'));
    }
  });
  test('Space Grotesk font is bundled', () async {
    final data = await rootBundle.load(
      'assets/fonts/SpaceGrotesk/SpaceGrotesk-Variable.ttf',
    );
    expect(data.lengthInBytes, greaterThan(100000));
  });
}
