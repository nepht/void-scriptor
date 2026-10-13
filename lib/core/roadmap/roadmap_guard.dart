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

/// Hasil gateway stability gate (fail-closed).
///
/// [applied] hanya true ketika SEMUA prasyarat terverifikasi dan tulis atomik
/// RECHECK_REQUIRED -> PASS berhasil. Selain itu [rejections] memuat alasan
/// verifikasi dan state TIDAK disentuh sama sekali.
class StabilityGatewayResult {
  StabilityGatewayResult({required this.applied, required this.rejections});

  final bool applied;
  final List<String> rejections;
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
    final continuityUntilSprint = activeStream['continuity_until_sprint'];
    if (continuityUntilSprint is int && continuityUntilSprint > sprint) {
      await _inspectCanonicalContinuity(
        archiveRoot: archiveRoot,
        activeSprint: sprint,
        untilSprint: continuityUntilSprint,
        issues: issues,
      );
    }
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
      if (runtime.containsKey('next_step') &&
          runtime['next_step'] != recommendedStep) {
        issues.add(
          'Runtime next_step ${runtime['next_step']} tidak cocok dengan '
          'recovery candidate $recommendedStep.',
        );
      }
      final expectedCurrentStep = recommendedStep ?? lastResolvedStep;
      if (expectedCurrentStep != null &&
          runtime.containsKey('current_step') &&
          runtime['current_step'] != expectedCurrentStep) {
        issues.add(
          'Runtime current_step ${runtime['current_step']} tidak cocok dengan '
          'canonical progress $expectedCurrentStep.',
        );
      }
      if (lastResolvedStep != null &&
          runtime.containsKey('last_resolved_step') &&
          runtime['last_resolved_step'] != lastResolvedStep) {
        issues.add(
          'Runtime last_resolved_step ${runtime['last_resolved_step']} tidak '
          'cocok dengan canonical progress $lastResolvedStep.',
        );
      }
      if (lastResolvedStep != null &&
          runtime.containsKey('last_verified_step') &&
          runtime['last_verified_step'] != lastResolvedStep) {
        issues.add(
          'Runtime last_verified_step ${runtime['last_verified_step']} tidak '
          'cocok dengan canonical progress $lastResolvedStep.',
        );
      }
      if (recommendedStep == null &&
          runtime.containsKey('current_step_status') &&
          runtime['current_step_status'] !=
              'SPRINT_COMPLETE_PENDING_OPERATOR_DECISION') {
        issues.add(
          'Runtime current_step_status ${runtime['current_step_status']} tidak '
          'menandai sprint selesai menunggu keputusan operator.',
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
    final lastResolvedStep = preflight.lastResolvedStep;
    final currentStep = nextStep ?? lastResolvedStep;
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
      'last_verified_step': lastResolvedStep,
      if (previous.containsKey('current_step') && currentStep != null)
        'current_step': currentStep,
      if (previous.containsKey('last_resolved_step'))
        'last_resolved_step': lastResolvedStep,
      if (previous.containsKey('current_step_status') && nextStep == null)
        'current_step_status': 'SPRINT_COMPLETE_PENDING_OPERATOR_DECISION',
      'next_step': nextStep,
      'suspended_streams': suspended,
      'stability_gate': await _stabilityGateForRepair(
        previousGate: previousGate,
        repository: repository,
        resumeStep: nextStep,
      ),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'updated_by': 'roadmap_guard repair',
    };
    await _writeObjectAtomically(runtimeFile, repaired);
    return inspect(repository: repository, policyFile: policyPath);
  }

  /// Id evidence wajib untuk stability gate (fail-closed: semua wajib ada).
  static const List<String> stabilityEvidenceCheckIds = [
    'roadmap_guard',
    'analyzer',
    'focused_core_regression',
    'full_test',
    'windows_build',
    'flaky_retest',
  ];

  /// Pemetaan nama required_check (di state) ke id evidence.
  static const Map<String, String> stabilityEvidenceIds = {
    'dart run tool/roadmap_guard.dart': 'roadmap_guard',
    'flutter analyze': 'analyzer',
    'focused Core MVP regression': 'focused_core_regression',
    'full flutter test': 'full_test',
    'Windows debug build': 'windows_build',
  };

  /// Token wajib di command lengkap setiap check evidence.
  static const Map<String, String> stabilityEvidenceCommandTokens = {
    'roadmap_guard': 'roadmap_guard',
    'analyzer': 'flutter analyze',
    'focused_core_regression': 'flutter test',
    'full_test': 'flutter test',
    'windows_build': 'flutter build windows',
    'flaky_retest': 'flutter test',
  };

