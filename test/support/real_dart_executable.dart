import 'dart:io';

/// Resolves the standalone Dart VM while running under either `dart test` or
/// `flutter test`.
///
/// `Platform.resolvedExecutable` points at `flutter_tester.exe` in a Flutter
/// test process, and `FLUTTER_ROOT` is not guaranteed to be exported. Walking
/// up from the engine executable keeps process-based tests independent from
/// shell configuration while still validating that the candidate exists.
Future<String> resolveRealDartExecutable() async {
  final executableName = Platform.isWindows ? 'dart.exe' : 'dart';
  final resolved = File(Platform.resolvedExecutable);
  if (_basename(resolved.path).toLowerCase() == executableName) {
    return resolved.path;
  }

  final candidates = <String>[];
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null && flutterRoot.trim().isNotEmpty) {
    candidates.add(
      _join(<String>[
        flutterRoot,
        'bin',
        'cache',
        'dart-sdk',
        'bin',
        executableName,
      ]),
    );
  }

  var directory = resolved.parent;
  for (var depth = 0; depth < 10; depth++) {
    candidates
      ..add(_join(<String>[directory.path, 'dart-sdk', 'bin', executableName]))
      ..add(
        _join(<String>[
          directory.path,
          'bin',
          'cache',
          'dart-sdk',
          'bin',
          executableName,
        ]),
      );
    final parent = directory.parent;
    if (parent.path == directory.path) break;
    directory = parent;
  }

  for (final candidate in candidates) {
    if (await File(candidate).exists()) return candidate;
  }
  throw StateError(
    'Unable to locate a standalone Dart VM from '
    '${Platform.resolvedExecutable}. Checked: ${candidates.join(', ')}',
  );
}

String _basename(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.substring(normalized.lastIndexOf('/') + 1).toLowerCase();
}

String _join(List<String> segments) => segments
    .map((segment) => segment.replaceAll(RegExp(r'[\\/]+$'), ''))
    .join(Platform.pathSeparator);
