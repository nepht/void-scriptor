import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/features/project_resilience/application/project_recovery_services.dart';

// Invoked in separate Flutter test processes against a shared temporary path.
// The winning process deliberately exits without release (crash residue).
void main() {
  final root = Platform.environment['VOID_LOCK_TEST_ROOT'];
  final result = Platform.environment['VOID_LOCK_TEST_RESULT'];
  test(
    'independent process competes for the shared marker',
    () async {
      final lock = ProjectSessionLock(
        ProjectPackage(projectId: 'process-test', root: Directory(root!)),
      );
      try {
        await lock.acquire();
        await File(result!).writeAsString('OWNED', flush: true);
      } on StateError {
        await File(result!).writeAsString('BLOCKED', flush: true);
      }
    },
    skip: root == null || result == null,
  );
}
