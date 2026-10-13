import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/roadmap/roadmap_guard.dart';

/// Gateway stability gate: penerapan atomik RECHECK_REQUIRED -> PASS hanya
/// ketika seluruh evidence cocok dengan HEAD, gate lulus, tidak ada proses
/// Flutter/dart lain, scheduler paused, dan evidence valid (fail-closed).
void main() {
  late Directory root;
  late Directory archive;
  late Directory references;
  late File stateFile;
  late File evidenceFile;
  late File schedulerFile;
  late Directory logDir;

  const requiredChecks = <String>[
    'dart run tool/roadmap_guard.dart',
    'flutter analyze',
    'focused Core MVP regression',
    'full flutter test',
    'Windows debug build',
  ];

  Map<String, dynamic> validEvidence({required String head}) {
    final log = File('${logDir.path}/check.log')
      ..writeAsStringSync('log check PASS');
    final rerunLog = File('${logDir.path}/rerun.log')
      ..writeAsStringSync('rerun konfirmasi PASS');
    final start = DateTime.now().toUtc().subtract(const Duration(minutes: 45));
    final end = DateTime.now().toUtc().subtract(const Duration(minutes: 2));

    Map<String, dynamic> check(String command, File logFile) => {
          'command': command,
          'exit_code': 0,
          'result': 'PASS',
          'started_at': start.toIso8601String(),
          'finished_at': end.toIso8601String(),
          'log_path': logFile.path,
        };

    return {
      'head_sha': head,
      'head_at_check': head,
      'started_at': start.toIso8601String(),
      'completed_at': end.toIso8601String(),
      'checks': {
        'roadmap_guard': check('dart run tool/roadmap_guard.dart', log),
        'analyzer': check('flutter analyze', log),
        'focused_core_regression': check('flutter test test/core', log),
        'full_test': check('flutter test', log),
        'windows_build': check('flutter build windows --debug', log),
        'flaky_retest': {
          ...check('flutter test test/core', rerunLog),
          'zero_flaky_detected': true,
          'reruns': <dynamic>[],
          'quarantined': <dynamic>[],
        },
      },
    };
  }

  void writeState({
    required String status,
    Map<String, dynamic>? evidence,
    List<String>? requiredChecks,
  }) {
    final gate = <String, dynamic>{
      'status': status,
      'resume_step': '119.6',
      'required_checks': requiredChecks ?? const [],
    };
    if (evidence != null) gate['evidence'] = evidence;
    stateFile.writeAsStringSync(jsonEncode({
      'schema_version': 2,
      'active_sprint': 119,
      'updated_at': '2026-10-01T00:00:00.000Z',
      'updated_by': 'fixture',
      'stability_gate': gate,
    }));
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('stability-gateway-');
    archive = Directory('${root.path}/archive')..createSync();
    references = Directory('${root.path}/references')..createSync();
    Directory('${root.path}/docs/roadmap').createSync(recursive: true);
    Directory('${root.path}/docs/sprints').createSync(recursive: true);
    Directory('${root.path}/.hermes').createSync(recursive: true);
    logDir = Directory('${root.path}/cache/stability')
      ..createSync(recursive: true);

    _writeJson(File('${archive.path}/sprint_119.json'), {
      'sprint': {'number': 119},
      'steps': [
        {'id': '119.1'},
        {'id': '119.2'},
      ],
    });
    File('${root.path}/docs/sprints/sprint-119.md').writeAsStringSync('''
| Step | Title | Status | Evidence |
|---|---|---|---|
| 119.1 | Foundation | PARTIAL | gap |
''');
    _writePolicy(root, archive, references);
    _writeDocumentRegistry(root);

    stateFile = File('${root.path}/.hermes/ROADMAP_STATE.json');
    evidenceFile = File('${root.path}/stability-evidence.json');
    schedulerFile = File('${root.path}/jobs.json');
    schedulerFile.writeAsStringSync(
      jsonEncode({
        'jobs': <dynamic>[],
      }),
    );
    writeState(status: 'RECHECK_REQUIRED');
  });

  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  Future<StabilityGatewayResult> runGateway({
    required String head,
    List<String> conflicts = const [],
  }) {
    return RoadmapGuard.applyStabilityGate(
      repository: root,
      evidenceFile: evidenceFile,
      schedulerFile: schedulerFile,
      headReader: () async => head,
      conflictReader: () async => conflicts,
    );
  }

  test('menerapkan PASS atomik saat seluruh evidence cocok dengan HEAD',
      () async {
    final head = 'a'.padRight(40, 'a');
    evidenceFile.writeAsStringSync(jsonEncode(validEvidence(head: head)));
    final before = jsonDecode(stateFile.readAsStringSync())
        as Map<String, dynamic>;

    final result = await runGateway(head: head);

    expect(result.applied, isTrue, reason: result.rejections.join('\n'));
    expect(result.rejections, isEmpty);

    final after =
        jsonDecode(stateFile.readAsStringSync()) as Map<String, dynamic>;
    final gate = after['stability_gate'] as Map<String, dynamic>;
    expect(gate['status'], 'PASS');
    final evidence = gate['evidence'] as Map<String, dynamic>;
    expect(evidence['head_sha'], head);
    expect(evidence['applied_by'], 'stability-gateway');
    expect(evidence['applied_at'], isNotEmpty);

    // Hanya field stability_gate yang boleh berubah.
    final beforeOthers = Map<String, dynamic>.from(before)
      ..remove('stability_gate');
    final afterOthers = Map<String, dynamic>.from(after)..remove('stability_gate');
    expect(afterOthers, beforeOthers,
        reason: 'field di luar stability_gate tidak boleh berubah');
  });

  test('menolak saat HEAD evidence tidak sama dengan HEAD repo', () async {
    final head = 'a'.padRight(40, 'a');
    evidenceFile.writeAsStringSync(jsonEncode(validEvidence(head: head)));
    final before = stateFile.readAsStringSync();

    final result = await runGateway(head: 'b'.padRight(40, 'b'));

    expect(result.applied, isFalse);
    expect(result.rejections.join('\n').toLowerCase(), contains('head'));
    expect(stateFile.readAsStringSync(), before,
        reason: 'tidak boleh menulis saat HEAD berubah');
  });

  test('menolak saat HEAD repo tidak terbaca', () async {
    final head = 'a'.padRight(40, 'a');
    evidenceFile.writeAsStringSync(jsonEncode(validEvidence(head: head)));
    final before = stateFile.readAsStringSync();

    final result = await RoadmapGuard.applyStabilityGate(
      repository: root,
      evidenceFile: evidenceFile,
      schedulerFile: schedulerFile,
      headReader: () async => null,
      conflictReader: () async => <String>[],
    );

    expect(result.applied, isFalse);
    expect(result.rejections, isNotEmpty);
    expect(stateFile.readAsStringSync(), before);
  });

  test('menolak saat salah satu check berexit code bukan 0', () async {
    final head = 'a'.padRight(40, 'a');
    final evidence = validEvidence(head: head);
    final checks = evidence['checks'] as Map<String, dynamic>;
    (checks['full_test'] as Map<String, dynamic>)['exit_code'] = 1;
    evidenceFile.writeAsStringSync(jsonEncode(evidence));
    final before = stateFile.readAsStringSync();

    final result = await runGateway(head: head);

    expect(result.applied, isFalse);
    expect(result.rejections.join('\n'), contains('full_test'));
    expect(stateFile.readAsStringSync(), before);
  });

  test('menolak saat required check hilang dari evidence', () async {
    final head = 'a'.padRight(40, 'a');
    final evidence = validEvidence(head: head);
    (evidence['checks'] as Map<String, dynamic>)
        .remove('focused_core_regression');
    evidenceFile.writeAsStringSync(jsonEncode(evidence));
    final before = stateFile.readAsStringSync();

    final result = await runGateway(head: head);

    expect(result.applied, isFalse);
    expect(result.rejections.join('\n'), contains('focused_core_regression'));
    expect(stateFile.readAsStringSync(), before);
  });

  test('menolak saat artifact log tidak tersedia', () async {
    final head = 'a'.padRight(40, 'a');
    final evidence = validEvidence(head: head);
    evidenceFile.writeAsStringSync(jsonEncode(evidence));
    final checks = evidence['checks'] as Map<String, dynamic>;
    final logPath =
        (checks['analyzer'] as Map<String, dynamic>)['log_path'] as String;
    File(logPath).deleteSync();
    final before = stateFile.readAsStringSync();

    final result = await runGateway(head: head);

    expect(result.applied, isFalse);
    expect(result.rejections.join('\n').toLowerCase(), contains('log'));
    expect(stateFile.readAsStringSync(), before);
  });

  test('menolak saat command check tidak sesuai check-nya', () async {
    final head = 'a'.padRight(40, 'a');
    final evidence = validEvidence(head: head);
    final checks = evidence['checks'] as Map<String, dynamic>;
    (checks['analyzer'] as Map<String, dynamic>)['command'] =
        'echo bukan analyzer';
    evidenceFile.writeAsStringSync(jsonEncode(evidence));
    final before = stateFile.readAsStringSync();

    final result = await runGateway(head: head);

    expect(result.applied, isFalse);
    expect(result.rejections.join('\n'), contains('analyzer'));
    expect(stateFile.readAsStringSync(), before);
  });

  test('menolak saat masih ada proses Flutter/dart lain', () async {
    final head = 'a'.padRight(40, 'a');
    evidenceFile.writeAsStringSync(jsonEncode(validEvidence(head: head)));
    final before = stateFile.readAsStringSync();

    final result = await runGateway(head: head, conflicts: ['dart.exe(4321)']);

    expect(result.applied, isFalse);
    expect(result.rejections.join('\n'), contains('dart.exe'));
    expect(stateFile.readAsStringSync(), before);
  });

  test('menolak saat scheduler belum paused, menerapkan setelah paused',
      () async {
    final head = 'a'.padRight(40, 'a');
    evidenceFile.writeAsStringSync(jsonEncode(validEvidence(head: head)));
    final repoPath = root.absolute.path.replaceAll('\\', '/');
    schedulerFile.writeAsStringSync(jsonEncode({
      'jobs': [
        {
          'id': 'job-1',
          'name': 'Void Scriptor Core Worker',
          'state': 'scheduled',
          'workdir': repoPath,
        },
      ],
    }));
    final before = stateFile.readAsStringSync();

    final rejected = await runGateway(head: head);
    expect(rejected.applied, isFalse);
    expect(rejected.rejections.join('\n'), contains('job-1'));
    expect(stateFile.readAsStringSync(), before);

    schedulerFile.writeAsStringSync(jsonEncode({
      'jobs': [
        {
          'id': 'job-1',
          'name': 'Void Scriptor Core Worker',
          'state': 'paused',
          'workdir': repoPath,
        },
      ],
    }));
    final applied = await runGateway(head: head);
    expect(applied.applied, isTrue, reason: applied.rejections.join('\n'));
  });

  test('menolak saat status sudah PASS (tanpa transisi ganda)', () async {
    final head = 'a'.padRight(40, 'a');
    writeState(status: 'PASS');
    evidenceFile.writeAsStringSync(jsonEncode(validEvidence(head: head)));
    final before = stateFile.readAsStringSync();

    final result = await runGateway(head: head);

    expect(result.applied, isFalse);
    expect(result.rejections.join('\n'), contains('RECHECK_REQUIRED'));
    expect(stateFile.readAsStringSync(), before);
  });

  test('menolak saat flaky dikarantina tanpa aturan tertulis', () async {
    final head = 'a'.padRight(40, 'a');
    final evidence = validEvidence(head: head);
    final checks = evidence['checks'] as Map<String, dynamic>;
    final flaky = checks['flaky_retest'] as Map<String, dynamic>;
    flaky['zero_flaky_detected'] = false;
    flaky['quarantined'] = [
      {
        'test': 'test/core/flaky_test.dart',
        'rule_path': '${logDir.path}/QUARANTINE_RULE_TIDAK_ADA.md',
        'log_path': '${logDir.path}/rerun.log',
      },
    ];
    evidenceFile.writeAsStringSync(jsonEncode(evidence));
    final before = stateFile.readAsStringSync();

    final result = await runGateway(head: head);

    expect(result.applied, isFalse);
    expect(result.rejections.join('\n').toLowerCase(), contains('quarantin'));
    expect(stateFile.readAsStringSync(), before);
  });

  test('menolak required_checks tak dikenal di state (fail-closed)', () async {
    final head = 'a'.padRight(40, 'a');
    writeState(
      status: 'RECHECK_REQUIRED',
      requiredChecks: [...requiredChecks, 'Check Misterius'],
    );
    evidenceFile.writeAsStringSync(jsonEncode(validEvidence(head: head)));
    final before = stateFile.readAsStringSync();

    final result = await runGateway(head: head);

    expect(result.applied, isFalse);
    expect(result.rejections.join('\n'), contains('Misterius'));
    expect(stateFile.readAsStringSync(), before);
  });

  test('repair mempertahankan PASS saat evidence masih cocok dengan HEAD',
      () async {
    await _gitInitCommit(root);
    final head = await _gitRevParse(root);
    expect(head, isNotNull);
    writeState(status: 'PASS', evidence: validEvidence(head: head!));

    final repaired = await RoadmapGuard.repair(repository: root);
    final state = jsonDecode(stateFile.readAsStringSync())
        as Map<String, dynamic>;
    final gate = state['stability_gate'] as Map<String, dynamic>;

    expect(repaired.ok, isTrue);
    expect(gate['status'], 'PASS',
        reason: 'PASS harus dipertahankan saat evidence cocok HEAD');
    expect((gate['evidence'] as Map<String, dynamic>)['head_sha'], head);
  });

  test('repair mengembalikan RECHECK_REQUIRED saat HEAD berubah', () async {
    await _gitInitCommit(root);
    final head = await _gitRevParse(root);
    writeState(status: 'PASS', evidence: validEvidence(head: head!));
    // HEAD bergerak: commit kedua.
    final ledger = File('${root.path}/docs/sprints/sprint-119.md');
    ledger.writeAsStringSync(
      '${ledger.readAsStringSync()}\n| 119.2 | Extra | VERIFIED | evidence |\n',
    );
    await Process.run('git', ['-C', root.path, 'add', '.']);
    await Process.run('git', [
      '-C',
      root.path,
      '-c',
      'user.email=gate@test.local',
      '-c',
      'user.name=gate',
      'commit',
      '-m',
      'head bergerak',
      '--no-gpg-sign',
    ]);
    final movedHead = await _gitRevParse(root);
    expect(movedHead, isNot(head),
        reason: 'fixture: HEAD harus bergerak setelah commit kedua');

    final repaired = await RoadmapGuard.repair(repository: root);
    final state = jsonDecode(stateFile.readAsStringSync())
        as Map<String, dynamic>;
    final gate = state['stability_gate'] as Map<String, dynamic>;

    expect(repaired.ok, isTrue);
    expect(gate['status'], 'RECHECK_REQUIRED',
        reason: 'evidence lama tidak boleh mempertahankan PASS setelah HEAD berubah');
  });

}

