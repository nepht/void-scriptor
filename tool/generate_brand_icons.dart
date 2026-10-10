import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as image;

const _pngOutputs = <String, int>{
  'assets/brands/own_brands/void_scriptor/void_scriptor_icon_16.png': 16,
  'assets/brands/own_brands/void_scriptor/void_scriptor_icon_32.png': 32,
  'assets/brands/own_brands/void_scriptor/void_scriptor_icon_64.png': 64,
  'assets/brands/own_brands/void_scriptor/void_scriptor_icon_128.png': 128,
  'assets/brands/own_brands/void_scriptor/void_scriptor_icon_256.png': 256,
  'assets/brands/own_brands/void_scriptor/void_scriptor_icon_512.png': 512,
  'web/icons/Icon-192.png': 192,
  'web/icons/Icon-512.png': 512,
  'web/icons/Icon-maskable-192.png': 192,
  'web/icons/Icon-maskable-512.png': 512,
  'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
  'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
  'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
  'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
  'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png': 20,
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png': 40,
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png': 60,
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png': 29,
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png': 58,
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png': 87,
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png': 80,
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png': 120,
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png': 120,
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png': 180,
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png': 76,
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png': 152,
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png':
      167,
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png':
      1024,
  'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png': 16,
  'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png': 32,
  'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png': 64,
  'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png': 128,
  'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png': 256,
  'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png': 512,
  'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png': 1024,
};

const _icoSizes = <int>[16, 24, 32, 48, 64, 128, 256];

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/generate_brand_icons.dart <source.png>',
    );
    exitCode = 64;
    return;
  }

  final sourceFile = File(args.single);
  if (!sourceFile.existsSync()) {
    throw ArgumentError('Source image does not exist: ${sourceFile.path}');
  }
  final sourceBytes = sourceFile.readAsBytesSync();
  final source = image.decodeImage(sourceBytes);
  if (source == null || source.width != source.height) {
    throw FormatException('Source image must be a decodable square PNG');
  }

  final root = Directory.current.path;
  _writeBytes(root, 'assets/logos/void_scriptor_logo.png', sourceBytes);
  for (final entry in _pngOutputs.entries) {
    final resized = image.copyResize(
      source,
      width: entry.value,
      height: entry.value,
    );
    _writeBytes(root, entry.key, image.encodePng(resized));
  }

  final icoFrames = <Uint8List>[
    for (final size in _icoSizes)
      image.encodePng(image.copyResize(source, width: size, height: size)),
  ];
  _writeBytes(
    root,
    'windows/runner/resources/app_icon.ico',
    _encodeIco(icoFrames),
  );
}

void _writeBytes(String root, String relativePath, List<int> bytes) {
  final file = File('$root${Platform.pathSeparator}$relativePath');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes, flush: true);
}

Uint8List _encodeIco(List<Uint8List> frames) {
  final bytes = <int>[];
  _writeUint16(bytes, 0);
  _writeUint16(bytes, 1);
  _writeUint16(bytes, frames.length);

  final headerSize = 6 + 16 * frames.length;
  var offset = headerSize;
  for (var index = 0; index < frames.length; index++) {
    final size = _icoSizes[index];
    bytes.add(size == 256 ? 0 : size);
    bytes.add(size == 256 ? 0 : size);
    bytes.add(0);
    bytes.add(0);
    _writeUint16(bytes, 1);
    _writeUint16(bytes, 32);
    _writeUint32(bytes, frames[index].length);
    _writeUint32(bytes, offset);
    offset += frames[index].length;
  }

  for (final frame in frames) {
    bytes.addAll(frame);
  }
  return Uint8List.fromList(bytes);
}

void _writeUint16(List<int> bytes, int value) {
  bytes
    ..add(value & 0xff)
    ..add((value >> 8) & 0xff);
}

void _writeUint32(List<int> bytes, int value) {
  bytes
    ..add(value & 0xff)
    ..add((value >> 8) & 0xff)
    ..add((value >> 16) & 0xff)
    ..add((value >> 24) & 0xff);
}
