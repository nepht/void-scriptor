import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Windows runner shows native branding only until Flutter first frame',
    () {
      final mainSource = File('windows/runner/main.cpp').readAsStringSync();
      final windowSource = File(
        'windows/runner/flutter_window.cpp',
      ).readAsStringSync();
      final cmakeSource = File(
        'windows/runner/CMakeLists.txt',
      ).readAsStringSync();

      expect(mainSource, contains('CreateNativeBrandWindow'));
      expect(mainSource, contains('L"Void Scriptor Studio"'));
      expect(windowSource, contains('SetNextFrameCallback'));
      expect(windowSource, contains('DestroyNativeBrandWindow'));
      expect(cmakeSource, contains('native_brand_window.cpp'));
      expect('$mainSource$windowSource', isNot(contains('Sleep(')));
    },
  );
}
