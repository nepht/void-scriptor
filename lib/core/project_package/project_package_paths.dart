import 'dart:io';
import 'package:path/path.dart' as p;
import 'project_package.dart';

final class ProjectPackagePaths {
  static Directory references(ProjectPackage package) =>
      _assets(package, 'references');
  static Directory audio(ProjectPackage package) => _assets(package, 'audio');
  static Directory images(ProjectPackage package) => _assets(package, 'images');
  static Directory video(ProjectPackage package) => _assets(package, 'video');
  static Directory generated(ProjectPackage package) =>
      _assets(package, 'generated');
  static Directory attachments(ProjectPackage package) =>
      _assets(package, 'attachments');
  static Directory thumbnails(ProjectPackage package) =>
      _cache(package, 'thumbnails');
  static Directory waveforms(ProjectPackage package) =>
      _cache(package, 'waveforms');
  static Directory previews(ProjectPackage package) =>
      _cache(package, 'previews');

  static Directory _assets(ProjectPackage package, String child) =>
      Directory(p.join(package.assetsDirectory.path, child));
  static Directory _cache(ProjectPackage package, String child) =>
      Directory(p.join(package.cacheDirectory.path, child));
}