  /// Gateway terbatas: satu-satunya jalur flip RECHECK_REQUIRED -> PASS.
  ///
  /// Fail-closed: evidence tidak valid, HEAD berubah/berbeda, masih ada
  /// proses Flutter/build/state-writer lain, scheduler tidak paused, atau
  /// required_checks tak dikenal -> REJECTED tanpa menyentuh state.
  static Future<StabilityGatewayResult> applyStabilityGate({
    required Directory repository,
    required File evidenceFile,
    File? policyFile,
    File? schedulerFile,
    Future<String?> Function()? headReader,
    Future<List<String>> Function()? conflictReader,
  }) async {
    final rejections = <String>[];

    Map<String, dynamic>? evidence;
    if (!evidenceFile.existsSync()) {
      rejections.add('evidence tidak ditemukan: ${evidenceFile.path}');
    } else {
      try {
        final decoded = jsonDecode(await evidenceFile.readAsString());
        if (decoded is Map<String, dynamic>) {
          evidence = decoded;
        }
      } catch (_) {
        evidence = null;
      }
      if (evidence == null) {
        rejections.add('evidence bukan JSON object valid: ${evidenceFile.path}');
      }
    }

    File stateFile;
    Map<String, dynamic> state;
    try {
      final policy = policyFile ??
          File(_join(repository.path, 'docs/roadmap/ROADMAP_POLICY.json'));
      if (!policy.existsSync()) {
        throw StateError('ROADMAP_POLICY.json tidak ada');
      }
      final decodedPolicy = jsonDecode(await policy.readAsString());
      final runtimeState = decodedPolicy is Map<String, dynamic>
          ? (decodedPolicy['runtime_state'] ?? '.hermes/ROADMAP_STATE.json')
          : '.hermes/ROADMAP_STATE.json';
      final isAbsolute = runtimeState is String &&
          (runtimeState.startsWith('/') ||
              RegExp(r'^[A-Za-z]:').hasMatch(runtimeState));
      final runtimePath = isAbsolute
          ? runtimeState
          : _join(repository.path,
              runtimeState is String ? runtimeState : '.hermes/ROADMAP_STATE.json');
      stateFile = File(runtimePath);
      if (!stateFile.existsSync()) {
        throw StateError('runtime state tidak ada: $runtimePath');
      }
      final decodedState = jsonDecode(await stateFile.readAsString());
      if (decodedState is! Map<String, dynamic>) {
        throw StateError('runtime state bukan JSON object');
      }
      state = decodedState;
    } catch (error) {
      rejections.add('runtime state tidak terbaca: $error');
      return StabilityGatewayResult(applied: false, rejections: rejections);
    }

    final head = await (headReader ?? () => _gitHead(repository))();
    if (head == null) {
      rejections.add('HEAD repo tidak terbaca (git rev-parse HEAD gagal)');
    }
    if (evidence != null) {
      rejections.addAll(validateStabilityEvidence(
        evidence: evidence,
        currentHead: head,
        requireLogArtifacts: true,
      ));
    }

    final gate = state['stability_gate'];
    final gateMap = gate is Map<String, dynamic> ? gate : null;
    if (gateMap == null) {
      rejections.add('stability_gate tidak ada di runtime state');
    } else if (gateMap['status'] != 'RECHECK_REQUIRED') {
      rejections.add(
        'stability_gate.status="${gateMap['status']}" - hanya RECHECK_REQUIRED -> PASS yang diizinkan',
      );
    } else if (evidence != null) {
      final required = gateMap['required_checks'];
      if (required is List) {
        for (final raw in required) {
          if (raw is! String) {
            rejections.add('required_check tidak valid: $raw');
            continue;
          }
          final id = stabilityEvidenceIds[raw];
          if (id == null) {
            rejections.add('required_check tak dikenal (fail-closed): $raw');
            continue;
          }
          final checks = evidence['checks'];
          if (checks is! Map<String, dynamic> || !checks.containsKey(id)) {
            rejections.add('evidence tidak memuat required check: $id');
          }
        }
      }
    }

    final conflicts = await (conflictReader ?? _liveConflictingProcesses)();
    for (final conflict in conflicts) {
      rejections.add(
        'proses Flutter/build/state-writer lain terdeteksi: $conflict',
      );
    }

    final resolvedScheduler = schedulerFile ?? _defaultSchedulerFile();
    rejections.addAll(_schedulerViolations(
      jobsFile: resolvedScheduler,
      repository: repository,
    ));

    if (rejections.isNotEmpty) {
      return StabilityGatewayResult(applied: false, rejections: rejections);
    }

    final newGate = <String, dynamic>{
      ...gateMap!,
      'status': 'PASS',
      'evidence': <String, dynamic>{
        ...evidence!,
        'applied_at': DateTime.now().toUtc().toIso8601String(),
        'applied_by': 'stability-gateway',
        'verified_head': head!,
      },
    };
    state['stability_gate'] = newGate;
    await _writeObjectAtomically(stateFile, state);
    return StabilityGatewayResult(applied: true, rejections: const []);
  }

