import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_storage_analyzer.dart';

void main() {
  test(
    'storage analyzer categorizes files and returns largest files',
    () async {
      final root = await Directory.systemTemp.createTemp('hermes-s24-storage-');
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Storage');
      await File(
        '${package.assetsDirectory.path}/images/large.bin',
      ).writeAsBytes(List.filled(20, 1));
      await File(
        '${package.cacheDirectory.path}/thumb.bin',
      ).writeAsBytes(List.filled(5, 1));

      final report = await ProjectStorageAnalyzer(package).analyze();
      expect(report.totalBytes, greaterThanOrEqualTo(25));
      expect(report.bytesFor(ProjectStorageCategory.image), 20);
      expect(report.bytesFor(ProjectStorageCategory.cache), 5);
      expect(
        report.largestFiles.any(
          (file) => file.relativePath == 'assets/images/large.bin',
        ),
        isTrue,
      );
    },
  );
}
