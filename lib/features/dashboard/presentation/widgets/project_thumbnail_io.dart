import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../../projects/domain/project_model.dart';

Widget buildProjectThumbnail({
  required ProjectModel? project,
  required Widget fallback,
}) {
  final thumbnail = project?.thumbnailPath;
  if (project == null || thumbnail == null || thumbnail.trim().isEmpty) {
    return fallback;
  }

  final file = File(
    path.isAbsolute(thumbnail)
        ? thumbnail
        : path.join(project.localPath, thumbnail),
  );
  return Image.file(
    file,
    fit: BoxFit.cover,
    excludeFromSemantics: true,
    errorBuilder: (_, _, _) => fallback,
  );
}