  /// Validasi evidence stability gate (fail-closed: kumpulkan semua masalah).
  static List<String> validateStabilityEvidence({
    required Object? evidence,
    required String? currentHead,
    required bool requireLogArtifacts,
  }) {
    final problems = <String>[];
    if (evidence is! Map<String, dynamic>) {
      return ['evidence tidak ada atau bukan JSON object'];
    }

    final headSha = evidence['head_sha'];
    if (headSha is! String || !RegExp(r'^[0-9a-f]{40}$').hasMatch(headSha)) {
      problems.add('evidence.head_sha bukan SHA-40 hex: $headSha');
    } else if (currentHead == null) {
      problems.add('HEAD repo tidak terbaca - evidence tidak bisa diverifikasi');
    } else if (headSha != currentHead) {
      problems.add(
        'evidence.head_sha ($headSha) tidak sama dengan HEAD repo ($currentHead)',
      );
    }
    if (evidence['head_at_check'] != headSha) {
      problems.add(
        'evidence.head_at_check tidak sama dengan head_sha (HEAD berubah saat pemeriksaan)',
      );
    }

    final started = _parseTimestamp(evidence['started_at']);
    final completed = _parseTimestamp(evidence['completed_at']);
    if (started == null) problems.add('evidence.started_at tidak valid');
    if (completed == null) problems.add('evidence.completed_at tidak valid');
    if (started != null && completed != null && completed.isBefore(started)) {
      problems.add('evidence.completed_at sebelum started_at');
    }
    if (completed != null &&
        completed.isAfter(DateTime.now().toUtc().add(const Duration(minutes: 2)))) {
      problems.add('evidence.completed_at di masa depan');
    }

    final checks = evidence['checks'];
    if (checks is! Map<String, dynamic>) {
      problems.add('evidence.checks tidak ada');
      return problems;
    }

    for (final id in stabilityEvidenceCheckIds) {
      final raw = checks[id];
      if (raw is! Map<String, dynamic>) {
        problems.add('check wajib hilang atau tidak valid: $id');
        continue;
      }
      final command = raw['command'];
      if (command is! String || command.trim().isEmpty) {
        problems.add('command kosong: $id');
      } else {
        final token = stabilityEvidenceCommandTokens[id]!;
        if (!command.toLowerCase().contains(token)) {
          problems.add(
            'command "$command" tidak sesuai check $id (harus mengandung "$token")',
          );
        }
      }
      if (raw['exit_code'] != 0) {
        problems.add('exit_code ${raw['exit_code']} != 0: $id');
      }
      if (raw['result'] != 'PASS') {
        problems.add('result "${raw['result']}" != PASS: $id');
      }
      final checkStarted = _parseTimestamp(raw['started_at']);
      final checkFinished = _parseTimestamp(raw['finished_at']);
      if (checkStarted == null || checkFinished == null) {
        problems.add('timestamp check tidak valid: $id');
      } else if (checkFinished.isBefore(checkStarted)) {
        problems.add('finished_at sebelum started_at: $id');
      }
      final logPath = raw['log_path'];
      if (logPath is! String || logPath.trim().isEmpty) {
        problems.add('log_path tidak ada: $id');
      } else if (requireLogArtifacts && !_logArtifactUsable(logPath)) {
        problems.add('artifact log tidak tersedia/kosong: $id ($logPath)');
      }
    }

    final flaky = checks['flaky_retest'];
    if (flaky is Map<String, dynamic>) {
      final zero = flaky['zero_flaky_detected'];
      if (zero is! bool) {
        problems.add('flaky_retest.zero_flaky_detected wajib boolean');
      } else if (!zero) {
        final rerunsOk = _flakyRerunsValid(
          flaky['reruns'],
          problems,
          requireLogArtifacts,
        );
        final quarantinedOk = _flakyQuarantineValid(
          flaky['quarantined'],
          problems,
          requireLogArtifacts,
        );
        if (!rerunsOk && !quarantinedOk) {
          problems.add(
            'flaky_retest: tanpa zero_flaky_detected wajib ada rerun lulus ATAU quarantine dengan rule tertulis',
          );
        }
      }
    }

    return problems;
  }

