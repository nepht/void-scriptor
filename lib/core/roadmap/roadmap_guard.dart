import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

class RoadmapGuardResult {
  const RoadmapGuardResult({
    required this.issues,
    required this.warnings,
    required this.canonicalSprint,
    required this.recommendedStep,
    required this.lastResolvedStep,
    required this.canonicalHash,
  });

  final List<String> issues;
  final List<String> warnings;
  final int? canonicalSprint;
  final String? recommendedStep;
  final String? lastResolvedStep;
  final String? canonicalHash;

  bool get ok => issues.isEmpty;
}

abstract final class RoadmapGuard {
  static Future<RoadmapGuardResult> inspect({
    required Directory repository,
    File? policyFile,
  }) async {
    final issues = <String>[];
    final warnings = <String>[];
    final policyPath =
        policyFile ??
        File(_join(repository.path, 'docs/roadmap/ROADMAP_POLICY.json'));
    final policy = await _readObject(policyPath, issues, 'roadmap policy');
    if (policy == null) {
      return RoadmapGuardResult(
        issues: List.unmodifiable(issues),
        warnings: const [],
        canonicalSprint: null,
        recommendedStep: null,
        lastResolvedStep: null,
        canonicalHash: null,
      );
    }

    await _inspectDocumentRegistry(
      repository: repository,
      policy: policy,
      policyFile: policyPath,
      issues: issues,
      warnings: warnings,
    );

    final activeStreamId = policy['active_stream'] as String?;
    final streams = _asObject(policy['streams']);
    final activeStream = activeStreamId == null
        ? null
        : _asObject(streams?[activeStreamId]);
    if (activeStreamId == null || activeStream == null) {
      issues.add('active_stream tidak menunjuk stream policy yang valid.');
      return RoadmapGuardResult(
        issues: List.unmodifiable(issues),
        warnings: const [],
        canonicalSprint: null,
        recommendedStep: null,
        lastResolvedStep: null,
        canonicalHash: null,
      );
    }
    if (activeStream['status'] != 'ACTIVE') {
      issues.add('Stream $activeStreamId bukan ACTIVE.');
    }
    for (final entry in streams!.entries) {
      if (entry.key == activeStreamId) continue;
      final stream = _asObject(entry.value);
      if (stream?['status'] == 'ACTIVE') {
        issues.add('Lebih dari satu mutation stream berstatus ACTIVE.');
      }
    }

    final sprint = activeStream['sprint'] as int?;
    final contractName = activeStream['contract'] as String?;
    final ledgerRelative = activeStream['ledger'] as String?;
    final archiveRoot = policy['canonical_archive_root'] as String?;
    final referenceRoot = policy['hermes_reference_root'] as String?;
    if (sprint == null ||
        contractName == null ||
        ledgerRelative == null ||
        archiveRoot == null ||
        referenceRoot == null) {
      issues.add('Policy active stream belum memiliki lokasi/sprint lengkap.');
      return RoadmapGuardResult(
        issues: List.unmodifiable(issues),
        warnings: const [],
        canonicalSprint: sprint,
        recommendedStep: null,
        lastResolvedStep: null,
        canonicalHash: null,
      );
    }

    final canonicalFile = File(_join(archiveRoot, contractName));
    final referenceFile = File(_join(referenceRoot, contractName));
    final canonical = await _readObject(
      canonicalFile,
      issues,
      'canonical contract',
    );
    String? canonicalHash;
    var contractSteps = <String>[];
    if (canonical != null) {
      canonicalHash = sha256
          .convert(await canonicalFile.readAsBytes())
          .toString();
      final contractSprint = _asObject(canonical['sprint'])?['number'];
      if (contractSprint != sprint) {
        issues.add(
          'Nomor sprint contract $contractSprint tidak cocok dengan policy $sprint.',
        );
      }
      final rawSteps = canonical['steps'];
      if (rawSteps is! List || rawSteps.isEmpty) {
        issues.add('Canonical contract tidak memiliki steps.');
      } else {
        contractSteps = rawSteps
            .map((step) => _asObject(step)?['id'])
            .whereType<String>()
            .toList(growable: false);
        if (contractSteps.length != rawSteps.length ||
            contractSteps.toSet().length != contractSteps.length) {
          issues.add('Canonical step IDs kosong atau duplikat.');
        }
        for (var index = 0; index < contractSteps.length; index++) {
          if (contractSteps[index] != '$sprint.${index + 1}') {
            issues.add(
              'Canonical sequence terputus pada ${contractSteps[index]}; '
              'expected $sprint.${index + 1}.',
            );
            break;
          }
        }
      }
    }

    if (!referenceFile.existsSync()) {
      issues.add('Runtime reference ${referenceFile.path} tidak tersedia.');
    } else if (canonicalFile.existsSync()) {
      final canonicalBytes = await canonicalFile.readAsBytes();
      final referenceBytes = await referenceFile.readAsBytes();
      if (!_sameBytes(canonicalBytes, referenceBytes)) {
        issues.add('Runtime reference tidak byte-identical dengan canonical.');
      }
    }

    final ledger = File(_join(repository.path, ledgerRelative));
    final ledgerStatuses = <String, String>{};
    if (!ledger.existsSync()) {
      issues.add('Active ledger ${ledger.path} tidak tersedia.');
    } else {
      ledgerStatuses.addAll(await _readLedgerStatuses(ledger, sprint));
      if (ledgerStatuses.isEmpty) {
        issues.add('Active ledger tidak memiliki baris Sprint $sprint.');
      }
    }

    String? recommendedStep;
    String? lastResolvedStep;
    for (final step in contractSteps) {
      final status = ledgerStatuses[step] ?? '';
      if (_isResolved(status)) {
        if (recommendedStep == null) lastResolvedStep = step;
      } else {
        recommendedStep ??= step;
      }
    }
    if (recommendedStep == null && contractSteps.isNotEmpty) {
      warnings.add('Seluruh langkah contract sudah resolved menurut ledger.');
    }

    final runtimeRelative =
        policy['runtime_state'] as String? ?? '.hermes/ROADMAP_STATE.json';
    final runtimeFile = File(_join(repository.path, runtimeRelative));
    final runtime = await _readObject(runtimeFile, issues, 'runtime state');
    if (runtime != null) {
      if (runtime['active_sprint'] != sprint) {
        issues.add(
          'Runtime active_sprint ${runtime['active_sprint']} tidak cocok '
          'dengan policy $sprint.',
        );
      }
      if (recommendedStep != null && runtime['next_step'] != recommendedStep) {
        issues.add(
          'Runtime next_step ${runtime['next_step']} tidak cocok dengan '
          'recovery candidate $recommendedStep.',
        );
      }
      if (_normalized(runtime['active_ledger']) !=
          _normalized(ledgerRelative)) {
        issues.add('Runtime active_ledger tidak cocok dengan policy.');
      }
      if (_normalized(runtime['active_sprint_source']) !=
          _normalized(referenceFile.absolute.path)) {
        issues.add(
          'Runtime active_sprint_source tidak cocok dengan reference.',
        );
      }
    }

    return RoadmapGuardResult(
      issues: List.unmodifiable(issues),
      warnings: List.unmodifiable(warnings),
      canonicalSprint: sprint,
      recommendedStep: recommendedStep,
      lastResolvedStep: lastResolvedStep,
      canonicalHash: canonicalHash,
    );
  }

