import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/domain/project_model.dart';
import 'package:void_scriptor/core/persistence/project_registry_service.dart';

/// Run313 registry incident (145.27 open issue): projects.json was pruned
/// 5->1 with four tombstone ids inside ~2 seconds while a two-instance
/// session was live. The only tombstone writer is `remove()`, yet the UI
/// delete path cannot produce four calls that fast (name-typed confirm),
/// and pure startup reproduction is clean. ROOT CAUSE IS NOT PROVEN — the
/// tree carries no forensic evidence naming the actor.
///
/// This slice instruments the boundary: every durable registry mutation
/// appends one JSONL record to `<registry>.audit.log` carrying an
/// operation, the payload id when applicable, the resulting listing size,
/// a timestamp, and a per-process instance nonce. Two racing instances
/// become distinguishable by their distinct nonces, and a full-listing
/// `save` of stale content (the surviving two-instance hypothesis) becomes
/// attributable. The journal is best-effort forensics: a failed audit
/// write must NEVER break the registry mutation itself.
ProjectModel _model(String id, String name, Directory root) => ProjectModel(
  id: id,
  name: name,
  description: '',
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 2),
  lastOpenedAt: DateTime.utc(2026, 1, 2),
  localPath: root.path,
  version: '0.1.0',
);

void main() {
  late Directory root;
  late File registryFile;
  late File auditFile;
  late ProjectRegistryService service;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('vs-registry-audit-');
    registryFile = File('${root.path}${Platform.pathSeparator}projects.json');
    auditFile = File('${registryFile.path}.audit.log');
    service = ProjectRegistryService(rootDirectory: root);
  });

  tearDown(() async {
    try {
      await root.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  List<Map<String, Object?>> readAudit() {
    if (!auditFile.existsSync()) return const [];
    return auditFile
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .map((line) => (jsonDecode(line) as Map).cast<String, Object?>())
        .toList();
  }

  test(
    'remove() appends an audit record naming the op, the id and the size',
    () async {
      await service.save([
        _model('alpha', 'Alpha', root),
        _model('beta', 'Beta', root),
      ]);
      await service.remove('alpha');

      final records = readAudit();
      final removal = records.lastWhere((record) => record['op'] == 'remove');
      expect(removal['id'], 'alpha');
      expect(removal['after'], 1);
      expect(removal['ts'], isA<String>());
      final instance = removal['instance'];
      expect(
        instance,
        isA<String>(),
        reason:
            'per-process nonce distinguishes '
            'two racing instances',
      );
      expect((instance! as String).isNotEmpty, isTrue);
    },
  );

  test('upsert() and plain save() are both recorded with their ops', () async {
    await service.upsert(_model('gamma', 'Gamma', root));
    await service.save([
      _model('gamma', 'Gamma', root),
      _model('delta', 'Delta', root),
    ]);

    final ops = readAudit().map((record) => record['op']).toList();
    expect(ops.sublist(ops.length - 2), ['upsert', 'save']);
    final upsert = readAudit().lastWhere((record) => record['op'] == 'upsert');
    expect(upsert['id'], 'gamma');
    expect(upsert['after'], 1);
  });

  test('same process reuses one instance nonce across records', () async {
    await service.upsert(_model('a', 'A', root));
    final other = ProjectRegistryService(rootDirectory: root);
    await other.upsert(_model('b', 'B', root));
    final records = readAudit().where((record) => record['op'] == 'upsert');
    expect(
      records.map((record) => record['instance']).toSet().length,
      1,
      reason: 'the nonce is per-process, not per-service',
    );
  });

  test('audit journal is capped and keeps the most recent records', () async {
    // Seed the journal past the cap directly (one real mutation instead of
    // 500 full write cycles, which only exercises the same trim branch):
    // line i carries id 'seed-i'.
    final seed = List.generate(
      ProjectRegistryService.auditMaxLines + 5,
      (index) => jsonEncode({'op': 'seed', 'id': 'seed-$index', 'after': 0}),
    );
    auditFile.writeAsStringSync('${seed.join('\n')}\n', flush: true);
    await service.save([_model('after-cap', 'AfterCap', root)]);

    final lines = auditFile
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .toList();
    expect(lines.length, ProjectRegistryService.auditMaxLines);
    final records = lines.map(
      (line) => (jsonDecode(line) as Map).cast<String, Object?>(),
    );
    expect(
      records.first['id'],
      'seed-6',
      reason:
          'oldest records are dropped first (append made 506 lines, '
          'the newest 500 survive)',
    );
    expect(
      records.last['id'],
      isNot(startsWith('seed')),
      reason: 'the newest real mutation is retained',
    );
    expect(records.last['op'], 'save');
  });

  test('a failing audit write never breaks the registry mutation', () async {
    // Make the audit path unusable: a DIRECTORY where the journal appends.
    Directory(auditFile.path).createSync(recursive: true);
    await service.upsert(_model('keep', 'Keep', root));
    expect(registryFile.existsSync(), isTrue);
    expect((await service.load()).map((p) => p.id), contains('keep'));
  });
}