  /// Reparasi stability gate: pertahankan PASS hanya jika evidence masih
  /// cocok dengan HEAD; selain itu kembalikan RECHECK_REQUIRED (fail-closed).
  static Future<Map<String, dynamic>> _stabilityGateForRepair({
    required Map<String, dynamic>? previousGate,
    required Directory repository,
    required Object? resumeStep,
  }) async {
    if (previousGate != null && previousGate['status'] == 'PASS') {
      final head = await _gitHead(repository);
      final problems = validateStabilityEvidence(
        evidence: previousGate['evidence'],
        currentHead: head,
        requireLogArtifacts: true,
      );
      if (problems.isEmpty) {
        return Map<String, dynamic>.from(previousGate);
      }
    }
    return {
      'status': 'RECHECK_REQUIRED',
      'resume_step': resumeStep,
      'previous_result': previousGate?['full_test_result'],
      'required_checks': [
        'dart run tool/roadmap_guard.dart',
        'flutter analyze',
        'focused Core MVP regression',
        'full flutter test',
        'Windows debug build',
      ],
    };
  }

  static bool _flakyRerunsValid(
    Object? reruns,
    List<String> problems,
    bool requireLogArtifacts,
  ) {
    if (reruns is! List || reruns.isEmpty) return false;
    var ok = true;
    for (final raw in reruns) {
      if (raw is! Map<String, dynamic>) {
        problems.add('flaky rerun entry tidak valid');
        ok = false;
        continue;
      }
      final testName = raw['test'];
      final runs = raw['runs'];
      if (testName is! String || testName.isEmpty) {
        problems.add('flaky rerun tanpa nama test');
        ok = false;
      }
      if (runs is! int || runs < 1) {
        problems.add('flaky rerun runs < 1: $testName');
        ok = false;
      }
      if (raw['exit_code'] != 0) {
        problems.add('flaky rerun exit_code != 0: $testName');
        ok = false;
      }
      final logPath = raw['log_path'];
      if (logPath is! String ||
          (requireLogArtifacts && !_logArtifactUsable(logPath))) {
        problems.add('flaky rerun log tidak tersedia: $testName');
        ok = false;
      }
    }
    return ok;
  }

  static bool _flakyQuarantineValid(
    Object? entries,
    List<String> problems,
    bool requireLogArtifacts,
  ) {
    if (entries is! List || entries.isEmpty) return false;
    var ok = true;
    for (final raw in entries) {
      if (raw is! Map<String, dynamic>) {
        problems.add('quarantine entry tidak valid');
        ok = false;
        continue;
      }
      final testName = raw['test'];
      if (testName is! String || testName.isEmpty) {
        problems.add('quarantine tanpa nama test');
        ok = false;
      }
      final rulePath = raw['rule_path'];
      if (rulePath is! String ||
          (requireLogArtifacts && !_logArtifactUsable(rulePath))) {
        problems.add('quarantine rule tidak tersedia (aturan tertulis wajib): $rulePath');
        ok = false;
      }
      final logPath = raw['log_path'];
      if (logPath is! String ||
          (requireLogArtifacts && !_logArtifactUsable(logPath))) {
        problems.add('quarantine log tidak tersedia: $testName');
        ok = false;
      }
    }
    return ok;
  }

  static bool _logArtifactUsable(String path) {
    final file = File(path);
    return file.existsSync() && file.lengthSync() > 0;
  }