  static Future<RoadmapGuardResult> repair({
    required Directory repository,
    File? policyFile,
  }) async {
    final policyPath =
        policyFile ??
        File(_join(repository.path, 'docs/roadmap/ROADMAP_POLICY.json'));
    final policy =
        jsonDecode(await policyPath.readAsString()) as Map<String, dynamic>;
    final streams = policy['streams'] as Map<String, dynamic>;
    final stream = streams[policy['active_stream']] as Map<String, dynamic>;
    final sprint = stream['sprint'] as int;
    final contractName = stream['contract'] as String;
    final canonicalFile = File(
      _join(policy['canonical_archive_root'] as String, contractName),
    );
    final referenceFile = File(
      _join(policy['hermes_reference_root'] as String, contractName),
    );
    referenceFile.parent.createSync(recursive: true);
    await canonicalFile.copy(referenceFile.path);

    final preflight = await inspect(
      repository: repository,
      policyFile: policyPath,
    );
    final runtimeRelative =
        policy['runtime_state'] as String? ?? '.hermes/ROADMAP_STATE.json';
    final runtimeFile = File(_join(repository.path, runtimeRelative));
    Map<String, dynamic> previous = {};
    if (runtimeFile.existsSync()) {
      try {
        previous =
            jsonDecode(await runtimeFile.readAsString())
                as Map<String, dynamic>;
      } on FormatException {
        previous = {};
      }
    }
    final previousGate = _asObject(previous['stability_gate']);
    final suspended = <String, dynamic>{};
    for (final entry in streams.entries) {
      if (entry.key != policy['active_stream']) {
        suspended[entry.key] = entry.value;
      }
    }
    final nextStep = preflight.recommendedStep;
    final repaired = <String, dynamic>{
      ...previous,
      'schema_version': 2,
      'product': previous['product'] ?? 'Void Scriptor',
      'repository': repository.absolute.path,
      'canonical_archive_root': policy['canonical_archive_root'],
      'hermes_reference_root': policy['hermes_reference_root'],
      'active_stream': policy['active_stream'],
      'active_sprint': sprint,
      'active_sprint_source': referenceFile.absolute.path,
      'active_ledger': stream['ledger'],
      'last_verified_step': preflight.lastResolvedStep,
      'next_step': nextStep,
      'suspended_streams': suspended,
      'stability_gate': {
        'status': 'RECHECK_REQUIRED',
        'resume_step': nextStep,
        'previous_result': previousGate?['full_test_result'],
        'required_checks': [
          'dart run tool/roadmap_guard.dart',
          'flutter analyze',
          'focused Core MVP regression',
          'full flutter test',
          'Windows debug build',
        ],
      },
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'updated_by': 'roadmap_guard repair',
    };
    await _writeObjectAtomically(runtimeFile, repaired);
    return inspect(repository: repository, policyFile: policyPath);
  }

