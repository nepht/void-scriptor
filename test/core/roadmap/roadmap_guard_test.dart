import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/roadmap/roadmap_guard.dart';

void main() {
  late Directory root;
  late Directory archive;
  late Directory references;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('roadmap-guard-');
    archive = Directory('${root.path}/archive')..createSync();
    references = Directory('${root.path}/references')..createSync();
    Directory('${root.path}/docs/roadmap').createSync(recursive: true);
    Directory('${root.path}/docs/sprints').createSync(recursive: true);
    Directory('${root.path}/.hermes').createSync();

    _writeJson(File('${archive.path}/sprint_145.json'), {
      'sprint': {'number': 145},
      'steps': [
        {'id': '145.1'},
        {'id': '145.2'},
        {'id': '145.3'},
      ],
    });
    File('${root.path}/docs/sprints/sprint-145.md').writeAsStringSync('''
| Step | Title | Status | Evidence |
|---|---|---|---|
| 145.1 | Gate | VERIFIED | evidence |
| 145.2 | Compatibility | PARTIAL | gap |
''');
    _writePolicy(root, archive, references);
    _writeDocumentRegistry(root);
  });

  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  test(
    'accepts matching canonical, runtime, reference, and ledger sources',
    () async {
      File(
        '${archive.path}/sprint_145.json',
      ).copySync('${references.path}/sprint_145.json');
      _writeRuntime(root, references, sprint: 145, nextStep: '145.2');

      final result = await RoadmapGuard.inspect(repository: root);

      expect(result.ok, isTrue);
      expect(result.recommendedStep, '145.2');
      expect(result.canonicalSprint, 145);
      expect(result.canonicalHash, hasLength(64));
    },
  );

  test(
    'rejects drift and derives recovery step from contract plus ledger',
    () async {
      _writeRuntime(root, references, sprint: 111, nextStep: '111.20');
      File('${references.path}/sprint_145.json').writeAsStringSync('drift');

      final result = await RoadmapGuard.inspect(repository: root);

      expect(result.ok, isFalse);
      expect(result.recommendedStep, '145.2');
      expect(result.issues, contains(contains('active_sprint')));
      expect(result.issues, contains(contains('byte-identical')));
    },
  );

  test('repair rebuilds disposable runtime state and reference copy', () async {
    _writeRuntime(root, references, sprint: 111, nextStep: '111.20');

    final repaired = await RoadmapGuard.repair(repository: root);
    final state =
        jsonDecode(
              File(
                '${root.path}/.hermes/ROADMAP_STATE.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;

    expect(repaired.ok, isTrue);
    expect(state['active_sprint'], 145);
    expect(state['next_step'], '145.2');
    expect(state['last_verified_step'], '145.1');
    expect(
      (state['stability_gate'] as Map<String, dynamic>)['status'],
      'RECHECK_REQUIRED',
    );
    expect(
      File('${references.path}/sprint_145.json').readAsBytesSync(),
      File('${archive.path}/sprint_145.json').readAsBytesSync(),
    );
  });

  test(
    'rejects an unregistered document inside a strict authority root',
    () async {
      File(
        '${archive.path}/sprint_145.json',
      ).copySync('${references.path}/sprint_145.json');
      _writeRuntime(root, references, sprint: 145, nextStep: '145.2');
      File(
        '${root.path}/docs/roadmap/rogue-plan.md',
      ).writeAsStringSync('# Unapproved plan\nBuild a new network feature.\n');

      final result = await RoadmapGuard.inspect(repository: root);

      expect(result.ok, isFalse);
      expect(result.issues, contains(contains('tidak terdaftar')));
      expect(result.issues, contains(contains('rogue-plan.md')));
    },
  );

  test('rejects checksum drift in an immutable registered document', () async {
    File(
      '${archive.path}/sprint_145.json',
    ).copySync('${references.path}/sprint_145.json');
    _writeRuntime(root, references, sprint: 145, nextStep: '145.2');
    File('${root.path}/docs/roadmap/ROADMAP_POLICY.json').writeAsStringSync(
      '${File('${root.path}/docs/roadmap/ROADMAP_POLICY.json').readAsStringSync()}\n',
    );

    final result = await RoadmapGuard.inspect(repository: root);

    expect(result.ok, isFalse);
    expect(result.issues, contains(contains('checksum tidak cocok')));
  });

  test('rejects scope creation authority for a non-sprint document', () async {
    File(
      '${archive.path}/sprint_145.json',
    ).copySync('${references.path}/sprint_145.json');
    _writeRuntime(root, references, sprint: 145, nextStep: '145.2');
    final registryFile = File(
      '${root.path}/docs/roadmap/DOCUMENT_REGISTRY.json',
    );
    final registry =
        jsonDecode(registryFile.readAsStringSync()) as Map<String, dynamic>;
    final documents = registry['documents'] as List<dynamic>;
    (documents.first as Map<String, dynamic>)['may_create_scope'] = true;
    _writeJson(registryFile, registry);

    final result = await RoadmapGuard.inspect(repository: root);

    expect(result.ok, isFalse);
    expect(result.issues, contains(contains('tidak boleh membuat scope')));
  });

  test('live ledger resolves 145.14 with user decision evidence', () {
    final repo = Directory.current;
    final ledger = File(
      '${repo.path}/docs/sprints/sprint-145-product-scope-reset-mvp-recovery.md',
    );
    expect(
      ledger.existsSync(),
      isTrue,
      reason: 'Ledger aktif Sprint 145 harus tersedia',
    );
    final cells = ledger
        .readAsLinesSync()
        .map((line) => line.split('|').map((c) => c.trim()).toList())
        .firstWhere(
          (row) => row.length > 3 && row[1] == '145.14',
          orElse: () => <String>[],
        );
    expect(cells, isNotEmpty, reason: 'Baris 145.14 harus ada di ledger');
    expect(
      cells[3],
      contains('VERIFIED'),
      reason:
          '145.14 harus resolved (VERIFIED) di ledger setelah keputusan '
          'primary user direkam, bukan lagi BLOCKED',
    );
    final audit = File('${repo.path}/docs/audits/primary-user-and-job.md');
    expect(
      audit.existsSync(),
      isTrue,
      reason: 'Dokumen audit keputusan primary user harus ada',
    );
    final auditText = audit.readAsStringSync().toLowerCase();
    expect(auditText, contains('primary user'));
    expect(auditText, contains('primary job'));
    expect(auditText, contains('local-first'));
    expect(auditText, contains('pain'));
    expect(auditText, contains('constraint'));
    expect(auditText, contains('success'));
    expect(auditText, contains('backup'));
    expect(auditText, contains('restore'));
  });
}

void _writePolicy(Directory root, Directory archive, Directory references) {
  _writeJson(File('${root.path}/docs/roadmap/ROADMAP_POLICY.json'), {
    'schema_version': 1,
    'canonical_archive_root': archive.path,
    'hermes_reference_root': references.path,
    'document_registry': 'docs/roadmap/DOCUMENT_REGISTRY.json',
    'runtime_state': '.hermes/ROADMAP_STATE.json',
    'active_stream': 'corrective_core_mvp',
    'streams': {
      'corrective_core_mvp': {
        'status': 'ACTIVE',
        'sprint': 145,
        'contract': 'sprint_145.json',
        'ledger': 'docs/sprints/sprint-145.md',
      },
      'sequential_expansion': {'status': 'SUSPENDED', 'sprint': 111},
    },
  });
}

void _writeDocumentRegistry(Directory root) {
  final policy = File('${root.path}/docs/roadmap/ROADMAP_POLICY.json');
  _writeJson(File('${root.path}/docs/roadmap/DOCUMENT_REGISTRY.json'), {
    'schema_version': 1,
    'defaults': {
      'unregistered_authority': 'NON_BINDING',
      'may_create_scope': false,
    },
    'strict_authority_roots': ['docs/roadmap'],
    'discovery_exclusions': ['docs/roadmap/DOCUMENT_REGISTRY.json'],
    'documents': [
      {
        'path': 'docs/roadmap/ROADMAP_POLICY.json',
        'role': 'POLICY',
        'authority': 'BINDING',
        'status': 'ACTIVE',
        'integrity': 'IMMUTABLE',
        'sha256': sha256.convert(policy.readAsBytesSync()).toString(),
        'owner': 'product-governance',
        'linked_sprints': [145, 111],
        'may_create_scope': false,
        'may_mark_implementation_complete': false,
        'may_change_runtime_pointer': true,
      },
    ],
  });
}

void _writeRuntime(
  Directory root,
  Directory references, {
  required int sprint,
  required String nextStep,
}) {
  _writeJson(File('${root.path}/.hermes/ROADMAP_STATE.json'), {
    'active_sprint': sprint,
    'active_sprint_source': '${references.path}/sprint_$sprint.json',
    'active_ledger': 'docs/sprints/sprint-$sprint.md',
    'last_verified_step': '$sprint.1',
    'next_step': nextStep,
    'stability_gate': {'status': 'PASS', 'resume_step': nextStep},
  });
}

void _writeJson(File file, Object value) {
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(value)}\n',
  );
}