  static DateTime? _parseTimestamp(Object? value) {
    if (value is! String || value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    return parsed.toUtc();
  }

  static Future<String?> _gitHead(Directory repository) async {
    try {
      final result = await Process.run(
        'git',
        ['-C', repository.path, 'rev-parse', 'HEAD'],
      );
      if (result.exitCode != 0) return null;
      final sha = (result.stdout as String).trim();
      return RegExp(r'^[0-9a-f]{40}$').hasMatch(sha) ? sha : null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<String>> _liveConflictingProcesses() async {
    try {
      final result = await Process.run('tasklist', ['/FO', 'CSV', '/NH']);
      if (result.exitCode != 0) {
        return ['tasklist gagal (exit ${result.exitCode})'];
      }
      final conflicts = <String>[];
      final self = pid;
      for (final line in (result.stdout as String).split(RegExp(r'\r?\n'))) {
        final match = RegExp(r'^"([^"]+)","(\d+)"').firstMatch(line.trim());
        if (match == null) continue;
        final name = match.group(1)!.toLowerCase();
        final pid = int.tryParse(match.group(2)!);
        if (pid == null || pid == self) continue;
        final blocking = name.startsWith('flutter') ||
            name == 'dart.exe' ||
            name.startsWith('msbuild') ||
            name == 'dotnet.exe';
        if (blocking) conflicts.add('${match.group(1)}($pid)');
      }
      return conflicts;
    } catch (error) {
      return ['tasklist tidak tersedia: $error'];
    }
  }

  static File _defaultSchedulerFile() {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData == null || localAppData.isEmpty) return File('');
    return File('$localAppData/hermes/cron/jobs.json');
  }

  /// Job scheduler yang menyentuh repo ini (workdir/path/ROADMAP_STATE)
  /// wajib berstatus paused sebelum gateway menulis state.
  static List<String> _schedulerViolations({
    required File jobsFile,
    required Directory repository,
  }) {
    if (!jobsFile.existsSync()) {
      return ['scheduler jobs.json tidak tersedia: ${jobsFile.path}'];
    }
    try {
      final decoded = jsonDecode(jobsFile.readAsStringSync());
      final jobs = decoded is Map<String, dynamic> ? decoded['jobs'] : null;
      if (jobs is! List) {
        return ['scheduler jobs.json tidak memuat daftar jobs'];
      }
      final repoNeedle =
          repository.absolute.path.replaceAll('\\', '/').toLowerCase();
      final violations = <String>[];
      for (final rawJob in jobs) {
        if (rawJob is! Map<String, dynamic>) continue;
        final flattened = _flattenSchedulerText(rawJob).toLowerCase();
        final workdir = rawJob['workdir'];
        final workdirNorm = workdir is String
            ? workdir.replaceAll('\\', '/').toLowerCase()
            : '';
        final inScope = workdirNorm == repoNeedle ||
            flattened.contains(repoNeedle) ||
            flattened.contains('.hermes/roadmap_state');
        if (!inScope) continue;
        if (rawJob['state'] != 'paused') {
          violations.add(
            'scheduler belum paused: ${rawJob['id'] ?? rawJob['name']} '
            '(${rawJob['name']}, state=${rawJob['state']})',
          );
        }
      }
      return violations;
    } catch (error) {
      return ['scheduler jobs.json tidak terbaca: $error'];
    }
  }

  static String _flattenSchedulerText(dynamic value) {
    if (value is String) return value.replaceAll('\\', ' ');
    if (value is Map) return value.values.map(_flattenSchedulerText).join(' ');
    if (value is List) return value.map(_flattenSchedulerText).join(' ');
    return '';
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

Future<void> _inspectCanonicalContinuity({
  required String archiveRoot,
  required int activeSprint,
  required int untilSprint,
  required List<String> issues,
}) async {
  for (var sprint = activeSprint + 1; sprint <= untilSprint; sprint++) {
    final file = File(_join(archiveRoot, 'sprint_$sprint.json'));
    if (!file.existsSync()) {
      issues.add(
        'Canonical continuity contract sprint $sprint tidak tersedia: '
        '${file.path}',
      );
      continue;
    }
    final contract = await _readObject(
      file,
      issues,
      'canonical continuity contract sprint $sprint',
    );
    if (contract == null) continue;

    final contractSprint = _asObject(contract['sprint'])?['number'];
    if (contractSprint != sprint) {
      issues.add(
        'Canonical continuity contract sprint $sprint memiliki nomor '
        '$contractSprint.',
      );
    }
    final rawSteps = contract['steps'];
    if (rawSteps is! List || rawSteps.isEmpty) {
      issues.add(
        'Canonical continuity contract sprint $sprint tidak memiliki steps.',
      );
      continue;
    }
    final stepIds = rawSteps
        .map((step) => _asObject(step)?['id'])
        .whereType<String>()
        .toList(growable: false);
    if (stepIds.length != rawSteps.length ||
        stepIds.toSet().length != stepIds.length) {
      issues.add(
        'Canonical continuity contract sprint $sprint memiliki step IDs '
        'kosong atau duplikat.',
      );
      continue;
    }
    for (var index = 0; index < stepIds.length; index++) {
      final expected = '$sprint.${index + 1}';
      if (stepIds[index] != expected) {
        issues.add(
          'Canonical continuity sequence terputus pada ${stepIds[index]}; '
          'expected $expected.',
        );
        break;
      }
    }
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