  static Future<RoadmapGuardResult> syncRuntimePointer({
    required Directory repository,
    File? policyFile,
  }) async {
    final policyPath =
        policyFile ??
        File(_join(repository.path, 'docs/roadmap/ROADMAP_POLICY.json'));
    final inspected = await inspect(
      repository: repository,
      policyFile: policyPath,
    );
    if (inspected.ok) return inspected;

    final onlyPointerDrift =
        inspected.issues.isNotEmpty &&
        inspected.issues.every(
          (issue) => issue.startsWith('Runtime next_step '),
        );
    if (!onlyPointerDrift ||
        inspected.canonicalSprint == null ||
        inspected.recommendedStep == null) {
      return inspected;
    }

    final policy =
        jsonDecode(await policyPath.readAsString()) as Map<String, dynamic>;
    final runtimeRelative =
        policy['runtime_state'] as String? ?? '.hermes/ROADMAP_STATE.json';
    final runtimeFile = File(_join(repository.path, runtimeRelative));
    final runtime =
        jsonDecode(await runtimeFile.readAsString()) as Map<String, dynamic>;
    final stabilityGate = _asObject(runtime['stability_gate']);
    if (stabilityGate?['status'] != 'PASS') {
      return RoadmapGuardResult(
        issues: [
          ...inspected.issues,
          'Runtime pointer sync requires stability_gate PASS.',
        ],
        warnings: inspected.warnings,
        canonicalSprint: inspected.canonicalSprint,
        recommendedStep: inspected.recommendedStep,
        lastResolvedStep: inspected.lastResolvedStep,
        canonicalHash: inspected.canonicalHash,
      );
    }

    final activeStreamDetails = _asObject(runtime['active_stream_details']);
    final updated = <String, dynamic>{
      ...runtime,
      'last_verified_step': inspected.lastResolvedStep,
      'next_step': inspected.recommendedStep,
      if (activeStreamDetails != null)
        'active_stream_details': <String, dynamic>{
          ...activeStreamDetails,
          'next_step': inspected.recommendedStep,
        },
      'stability_gate': <String, dynamic>{
        ...stabilityGate!,
        'resume_step': inspected.recommendedStep,
      },
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'updated_by': 'roadmap_guard sync-pointer',
    };
    await _writeObjectAtomically(runtimeFile, updated);
    return inspect(repository: repository, policyFile: policyPath);
  }
}