Future<void> _gitInitCommit(Directory dir) async {
  await Process.run('git', ['-C', dir.path, 'init']);
  await Process.run('git', ['-C', dir.path, 'add', '.']);
  final commit = await Process.run('git', [
    '-C',
    dir.path,
    '-c',
    'user.email=gate@test.local',
    '-c',
    'user.name=gate',
    'commit',
    '-m',
    'fixture stability gate',
    '--no-gpg-sign',
  ]);
  if (commit.exitCode != 0) {
    fail('git commit fixture gagal: ${commit.stderr}');
  }
}

Future<String?> _gitRevParse(Directory dir) async {
  final result = await Process.run('git', ['-C', dir.path, 'rev-parse', 'HEAD']);
  if (result.exitCode != 0) return null;
  final sha = (result.stdout as String).trim();
  return RegExp(r'^[0-9a-f]{40}$').hasMatch(sha) ? sha : null;
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
        'sprint': 119,
        'contract': 'sprint_119.json',
        'ledger': 'docs/sprints/sprint-119.md',
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
        'sha256': _sha256Of(policy),
        'owner': 'product-governance',
        'linked_sprints': [119, 111],
        'may_create_scope': false,
        'may_mark_implementation_complete': false,
        'may_change_runtime_pointer': true,
      },
    ],
  });
}

String _sha256Of(File file) => sha256.convert(file.readAsBytesSync()).toString();

void _writeJson(File file, Object value) {
  file.parent.createSync(recursive: true);
  file.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(value)}\n');
}
