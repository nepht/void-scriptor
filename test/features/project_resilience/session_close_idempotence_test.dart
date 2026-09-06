import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';

void main() {
  test(
    'concurrent and repeated close share a single session shutdown',
    () async {
      final root = await Directory.systemTemp.createTemp('void-close-once-');
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Close once');
      final session = await ProjectSessionManager().open(package);
      try {
        final first = session.close();
        final second = session.close();
        expect(identical(first, second), isTrue);
        await Future.wait([first, second]);
        await session.close();
        expect(await package.sessionFile.exists(), isFalse);
        expect(await package.lockFile.exists(), isFalse);
        final reopened = await ProjectSessionManager().open(package);
        await reopened.close();
      } finally {
        if (await root.exists()) await root.delete(recursive: true);
      }
    },
  );
}
