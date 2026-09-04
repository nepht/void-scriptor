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
    });
  }
}
