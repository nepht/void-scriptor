import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

void main() {
  const paths = <String>[
    'assets/logos/void_scriptor_logo.png',
    'assets/backgrounds/auth_background.png',
    'assets/brands/tech/flutter_0.webp',
  ];

  for (final path in paths) {
    test('$path is a decodable image asset', () {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: 'Missing asset: $path');

      final decoded = image.decodeImage(file.readAsBytesSync());
      expect(decoded, isNotNull, reason: 'Undecodable asset: $path');
      expect(decoded!.width, greaterThan(0));
      expect(decoded.height, greaterThan(0));
      if (path == 'assets/logos/void_scriptor_logo.png') {
        expect(decoded.width, greaterThanOrEqualTo(1024));
        expect(decoded.height, decoded.width);
      }
    });
  }

  test('platform launcher icons are generated square PNGs', () {
    const platformIcons = <String, int>{
      'web/icons/Icon-512.png': 512,
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png':
          1024,
      'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png': 1024,
    };

    for (final entry in platformIcons.entries) {
      final file = File(entry.key);
      expect(file.existsSync(), isTrue, reason: 'Missing icon: ${entry.key}');
      final decoded = image.decodeImage(file.readAsBytesSync());
      expect(decoded, isNotNull, reason: 'Undecodable icon: ${entry.key}');
      expect(decoded!.width, entry.value);
      expect(decoded.height, entry.value);
    }
  });

  test('Windows launcher icon is a multi-image ICO', () {
    final bytes = File(
      'windows/runner/resources/app_icon.ico',
    ).readAsBytesSync();
    expect(bytes.length, greaterThan(6));
    expect(bytes.sublist(0, 4), orderedEquals(const [0, 0, 1, 0]));
    final imageCount = bytes[4] | (bytes[5] << 8);
    expect(imageCount, greaterThanOrEqualTo(4));
  });
}