Future<void> _inspectDocumentRegistry({
  required Directory repository,
  required Map<String, dynamic> policy,
  required File policyFile,
  required List<String> issues,
  required List<String> warnings,
}) async {
  final registryRelative = policy['document_registry'] as String?;
  if (registryRelative == null || registryRelative.trim().isEmpty) {
    issues.add('Policy belum menunjuk document_registry.');
    return;
  }
  if (!_isSafeRelativePath(registryRelative)) {
    issues.add('document_registry harus berupa path repository yang aman.');
    return;
  }

  final registryFile = File(_join(repository.path, registryRelative));
  final registry = await _readObject(registryFile, issues, 'document registry');
  if (registry == null) return;

  if (registry['schema_version'] != 1) {
    issues.add('document registry schema_version belum didukung.');
  }
  final defaults = _asObject(registry['defaults']);
  if (defaults?['unregistered_authority'] != 'NON_BINDING' ||
      defaults?['may_create_scope'] != false) {
    issues.add(
      'Document registry default wajib NON_BINDING dan tidak boleh membuat scope.',
    );
  }

  final rawDocuments = registry['documents'];
  if (rawDocuments is! List || rawDocuments.isEmpty) {
    issues.add('Document registry tidak memiliki documents.');
    return;
  }

  const allowedRoleAuthorities = <String, String>{
    'POLICY': 'BINDING',
    'EXECUTOR_POLICY': 'BINDING',
    'GOVERNANCE_GUIDE': 'ADVISORY',
    'EXECUTION_SUMMARY': 'DERIVED',
    'HISTORICAL_LEDGER': 'DERIVED',
    'EVIDENCE': 'EVIDENCE_ONLY',
    'REFERENCE': 'NON_BINDING',
    'BACKLOG': 'NON_BINDING',
    'GENERATED': 'NON_BINDING',
  };
  const allowedStatuses = {'ACTIVE', 'ARCHIVED'};
  const allowedIntegrity = {'IMMUTABLE', 'MUTABLE'};
  final registeredPaths = <String>{};

  for (final rawDocument in rawDocuments) {
    final document = _asObject(rawDocument);
    if (document == null) {
      issues.add('Document registry berisi entry yang bukan object.');
      continue;
    }
    final path = document['path'] as String?;
    if (path == null || !_isSafeRelativePath(path)) {
      issues.add('Document registry memiliki path tidak aman atau kosong.');
      continue;
    }
    final normalizedPath = _normalized(path);
    if (!registeredPaths.add(normalizedPath)) {
      issues.add('Document registry menduplikasi path $path.');
      continue;
    }

    final role = document['role'] as String?;
    final authority = document['authority'] as String?;
    final requiredAuthority = allowedRoleAuthorities[role];
    if (requiredAuthority == null) {
      issues.add('Role document $path tidak dikenal: ${role ?? '-'}');
    } else if (authority != requiredAuthority) {
      issues.add(
        'Authority document $path harus $requiredAuthority untuk role $role.',
      );
    }
    if (!allowedStatuses.contains(document['status'])) {
      issues.add('Status document $path harus ACTIVE atau ARCHIVED.');
    }
    final integrity = document['integrity'] as String?;
    if (!allowedIntegrity.contains(integrity)) {
      issues.add('Integrity document $path harus IMMUTABLE atau MUTABLE.');
    }
    if (document['may_create_scope'] != false) {
      issues.add('Document tanpa sprint $path tidak boleh membuat scope.');
    }
    if (document['may_mark_implementation_complete'] != false) {
      issues.add(
        'Document tanpa sprint $path tidak boleh sendiri menandai implementasi selesai.',
      );
    }
    final mayChangeRuntimePointer = document['may_change_runtime_pointer'];
    if (mayChangeRuntimePointer is! bool ||
        (mayChangeRuntimePointer && role != 'POLICY')) {
      issues.add(
        'Hak runtime pointer document $path tidak sesuai dengan role $role.',
      );
    }
    final owner = document['owner'];
    if (owner is! String || owner.trim().isEmpty) {
      issues.add('Document $path belum memiliki owner.');
    }
    final linkedSprints = document['linked_sprints'];
    if (linkedSprints is! List || linkedSprints.any((value) => value is! int)) {
      issues.add('Document $path memiliki linked_sprints tidak valid.');
    }

    final file = File(_join(repository.path, path));
    if (!file.existsSync()) {
      issues.add('Document terdaftar tidak tersedia: $path');
      continue;
    }
    if (integrity == 'IMMUTABLE') {
      final expectedHash = document['sha256'] as String?;
      if (expectedHash == null ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(expectedHash)) {
        issues.add('Document immutable $path belum memiliki SHA-256 valid.');
      } else {
        final actualHash = sha256.convert(await file.readAsBytes()).toString();
        if (actualHash != expectedHash) {
          issues.add('Document immutable $path checksum tidak cocok.');
        }
      }
    } else if (document.containsKey('sha256')) {
      warnings.add('Document mutable $path mengabaikan checksum statis.');
    }
  }

  final policyRelative = _repositoryRelative(repository, policyFile);
  if (!registeredPaths.contains(_normalized(policyRelative))) {
    issues.add(
      'ROADMAP_POLICY.json belum terdaftar sebagai document authority.',
    );
  }
  final executorPolicy = policy['executor_policy'] as String?;
  if (executorPolicy != null &&
      !registeredPaths.contains(_normalized(executorPolicy))) {
    issues.add('executor_policy belum terdaftar sebagai document authority.');
  }

  final rawExclusions = registry['discovery_exclusions'];
  final exclusions = rawExclusions is List
      ? rawExclusions.whereType<String>().map(_normalized).toSet()
      : <String>{};
  final rawRoots = registry['strict_authority_roots'];
  if (rawRoots is! List || rawRoots.isEmpty) {
    issues.add('Document registry belum memiliki strict_authority_roots.');
    return;
  }
  for (final rootRelative in rawRoots.whereType<String>()) {
    if (!_isSafeRelativePath(rootRelative)) {
      issues.add('strict_authority_root tidak aman: $rootRelative');
      continue;
    }
    final root = Directory(_join(repository.path, rootRelative));
    if (!root.existsSync()) {
      issues.add('strict_authority_root tidak tersedia: $rootRelative');
      continue;
    }
    for (final entity in root.listSync(recursive: true, followLinks: false)) {
      if (entity is! File || !_isGovernanceDocument(entity.path)) continue;
      final relative = _repositoryRelative(repository, entity);
      final normalizedRelative = _normalized(relative);
      if (exclusions.contains(normalizedRelative) ||
          registeredPaths.contains(normalizedRelative)) {
        continue;
      }
      issues.add(
        'Document authority tidak terdaftar di strict root: $relative',
      );
    }
  }
}

