import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/references/application/reference_file_health_service.dart';
import 'package:void_scriptor/features/references/domain/reference_models.dart';

void main() {
  test(
    'health service distinguishes healthy modified missing and moved',
    () async {
      final root = await Directory.systemTemp.createTemp('s20-health-');
      addTearDown(() => root.delete(recursive: true));
      final file = File('${root.path}/assets/references/face.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes([1, 2, 3]);
      final service = ReferenceFileHealthService(projectDirectory: root);
      final reference = ReferenceModel(
        id: 'face',
        projectId: 'p',
        type: ReferenceType.face,
        source: ReferenceSource.imported,
        name: 'Face',
        filePath: 'assets/references/face.png',
        priority: 0,
        primary: true,
        enabled: true,
        contentHash: await service.hash(file),
      );
      expect(
        (await service.inspect(reference)).health,
        ReferenceHealth.healthy,
      );
      await file.writeAsBytes([9]);
      expect(
        (await service.inspect(reference)).health,
        ReferenceHealth.modified,
      );
      await file.delete();
      expect(
        (await service.inspect(reference)).health,
        ReferenceHealth.missing,
      );
      final moved = File('${root.path}/assets/references/moved/face.png');
      await moved.parent.create(recursive: true);
      await moved.writeAsBytes([1, 2, 3]);
      final result = await service.inspect(reference);
      expect(result.health, ReferenceHealth.moved);
      expect(
        result.relocatedPath?.replaceAll('\\', '/'),
        endsWith('moved/face.png'),
      );
    },
  );
}
