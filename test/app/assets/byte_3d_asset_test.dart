import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Byte ships as a valid lightweight GLB 2.0 model', () async {
    final file = File('assets/models/byte_mascot_v1.glb');
    expect(await file.exists(), isTrue);

    final bytes = await file.readAsBytes();
    expect(bytes.length, greaterThan(20 * 1024));
    expect(bytes.length, lessThan(5 * 1024 * 1024));
    expect(ascii.decode(bytes.sublist(0, 4)), 'glTF');
    expect(ByteData.sublistView(bytes).getUint32(4, Endian.little), 2);
    expect(
      ByteData.sublistView(bytes).getUint32(8, Endian.little),
      bytes.length,
    );

    final payload = latin1.decode(bytes, allowInvalid: true);
    for (final marker in const [
      'ByteHead',
      'ByteFace',
      'ByteChest',
      'ByteTail',
      'ByteCrystal',
      'ByteRigRoot',
      'ByteCuriousIdle',
    ]) {
      expect(payload, contains(marker));
    }
  });
}