bool _isSafeRelativePath(String value) {
  final normalized = value.replaceAll('\\', '/').trim();
  if (normalized.isEmpty ||
      normalized.startsWith('/') ||
      RegExp(r'^[A-Za-z]:/').hasMatch(normalized)) {
    return false;
  }
  return !normalized.split('/').contains('..');
}

bool _isGovernanceDocument(String path) {
  final normalized = path.toLowerCase();
  return const [
    '.md',
    '.json',
    '.txt',
    '.yaml',
    '.yml',
  ].any(normalized.endsWith);
}

String _repositoryRelative(Directory repository, File file) {
  final root = repository.absolute.path.replaceAll('\\', '/');
  final absolute = file.absolute.path.replaceAll('\\', '/');
  if (absolute.toLowerCase().startsWith('${root.toLowerCase()}/')) {
    return absolute.substring(root.length + 1);
  }
  return absolute;
}

Future<Map<String, dynamic>?> _readObject(
  File file,
  List<String> issues,
  String label,
) async {
  if (!file.existsSync()) {
    issues.add('$label tidak tersedia: ${file.path}');
    return null;
  }
  try {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is Map<String, dynamic>) return decoded;
    issues.add('$label bukan JSON object: ${file.path}');
  } on FormatException catch (error) {
    issues.add('$label JSON invalid: ${error.message}');
  }
  return null;
}

Future<Map<String, String>> _readLedgerStatuses(File ledger, int sprint) async {
  final statuses = <String, String>{};
  for (final line in await ledger.readAsLines()) {
    final cells = line.split('|').map((cell) => cell.trim()).toList();
    if (cells.length < 5 || !cells[1].startsWith('$sprint.')) continue;
    statuses[cells[1]] = cells[3];
  }
  return statuses;
}

bool _isResolved(String status) {
  final normalized = status.toUpperCase();
  return normalized.contains('VERIFIED') || normalized.contains('COMPLETED');
}

Map<String, dynamic>? _asObject(Object? value) =>
    value is Map<String, dynamic> ? value : null;

bool _sameBytes(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

String _normalized(Object? value) =>
    (value?.toString() ?? '').replaceAll('\\', '/').toLowerCase();

String _join(String root, String child) {
  final separator = Platform.pathSeparator;
  return '${root.replaceAll(RegExp(r'[\\/]+$'), '')}$separator'
      '${child.replaceAll(RegExp(r'^[\\/]+'), '').replaceAll(RegExp(r'[\\/]'), separator)}';
}

Future<void> _writeObjectAtomically(
  File target,
  Map<String, dynamic> value,
) async {
  target.parent.createSync(recursive: true);
  final temp = File('${target.path}.roadmap-guard.tmp');
  final backup = File('${target.path}.roadmap-guard.bak');
  await temp.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(value)}\n',
    flush: true,
  );
  if (backup.existsSync()) await backup.delete();
  if (target.existsSync()) await target.rename(backup.path);
  try {
    await temp.rename(target.path);
    if (backup.existsSync()) await backup.delete();
  } catch (_) {
    if (!target.existsSync() && backup.existsSync()) {
      await backup.rename(target.path);
    }
    rethrow;
  } finally {
    if (temp.existsSync()) await temp.delete();
  }
}
