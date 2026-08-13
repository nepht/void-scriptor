import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../domain/reference_models.dart';

class ReferenceHealthResult {
  const ReferenceHealthResult({required this.health, this.relocatedPath});
  final ReferenceHealth health;
  final String? relocatedPath;
}

class ReferenceFileHealthService {
  const ReferenceFileHealthService({required this.projectDirectory});
  final Directory projectDirectory;

  Future<String> hash(File file) async =>
      sha256.convert(await file.readAsBytes()).toString();

  Future<ReferenceHealthResult> inspect(ReferenceModel reference) async {
    if (reference.filePath.trim().isEmpty) {
      return const ReferenceHealthResult(health: ReferenceHealth.incomplete);
    }
    final file = File(
      p.isAbsolute(reference.filePath)
          ? reference.filePath
          : p.join(projectDirectory.path, reference.filePath),
    );
    if (await file.exists()) {
      if (reference.contentHash == null || reference.contentHash!.isEmpty) {
        return const ReferenceHealthResult(health: ReferenceHealth.incomplete);
      }
      return ReferenceHealthResult(
        health: await hash(file) == reference.contentHash
            ? ReferenceHealth.healthy
            : ReferenceHealth.modified,
      );
    }
    final expectedHash = reference.contentHash;
    if (expectedHash != null &&
        expectedHash.isNotEmpty &&
        await projectDirectory.exists()) {
      await for (final entity in projectDirectory.list(recursive: true)) {
        if (entity is! File ||
            p.basename(entity.path) != p.basename(file.path)) {
          continue;
        }
        try {
          if (await hash(entity) == expectedHash) {
            return ReferenceHealthResult(
              health: ReferenceHealth.moved,
              relocatedPath: p.relative(
                entity.path,
                from: projectDirectory.path,
              ),
            );
          }
        } on FileSystemException {
          continue;
        }
      }
    }
    return const ReferenceHealthResult(health: ReferenceHealth.missing);
  }
}
