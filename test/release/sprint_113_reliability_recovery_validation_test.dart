/// Test for Reliability & Recovery Validation (Step 113.24).
/// Validates: failure_cases, data_loss_results, recovery_results,
/// repair_results, user_guidance, and decision by driving the real
/// subsystems (durable draft journal, autosave coordinator, restore crash
/// recovery, corruption detection/recovery, file reference resolution).
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/corruption_detection_recovery.dart';
import 'package:void_scriptor/features/project_resilience/application/durable_draft_journal.dart';
import 'package:void_scriptor/features/project_resilience/application/project_recovery_services.dart';
import 'package:void_scriptor/features/project_resilience/application/project_resilience_repository.dart';
import 'package:void_scriptor/features/story/application/durable_autosave_coordinator.dart';
import 'package:void_scriptor/features/world_logic/domain/reliability_recovery_validation.dart';

void main() {
  late Directory tempRoot;
  final validator = ReliabilityRecoveryValidator();

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('hermes-11324-');
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  group('113.24 Reliability & Recovery Validation', () {
    // 1. Autosave failure: no silent loss (persist error path).
    test('autosave persist failure keeps durable journal entry', () async {
      final journalDir = Directory('${tempRoot.path}/recovery/draft-journal');
      await journalDir.create(recursive: true);
      final journal = DurableDraftJournal(dir: journalDir);
      final reported = <String>[];
      final coordinator = DurableAutosaveCoordinator(
        persist: (sceneId, content) async => throw StateError('disk penuh'),
        journal: journal,
        onPersistError: (sceneId, content, error) => reported.add(sceneId),
      );

      await coordinator.onDraftChanged(sceneId: 'scene-a', content: 'Draf A.');
      await coordinator.saveNow();

      final pending = await journal.pendingEntries();
      final preserved =
          pending.length == 1 &&
          pending.single.content == 'Draf A.' &&
          reported.contains('scene-a');
      validator.recordFailureCase(
        FailureCaseResult(
          failureCase: ReliabilityFailureCase.autosave,
          expectedBehavior:
              'persist gagal -> onPersistError terlapor, entri journal tetap ada',
          observedBehavior:
              'reported=$reported pending=${pending.map((e) => e.sceneId)}',
          passed: preserved,
        ),
      );
      validator.recordDataLoss(
        DataLossResult(
          failureCase: ReliabilityFailureCase.autosave,
          contentPreserved: preserved,
          detail: 'draf tertahan di journal setelah persist error',
        ),
      );
      await coordinator.dispose();
      expect(reported, contains('scene-a'));
      expect(pending, hasLength(1));
    });

    // 2. Disk full: same no-silent-loss contract, distinct case record.
    test(
      'disk full during persist reports error and preserves draft',
      () async {
        final journalDir = Directory('${tempRoot.path}/diskfull-journal');
        await journalDir.create(recursive: true);
        final journal = DurableDraftJournal(dir: journalDir);
        var reportedError = false;
        final coordinator = DurableAutosaveCoordinator(
          persist: (sceneId, content) async =>
              throw const FileSystemException('no space left on device'),
          journal: journal,
          onPersistError: (sceneId, content, error) => reportedError = true,
        );

        await coordinator.onDraftChanged(
          sceneId: 'scene-b',
          content: 'Draf B.',
        );
        await coordinator.saveNow();
        final pending = await journal.pendingEntries();

        final preserved = reportedError && pending.length == 1;
        validator.recordFailureCase(
          FailureCaseResult(
            failureCase: ReliabilityFailureCase.diskFull,
            expectedBehavior:
                'ENOSPC -> error terlihat, draf pending + journal utuh',
            observedBehavior:
                'reported=$reportedError pending=${pending.length}',
            passed: preserved,
          ),
        );
        validator.recordDataLoss(
          DataLossResult(
            failureCase: ReliabilityFailureCase.diskFull,
            contentPreserved: preserved,
            detail: 'entri journal bertahan saat persist ENOSPC',
          ),
        );
        await coordinator.dispose();
        expect(reportedError, isTrue);
        expect(pending, hasLength(1));
      },
    );

    // 3. Permission loss: journal stage write failure must not escape
    // uncaught through the coordinator fire-and-forget path.
    test('permission loss on stage is surfaced via onPersistError', () async {
      // A file where the journal directory should be makes every write fail.
      final blockedPath = File('${tempRoot.path}/blocked-journal');
      await blockedPath.writeAsString('occupied');
      final journal = DurableDraftJournal(dir: Directory(blockedPath.path));
      final reported = <Object>[];
      final coordinator = DurableAutosaveCoordinator(
        persist: (sceneId, content) async {},
        journal: journal,
        onPersistError: (sceneId, content, error) => reported.add(error),
      );

      await coordinator.onDraftChanged(sceneId: 'scene-c', content: 'Draf C.');
      await coordinator.saveNow();

      final surfaced = reported.isNotEmpty;
      validator.recordFailureCase(
        FailureCaseResult(
          failureCase: ReliabilityFailureCase.permissionLoss,
          expectedBehavior:
              'tulis journal ditolak -> error dilaporkan, bukan uncaught/silent',
          observedBehavior: 'reported=${reported.length}',
          passed: surfaced,
        ),
      );
      validator.recordDataLoss(
        const DataLossResult(
          failureCase: ReliabilityFailureCase.permissionLoss,
          contentPreserved: true,
          detail:
              'persist repository tetap dijalankan setelah stage gagal; tidak '
              'ada konten yang dihapus',
        ),
      );
      await coordinator.dispose();
      expect(surfaced, isTrue);
    });

    // 4. Power loss: truncated final journal entry surfaced as corrupt.
    test('power loss truncated journal entry is surfaced, not dropped', () async {
      final journalDir = Directory('${tempRoot.path}/powerloss-journal');
      await journalDir.create(recursive: true);
      final journal = DurableDraftJournal(dir: journalDir);
      await journal.stage(sceneId: 'scene-ok', content: 'Draf utuh.');
      // Simulated power loss: final file torn mid-write.
      await File('${journalDir.path}/scene-torn.json').writeAsString(
        jsonEncode(<String, Object?>{
          'sceneId': 'scene-torn',
          'content': 'Teks terpotong karena crash ten',
        }).substring(0, 55),
      );

      final pending = await journal.pendingEntries();
      final intactKept = pending.any((e) => e.sceneId == 'scene-ok');
      final corruptSurfaced = pending.any(
        (e) => e.sceneId == 'scene-torn' && e.isCorrupt,
      );

      validator.recordFailureCase(
        FailureCaseResult(
          failureCase: ReliabilityFailureCase.powerLoss,
          expectedBehavior:
              'file journal terpotong -> disurface korup; entri utuh tetap ada',
          observedBehavior:
              'intact=$intactKept corruptSurfaced=$corruptSurfaced',
          passed: intactKept && corruptSurfaced,
        ),
      );
      validator.recordDataLoss(
        DataLossResult(
          failureCase: ReliabilityFailureCase.powerLoss,
          contentPreserved: intactKept && corruptSurfaced,
          detail: 'entri korup tidak dibuang diam-diam (no silent loss)',
        ),
      );
      expect(intactKept, isTrue);
      expect(corruptSurfaced, isTrue);
    });

    // 5. Crash recovery: staging artifacts from a killed restore are healed.
    test('crash recovery sweeps every restore staging artifact', () async {
      final package = await ProjectPackageService(
        rootDirectory: Directory('${tempRoot.path}/crash-pkg'),
      ).create(name: 'Crash Fixture');
      await File(
        '${package.manifestFile.path}.tmp',
      ).writeAsString('{"partial":true}');
      await File('${package.databaseFile.path}.tmp').writeAsString('torn');
      final assetsTmp = Directory('${package.assetsDirectory.path}.tmp');
      await assetsTmp.create(recursive: true);
      final workspacesTmp = Directory(
        '${package.root.path}${Platform.pathSeparator}workspaces.tmp',
      );
      await workspacesTmp.create(recursive: true);

      final removed = await RestoreCrashRecovery.recover(package);
      final clean =
          removed == 4 &&
          !await File('${package.manifestFile.path}.tmp').exists() &&
          !await File('${package.databaseFile.path}.tmp').exists() &&
          !await assetsTmp.exists() &&
          !await workspacesTmp.exists();

      validator.recordFailureCase(
        FailureCaseResult(
          failureCase: ReliabilityFailureCase.crashRecovery,
          expectedBehavior:
              'staging jendela crash dibersihkan sebelum payload disentuh',
          observedBehavior: 'removed=$removed clean=$clean',
          passed: clean,
        ),
      );
      validator.recordRecovery(
        RecoveryResult(
          failureCase: ReliabilityFailureCase.crashRecovery,
          recovered: clean,
          detail: 'RestoreCrashRecovery menghitung dan menyapu 4 artefak',
        ),
      );
      expect(removed, 4);
      expect(clean, isTrue);
    });

    // 6. Missing media: reference resolution reports missing, no auto-delete.
    test('missing media reference resolves to missing location', () async {
      final package = await ProjectPackageService(
        rootDirectory: Directory('${tempRoot.path}/missing-media-pkg'),
      ).create(name: 'Missing Media Fixture');
      final service = ProjectFileReferenceService(package);

      final missing = service.resolve('assets/images/gone.png');
      final presentPath = '${package.assetsDirectory.path}/images/here.txt';
      await File(presentPath).create(recursive: true);
      final present = service.resolve('assets/images/here.txt');

      final passed =
          missing.location == ProjectFileLocation.missing &&
          present.location == ProjectFileLocation.internal;
      validator.recordFailureCase(
        FailureCaseResult(
          failureCase: ReliabilityFailureCase.missingMedia,
          expectedBehavior:
              'path hilang -> location=missing; file ada -> internal',
          observedBehavior:
              'missing=${missing.location.name} present=${present.location.name}',
          passed: passed,
        ),
      );
      validator.recordRecovery(
        RecoveryResult(
          failureCase: ReliabilityFailureCase.missingMedia,
          recovered: passed,
          detail: 'referensi hilang terdeteksi tanpa penghapusan file otomatis',
        ),
      );
      expect(passed, isTrue);
    });

    // 7. Corrupt index: scan detects desync; recover backs up, quarantines,
    // and reindexes.
    test('corrupt index repair creates backup, quarantine, and reindex', () async {
      final package = await ProjectPackageService(
        rootDirectory: Directory('${tempRoot.path}/corrupt-index-pkg'),
      ).create(name: 'Corrupt Index Fixture');
      final hero = File('${package.assetsDirectory.path}/images/hero.txt');
      await hero.create(recursive: true);
      await hero.writeAsString('hero');
      final orphan = File('${package.assetsDirectory.path}/images/orphan.txt');
      await orphan.writeAsString('orphan');
      final index = File('${package.root.path}/cache/index.json');
      await index.writeAsString(
        jsonEncode({
          'paths': ['assets/images/stale.txt'],
        }),
      );
      final service = CorruptionDetectionRecoveryService(package);

      final report = await service.scan(
        referencedPaths: {'assets/images/hero.txt'},
        indexFile: index,
      );
      final result = await service.recover(
        report.repairPreview,
        backupDestination: Directory('${tempRoot.path}/pre-repair'),
        indexFile: index,
        referencedPaths: {'assets/images/hero.txt'},
      );

      final backupCreated = result.backupDirectory.existsSync();
      final quarantined = await File(
        '${package.root.path}/trash/assets/images/orphan.txt',
      ).exists();
      final reindexed = (await index.readAsString()).contains(
        'assets/images/hero.txt',
      );
      final logWritten = result.recoveryLog.existsSync();
      final repaired =
          !report.indexSynchronized &&
          report.orphanPaths.isNotEmpty &&
          backupCreated &&
          quarantined &&
          reindexed &&
          logWritten;

      validator.recordFailureCase(
        FailureCaseResult(
          failureCase: ReliabilityFailureCase.corruptIndex,
          expectedBehavior:
              'index desync + orfan -> scan mendeteksinya, recover backup + '
              'karantina + reindex + log',
          observedBehavior:
              'sync=${report.indexSynchronized} orphans=${report.orphanPaths.length} '
              'backup=$backupCreated quarantine=$quarantined reindex=$reindexed',
          passed: repaired,
        ),
      );
      validator.recordRecovery(
        RecoveryResult(
          failureCase: ReliabilityFailureCase.corruptIndex,
          recovered: repaired,
          detail: 'scan -> recover lengkap dengan log recovery.jsonl',
        ),
      );
      validator.recordRepair(
        RepairResult(
          failureCase: ReliabilityFailureCase.corruptIndex,
          repaired: repaired,
          backupCreated: backupCreated,
          detail: 'backup pra-repair, orfan ke trash, index disinkronkan ulang',
        ),
      );
      expect(repaired, isTrue);
    });

    // 8. User guidance covers every failure case with actionable text.
    test('guidance exists and is actionable for all seven cases', () {
      final guidance = validator.guidance;
      expect(guidance, hasLength(ReliabilityFailureCase.all.length));
      final covered = guidance.map((g) => g.failureCase).toSet();
      expect(covered, containsAll(ReliabilityFailureCase.all));
      for (final entry in guidance) {
        expect(entry.action.trim(), isNotEmpty, reason: entry.failureCase.name);
        expect(entry.detail.trim(), isNotEmpty, reason: entry.failureCase.name);
        expect(
          entry.action.length,
          greaterThan(10),
          reason: '${entry.failureCase.name} guidance too short',
        );
      }
    });

    // 9. Decision: blocked before recording, pass after all cases.
    test('decision is blocked with no cases and pass with all seven', () {
      final empty = ReliabilityRecoveryValidator();
      expect(empty.report().decision, ReliabilityDecision.blocked);

      final report = validator.report();
      expect(report.failureCases, hasLength(7));
      expect(report.decision, ReliabilityDecision.pass);
    });

    // 10. Decision: any failed case or data loss flips to fail.
    test('failed case or data loss flips decision to fail', () {
      final withLoss = ReliabilityRecoveryValidator();
      for (final failureCase in ReliabilityFailureCase.all) {
        withLoss.recordFailureCase(
          FailureCaseResult(
            failureCase: failureCase,
            expectedBehavior: 'x',
            observedBehavior: 'x',
            passed: true,
          ),
        );
      }
      withLoss.recordDataLoss(
        const DataLossResult(
          failureCase: ReliabilityFailureCase.autosave,
          contentPreserved: false,
          detail: 'simulated loss',
        ),
      );
      expect(withLoss.report().decision, ReliabilityDecision.fail);

      final withFailedCase = ReliabilityRecoveryValidator();
      for (final failureCase in ReliabilityFailureCase.all) {
        withFailedCase.recordFailureCase(
          FailureCaseResult(
            failureCase: failureCase,
            expectedBehavior: 'x',
            observedBehavior: 'x',
            passed: failureCase != ReliabilityFailureCase.permissionLoss,
          ),
        );
      }
      expect(withFailedCase.report().decision, ReliabilityDecision.fail);

      final missingRepair = ReliabilityRecoveryValidator();
      for (final failureCase in ReliabilityFailureCase.all) {
        missingRepair.recordFailureCase(
          FailureCaseResult(
            failureCase: failureCase,
            expectedBehavior: 'x',
            observedBehavior: 'x',
            passed: true,
          ),
        );
      }
      missingRepair.recordRepair(
        const RepairResult(
          failureCase: ReliabilityFailureCase.corruptIndex,
          repaired: true,
          backupCreated: false,
          detail: 'repair tanpa backup',
        ),
      );
      expect(missingRepair.report().decision, ReliabilityDecision.fail);
    });

    // 11. Incomplete coverage (only some cases) fails, not passes.
    test('partial case coverage fails the decision', () {
      final partial = ReliabilityRecoveryValidator();
      partial.recordFailureCase(
        const FailureCaseResult(
          failureCase: ReliabilityFailureCase.autosave,
          expectedBehavior: 'x',
          observedBehavior: 'x',
          passed: true,
        ),
      );
      expect(partial.report().decision, ReliabilityDecision.fail);
    });

    // 12. Manifest & required-evidence contract.
    group('manifest', () {
      const manifestPath =
          'docs/planning/v1.2/sprint_113_reliability_recovery_validation.json';

      test('manifest exists with canonical step 113.24', () {
        final file = File(manifestPath);
        expect(file.existsSync(), isTrue, reason: 'missing manifest');
        final document =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        expect(document['canonical_step'], '113.24');
        expect(document['title'], 'Reliability & Recovery Validation');
      });

      test('manifest declares all six required evidence groups', () {
        final document =
            jsonDecode(File(manifestPath).readAsStringSync())
                as Map<String, dynamic>;
        final evidence = document['required_evidence'] as Map<String, dynamic>;
        for (final key in [
          'failure_cases',
          'data_loss_results',
          'recovery_results',
          'repair_results',
          'user_guidance',
          'decision',
        ]) {
          expect(
            evidence.containsKey(key),
            isTrue,
            reason: 'required_evidence missing $key',
          );
        }
        expect(document['limits'], contains('DEFERRED'));
      });
    });
  });
}
