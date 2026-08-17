import 'debug.dart';

/// Sprint 47 — Step 47.89–47.92 Build Config, Asset Cooking, Export.
class GameBuildConfig {
  const GameBuildConfig({
    required this.id,
    required this.projectId,
    required this.target,
    required this.optimizationLevel,
    this.cookAssets = true,
  });

  final String id;
  final String projectId;
  final BuildTarget target;
  final String optimizationLevel;
  final bool cookAssets;
}

class AssetCookResult {
  const AssetCookResult({
    required this.assetId,
    required this.success,
    this.outputHash,
  });

  final String assetId;
  final bool success;
  final String? outputHash;
}

class GameExportPackage {
  const GameExportPackage({
    required this.packageId,
    required this.projectId,
    required this.version,
    required this.createdAt,
    this.fileCount = 0,
    this.totalBytes = 0,
  });

  final String packageId;
  final String projectId;
  final String version;
  final DateTime createdAt;
  final int fileCount;
  final int totalBytes;
}
