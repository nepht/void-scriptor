/// Test for Security Revalidation (Step 113.26).
/// Validates: security_tests, dependency_scan, package_scan, findings,
/// remediations, and residual_risk by driving the real subsystems
/// (WorkspacePermissionPolicy, PortableProjectImporter zip-slip/secret
/// guards, ProjectPackage path escape, BackupLocationPolicy,
/// PluginSandbox/PluginPermissionSet, SharePackageBuilder leak controls,
/// SecretRedactor/SecretScanner, pubspec.lock dependency scan, and
/// ArchiveSecretPolicy staging/archive scanning).
library;

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/plugin/domain/plugin_manifest.dart';
import 'package:void_scriptor/core/plugin/sandbox/plugin_permission.dart';
import 'package:void_scriptor/core/plugin/sandbox/plugin_sandbox.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/core/security/application/secret_redactor.dart';
import 'package:void_scriptor/core/security/application/secret_scanner.dart';
import 'package:void_scriptor/features/project_resilience/application/archive_secret_policy.dart';
import 'package:void_scriptor/features/project_resilience/application/backup_location_policy.dart';
import 'package:void_scriptor/features/project_resilience/application/portable_project_service.dart';
import 'package:void_scriptor/features/spoiler/domain/share_export.dart';
import 'package:void_scriptor/features/spoiler/domain/spoiler_classification.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_permission_policy.dart';
import 'package:void_scriptor/features/world_logic/domain/security_revalidation.dart';

void main() {
  late Directory tempRoot;
  final validator = SecurityRevalidator();

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('hermes-11326-');
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  group('113.26 Security Revalidation', () {
    // 1. Permission: deny-by-default workspace access policy.
    test('workspace permission policy enforces explicit links and roles', () {
      const policy = WorkspacePermissionPolicy();
      const owner = WorkspaceAccess(isLocalProjectOwner: true);
      const stranger = WorkspaceAccess();
      const linked = WorkspaceAccess(
        readableNovelWorkspaceIds: {'n1'},
        readableCharacterWorkspaceIds: {'c1'},
        writableNovelWorkspaceIds: {'n1'},
        writableCharacterWorkspaceIds: {'c1'},
      );

      final ownerWithLink = policy.canReadCharacterProjection(
        access: owner,
        novelWorkspaceId: 'n1',
        characterWorkspaceId: 'c1',
        hasExplicitLink: true,
      );
      final ownerWithoutLink = policy.canReadCharacterProjection(
        access: owner,
        novelWorkspaceId: 'n1',
        characterWorkspaceId: 'c1',
        hasExplicitLink: false,
      );
      final strangerWithLink = policy.canReadCharacterProjection(
        access: stranger,
        novelWorkspaceId: 'n1',
        characterWorkspaceId: 'c1',
        hasExplicitLink: true,
      );
      final linkedReader = policy.canReadCharacterProjection(
        access: linked,
        novelWorkspaceId: 'n1',
        characterWorkspaceId: 'c1',
        hasExplicitLink: true,
      );
      final writeWithoutOwnerApi = policy.canWriteCharacterCanon(
        access: owner,
        novelWorkspaceId: 'n1',
        characterWorkspaceId: 'c1',
        throughCharacterOwnerApi: false,
      );
      final writeWithOwnerApi = policy.canWriteCharacterCanon(
        access: owner,
        novelWorkspaceId: 'n1',
        characterWorkspaceId: 'c1',
        throughCharacterOwnerApi: true,
      );
      final privateAsStranger = policy.canReadPrivateCharacterFields(
        access: stranger,
        characterWorkspaceId: 'c1',
      );
      final privateAsMember = policy.canReadPrivateCharacterFields(
        access: const WorkspaceAccess(privateCharacterWorkspaceIds: {'c1'}),
        characterWorkspaceId: 'c1',
      );

      final passed =
          ownerWithLink &&
          !ownerWithoutLink &&
          !strangerWithLink &&
          linkedReader &&
          !writeWithoutOwnerApi &&
          writeWithOwnerApi &&
          !privateAsStranger &&
          privateAsMember;
      validator.recordCheck(
        SecurityCheck(
          area: SecurityArea.permission,
          description:
              'WorkspacePermissionPolicy: link eksplisit, owner bypass, write '
              'via character-owner API, private field membership',
          passed: passed,
          detail:
              'ownerLink=$ownerWithLink ownerNoLink=$ownerWithoutLink '
              'stranger=$strangerWithLink linked=$linkedReader '
              'writeNoApi=$writeWithoutOwnerApi writeApi=$writeWithOwnerApi '
              'privateStranger=$privateAsStranger privateMember=$privateAsMember',
        ),
      );
      expect(ownerWithLink, isTrue);
      expect(ownerWithoutLink, isFalse);
      expect(strangerWithLink, isFalse);
      expect(linkedReader, isTrue);
      expect(writeWithoutOwnerApi, isFalse);
      expect(writeWithOwnerApi, isTrue);
      expect(privateAsStranger, isFalse);
      expect(privateAsMember, isTrue);
    });

    // 2. Import: zip-slip entry rejected by checksummed archive import and
    //    no file lands outside the package.
    test('import rejects a zip-slip entry and writes no escaped file', () async {
      final service = ProjectPackageService(
        rootDirectory: Directory('${tempRoot.path}/pkg-root'),
      );
      final source = await service.create(name: 'ZipSlip Fixture');
      final manifestText = await source.manifestFile.readAsString();
      final dbBytes = await source.databaseFile.readAsBytes();

      final archive = Archive()
        ..addFile(ArchiveFile.string('manifest/project.json', manifestText))
        ..addFile(ArchiveFile('database/project.db', dbBytes.length, dbBytes))
        ..addFile(ArchiveFile.string('../evil.txt', 'escaped payload'));
      final checksum = ArchiveIntegrity.computeContentChecksum(archive);
      final manifest = jsonDecode(manifestText) as Map<String, dynamic>;
      archive.addFile(
        ArchiveFile.string(
          ArchiveIntegrity.manifestEntryName,
          jsonEncode(
            ArchiveManifest(
              projectId: source.projectId,
              sourceSchemaVersion: manifest['schemaVersion'] as int,
              checksum: checksum,
            ).toJson(),
          ),
        ),
      );
      final archivePath = File('${tempRoot.path}/zipslip.voidproject');
      await archivePath.writeAsBytes(ZipEncoder().encode(archive));

      final destination = Directory('${tempRoot.path}/import-dest');
      Object? caught;
      try {
        await PortableProjectImporter().importArchive(
          archivePath,
          destination: destination,
        );
      } on Object catch (error) {
        caught = error;
      }

      final evilFile = File(p.join(destination.path, 'evil.txt'));
      final rejectedWithEscape =
          caught is FormatException && caught.message.contains('escapes');
      final noEscapedFile = !evilFile.existsSync();
      final partialCleaned = destination.existsSync()
          ? destination.listSync().isEmpty
          : true;
      validator.recordCheck(
        SecurityCheck(
          area: SecurityArea.importArchive,
          description:
              'PortableProjectImporter menolak entry zip-slip checksum-valid '
              '(../) dan membersihkan output parsial',
          passed: rejectedWithEscape && noEscapedFile && partialCleaned,
          detail:
              'caught=${caught.runtimeType} msg=${caught is FormatException ? caught.message : '-'} '
              'escapedFileExists=${evilFile.existsSync()} '
              'partialCleaned=$partialCleaned',
        ),
      );
      expect(caught, isA<FormatException>());
      expect((caught as FormatException).message, contains('escapes'));
      expect(evilFile.existsSync(), isFalse);
      expect(partialCleaned, isTrue);
    });

    // 3. Import: archive containing a secret file is refused even when the
    //    checksum is valid.
    test(
      'import rejects a checksum-valid archive containing a secret',
      () async {
        final service = ProjectPackageService(
          rootDirectory: Directory('${tempRoot.path}/pkg-root2'),
        );
        final source = await service.create(name: 'Secret Entry Fixture');
        final manifestText = await source.manifestFile.readAsString();
        final dbBytes = await source.databaseFile.readAsBytes();

        final archive = Archive()
          ..addFile(ArchiveFile.string('manifest/project.json', manifestText))
          ..addFile(ArchiveFile('database/project.db', dbBytes.length, dbBytes))
          ..addFile(ArchiveFile.string('secrets.json', '{"apiKey":"leaked"}'));
        final checksum = ArchiveIntegrity.computeContentChecksum(archive);
        final manifest = jsonDecode(manifestText) as Map<String, dynamic>;
        archive.addFile(
          ArchiveFile.string(
            ArchiveIntegrity.manifestEntryName,
            jsonEncode(
              ArchiveManifest(
                projectId: source.projectId,
                sourceSchemaVersion: manifest['schemaVersion'] as int,
                checksum: checksum,
              ).toJson(),
            ),
          ),
        );
        final archivePath = File('${tempRoot.path}/secret-entry.voidproject');
        await archivePath.writeAsBytes(ZipEncoder().encode(archive));

        Object? caught;
        try {
          await PortableProjectImporter().importArchive(
            archivePath,
            destination: Directory('${tempRoot.path}/import-dest2'),
          );
        } on Object catch (error) {
          caught = error;
        }

        final rejectedSecret =
            caught is FormatException && caught.message.contains('secret');
        validator.recordCheck(
          SecurityCheck(
            area: SecurityArea.importArchive,
            description:
                'ArchiveSecretPolicy menolak entry secret (secrets.json) pada '
                'archive dengan checksum valid',
            passed: rejectedSecret,
            detail: 'caught=${caught.runtimeType}',
          ),
        );
        expect(caught, isA<FormatException>());
        expect((caught as FormatException).message, contains('secret'));
      },
    );

    // 4. Path handling: package-relative resolution rejects escapes and the
    //    backup location policy keeps external detection fail-safe.
    test(
      'package path resolution rejects escapes; backup policy is fail-safe',
      () {
        final package = ProjectPackage(
          projectId: 'path-fixture',
          root: Directory('${tempRoot.path}/path-fixture.voidproject'),
        );

        Object? escapeCaught;
        try {
          package.resolve('../evil.txt');
        } on Object catch (error) {
          escapeCaught = error;
        }
        final resolved = package.resolve('database/project.db');

        final policy = BackupLocationPolicy();
        final defaultRoot = policy.resolveBackupRoot(package);
        final externalUsb = Directory('${tempRoot.path}/usb-backups')
          ..createSync();
        policy.configureCustomBackupRoot(externalUsb);
        final customRoot = policy.resolveBackupRoot(package);
        policy.configureCustomBackupRoot(
          Directory('${tempRoot.path}/missing-drive'),
        );
        final fallbackRoot = policy.resolveBackupRoot(package);
        final externalDetected = BackupLocationPolicy.isExternalBackup(
          package,
          p.join(externalUsb.path, 'b.zip'),
        );
        final internalNotExternal = !BackupLocationPolicy.isExternalBackup(
          package,
          p.join(package.backupDirectory.path, 'b.zip'),
        );

        final passed =
            escapeCaught is ArgumentError &&
            p.normalize(resolved).endsWith(p.join('database', 'project.db')) &&
            defaultRoot.path == package.backupDirectory.path &&
            customRoot.path == externalUsb.path &&
            fallbackRoot.path == package.backupDirectory.path &&
            externalDetected &&
            internalNotExternal;
        validator.recordCheck(
          SecurityCheck(
            area: SecurityArea.pathHandling,
            description:
                'ProjectPackage.resolve menolak escape; BackupLocationPolicy '
                'fail-safe (custom root hilang -> default) + deteksi external',
            passed: passed,
            detail:
                'escape=${escapeCaught.runtimeType} default=$defaultRoot '
                'fallbackOk=${fallbackRoot.path == package.backupDirectory.path} '
                'external=$externalDetected internal=$internalNotExternal',
          ),
        );
        expect(escapeCaught, isA<ArgumentError>());
        expect(
          p.normalize(resolved),
          endsWith(p.join('database', 'project.db')),
        );
        expect(defaultRoot.path, package.backupDirectory.path);
        expect(customRoot.path, externalUsb.path);
        expect(fallbackRoot.path, package.backupDirectory.path);
        expect(externalDetected, isTrue);
        expect(internalNotExternal, isTrue);
      },
    );

    // 5. Plugin boundary: sandbox denies by default and permission names are
    //    validated against the known set.
    test('plugin sandbox denies by default and validates permission names', () {
      final openSandbox = PluginSandbox();
      final deniedByDefault = !openSandbox.canAccess(PluginPermission.storage);
      Object? deniedCaught;
      try {
        openSandbox.require(PluginPermission.network);
      } on Object catch (error) {
        deniedCaught = error;
      }
      final granted = PluginSandbox(granted: {PluginPermission.storage});
      final grantedWorks =
          granted.canAccess(PluginPermission.storage) &&
          !granted.canAccess(PluginPermission.projectData);

      Object? unknownCaught;
      try {
        PluginPermissionSet.validate(['storage', 'bogus']);
      } on Object catch (error) {
        unknownCaught = error;
      }
      final knownSet = PluginPermissionSet.validate(['storage', 'ui']);
      final knownValid =
          knownSet.length == 2 &&
          knownSet.contains(PluginPermission.storage) &&
          knownSet.contains(PluginPermission.ui);

      final passed =
          deniedByDefault &&
          deniedCaught is PluginPermissionDenied &&
          grantedWorks &&
          unknownCaught is PluginManifestException &&
          knownValid;
      validator.recordCheck(
        SecurityCheck(
          area: SecurityArea.pluginBoundary,
          description:
              'PluginSandbox deny-by-default + PluginPermission.validasi nama '
              'permission tak dikenal ditolak',
          passed: passed,
          detail:
              'denied=$deniedByDefault require=${deniedCaught.runtimeType} '
              'granted=$grantedWorks unknown=${unknownCaught.runtimeType} '
              'knownValid=$knownValid',
        ),
      );
      expect(deniedByDefault, isTrue);
      expect(deniedCaught, isA<PluginPermissionDenied>());
      expect(grantedWorks, isTrue);
      expect(unknownCaught, isA<PluginManifestException>());
      expect(knownValid, isTrue);
    });

    // 6. Sharing: spoiler-safe export redacts, drops metadata, expires, and
    //    revokes.
    test('share package redacts, drops metadata, expires and revokes', () {
      final registry = SpoilerRegistry()
        ..addAudience(const SpoilerAudience('beta', SpoilerLevel.clean))
        ..classify('twist-ending', SpoilerLevel.major);
      var now = DateTime(2026, 1, 1);
      final builder = SharePackageBuilder(
        registry: registry,
        clock: () => now,
        tokens: () => 'tok-1',
      );
      builder.setDocument(
        title: 'Bab 1',
        blocks: const [
          ShareBlock(
            id: 'b1',
            text: 'rahasia twist',
            spoilerItemId: 'twist-ending',
          ),
          ShareBlock(id: 'b2', text: 'prosa biasa'),
        ],
        metadata: {'internal-user': 'email@example.invalid'},
      );

      final preflight = builder.preflight(audience: 'beta');
      final package = builder.export(
        audience: 'beta',
        ttl: const Duration(hours: 1),
      );
      final manifest = builder.manifestFor('beta');
      final downloadBeforeExpiry = package.downloadAt(now);
      now = now.add(const Duration(hours: 2));
      Object? expiredCaught;
      try {
        package.downloadAt(now);
      } on Object catch (error) {
        expiredCaught = error;
      }

      final shortLived = builder.export(
        audience: 'beta',
        ttl: const Duration(days: 3650),
      )..revokeAt(DateTime(2026, 1, 2));
      Object? revokedCaught;
      try {
        shortLived.downloadAt(DateTime(2026, 1, 3));
      } on Object catch (error) {
        revokedCaught = error;
      }

      final noInternalMetadata = !jsonEncode(
        package.toJson(),
      ).contains('email@example.invalid');
      final passed =
          preflight.redactedCount == 1 &&
          preflight.metadataDropped &&
          !preflight.fullyClean &&
          package.blocks.first.wasRedacted &&
          package.blocks.first.text == '[disensor]' &&
          !package.blocks.last.wasRedacted &&
          manifest.containsHiddenContent &&
          downloadBeforeExpiry.length == 2 &&
          expiredCaught is StateError &&
          revokedCaught is StateError &&
          noInternalMetadata;
      validator.recordCheck(
        SecurityCheck(
          area: SecurityArea.sharing,
          description:
              'SharePackageBuilder: preflight, redaksi spoiler, metadata '
              'dibuang, kedaluwarsa, dan pencabutan menolak download',
          passed: passed,
          detail:
              'redacted=${preflight.redactedCount} meta=${preflight.metadataDropped} '
              'expired=${expiredCaught.runtimeType} revoked=${revokedCaught.runtimeType} '
              'noMeta=$noInternalMetadata',
        ),
      );
      expect(preflight.redactedCount, 1);
      expect(preflight.metadataDropped, isTrue);
      expect(preflight.fullyClean, isFalse);
      expect(package.blocks.first.text, '[disensor]');
      expect(package.blocks.first.wasRedacted, isTrue);
      expect(package.blocks.last.wasRedacted, isFalse);
      expect(manifest.containsHiddenContent, isTrue);
      expect(downloadBeforeExpiry.length, 2);
      expect(expiredCaught, isA<StateError>());
      expect(revokedCaught, isA<StateError>());
      expect(noInternalMetadata, isTrue);
    });

    // 7. Redaction: secrets are replaced/masked and the scanner detects the
    //    supported credential formats without prose false positives.
    test('redactor removes secrets and scanner detects credential formats', () {
      const redactor = SecretRedactor();
      const scanner = SecretScanner();
      const secret = 'ghp_abcdefghijklmnopqrstuvwxyz0123456789';
      const log = 'POST /v1 with Authorization: $secret retry=3';
      final cleaned = redactor.redact(log, secrets: const [secret]);
      final masked = redactor.mask('longsecretvalue');

      const openai = 'sk-abcdefghijklmnopqrstuvwxyz0123456789ABCD';
      const aws = 'AKIAABCDEFGHIJKLMNOP';
      const slack = 'xoxb-abcdefghij-klmnopqrstuvwx';
      final detected = scanner.scan('keys: $openai $aws $secret $slack');
      final proseClean = scanner.scan(
        'The story begins with a hero; no keys were involved today.',
      );

      final passed =
          !cleaned.contains(secret) &&
          cleaned.contains('[REDACTED]') &&
          masked == 'lon****' &&
          detected.contains(openai) &&
          detected.contains(aws) &&
          detected.contains(secret) &&
          detected.contains(slack) &&
          proseClean.isEmpty;
      validator.recordCheck(
        SecurityCheck(
          area: SecurityArea.redaction,
          description:
              'SecretRedactor.redact/mask + SecretScanner 4 format kredensial '
              'tanpa false positive pada prosa',
          passed: passed,
          detail:
              'cleaned=${!cleaned.contains(secret)} masked=$masked '
              'detected=${detected.length} prose=${proseClean.length}',
        ),
      );
      expect(cleaned, isNot(contains(secret)));
      expect(cleaned, contains('[REDACTED]'));
      expect(masked, 'lon****');
      expect(detected, contains(openai));
      expect(detected, contains(aws));
      expect(detected, contains(secret));
      expect(detected, contains(slack));
      expect(proseClean, isEmpty);
    });

    // 8. Dependency scan: every hosted lock entry is hash-pinned and the
    //    dependency graph uses no git/path sources or overrides.
    test('pubspec.lock pins every hosted package; no git/path/overrides', () {
      final lock = File('pubspec.lock');
      expect(lock.existsSync(), isTrue, reason: 'pubspec.lock missing');
      final text = lock.readAsStringSync();

      final headerMatches = RegExp(
        r'^  ([a-zA-Z0-9_.-]+):\s*$',
        multiLine: true,
      ).allMatches(text).toList();
      var hosted = 0;
      var hostedWithoutSha = 0;
      var gitSources = 0;
      var pathSources = 0;
      for (var i = 0; i < headerMatches.length; i++) {
        final start = headerMatches[i].end;
        final end = i + 1 < headerMatches.length
            ? headerMatches[i + 1].start
            : text.length;
        final block = text.substring(start, end);
        if (block.contains('source: hosted')) {
          hosted += 1;
          if (!block.contains('sha256:')) hostedWithoutSha += 1;
        }
        if (block.contains('source: git')) gitSources += 1;
        if (block.contains('source: path')) pathSources += 1;
      }

      final pubspec = File('pubspec.yaml').readAsStringSync();
      final hasOverride = pubspec.contains('dependency_overrides:');
      const scanner = SecretScanner();
      final secretInLock = scanner.scan(text);

      final passed =
          hosted > 0 &&
          hostedWithoutSha == 0 &&
          gitSources == 0 &&
          pathSources == 0 &&
          !hasOverride &&
          secretInLock.isEmpty;
      validator.recordDependencyScan(
        DependencyScanResult(
          hostedPackages: hosted,
          hostedWithoutSha256: hostedWithoutSha,
          gitSources: gitSources,
          pathSources: pathSources,
          dependencyOverrides: hasOverride,
          secretMatches: secretInLock.length,
        ),
      );
      validator.recordCheck(
        SecurityCheck(
          area: SecurityArea.dependency,
          description:
              'Dependency scan pubspec.lock: hosted hash-pinned, tanpa '
              'git/path source, tanpa dependency_overrides, tanpa secret',
          passed: passed,
          detail:
              'hosted=$hosted unpinned=$hostedWithoutSha git=$gitSources '
              'path=$pathSources overrides=$hasOverride secrets=${secretInLock.length}',
        ),
      );
      expect(hosted, greaterThan(0));
      expect(hostedWithoutSha, 0);
      expect(gitSources, 0);
      expect(pathSources, 0);
      expect(hasOverride, isFalse);
      expect(secretInLock, isEmpty);

      validator.recordResidualRisk(
        const ResidualRisk(
          area: SecurityArea.dependency,
          description:
              'Dependency scan berbasis lockfile (hash-pin, source, overrides) '
              '— bukan audit advisory database eksternal/OSV.',
        ),
      );
    });

    // 9. Package scan: staging and archive scans catch secret files and
    //    secret-like payloads while clean staging passes.
    test('archive secret policy scans staging files and archive entries', () async {
      final clean = Directory('${tempRoot.path}/clean-staging')..createSync();
      File(p.join(clean.path, 'manifest')).writeAsStringSync('dir-placeholder');
      await File(
        p.join(clean.path, 'project.json'),
      ).writeAsString('{"name":"Aman"}');
      await ArchiveSecretPolicy.assertNoSecrets(clean);

      final dirty = Directory('${tempRoot.path}/dirty-staging')..createSync();
      await File(p.join(dirty.path, '.env')).writeAsString('API_KEY=x');
      Object? fileCaught;
      try {
        await ArchiveSecretPolicy.assertNoSecrets(dirty);
      } on Object catch (error) {
        fileCaught = error;
      }

      final payloadDir = Directory('${tempRoot.path}/payload-staging')
        ..createSync();
      await File(p.join(payloadDir.path, 'notes.md')).writeAsString(
        'log: ghp_abcdefghijklmnopqrstuvwxyz0123456789 in a note',
      );
      Object? payloadCaught;
      try {
        await ArchiveSecretPolicy.assertNoSecrets(payloadDir);
      } on Object catch (error) {
        payloadCaught = error;
      }

      final dirtyArchive = Archive()
        ..addFile(ArchiveFile.string('manifest/project.json', '{}'))
        ..addFile(ArchiveFile.string('.ssh/id_rsa', 'PRIVATE'));
      Object? archiveCaught;
      try {
        ArchiveSecretPolicy.assertArchiveHasNoSecrets(dirtyArchive);
      } on Object catch (error) {
        archiveCaught = error;
      }

      final detectionMatrix = <String, bool>{
        '.env': ArchiveSecretPolicy.isSecretPath('.env'),
        '.env.example': !ArchiveSecretPolicy.isSecretPath('.env.example'),
        'id_rsa': ArchiveSecretPolicy.isSecretPath('id_rsa'),
        'assets/logo.pem': ArchiveSecretPolicy.isSecretPath('assets/logo.pem'),
        'manifest/project.json': !ArchiveSecretPolicy.isSecretPath(
          'manifest/project.json',
        ),
      };
      final matrixOk = detectionMatrix.values.every((expected) => expected);

      final passed =
          fileCaught is FormatException &&
          payloadCaught is FormatException &&
          archiveCaught is FormatException &&
          matrixOk;
      validator.recordPackageScan(
        PackageScanResult(
          cleanStagingAccepted: true,
          secretFileDetected: fileCaught is FormatException,
          secretPayloadDetected: payloadCaught is FormatException,
          archiveSecretDetected: archiveCaught is FormatException,
          detectionMatrixOk: matrixOk,
        ),
      );
      validator.recordCheck(
        SecurityCheck(
          area: SecurityArea.packaging,
          description:
              'ArchiveSecretPolicy: staging bersih lolos; file secret, payload '
              'secret-like, entry archive secret, dan deteksi filename ditolak',
          passed: passed,
          detail:
              'file=${fileCaught.runtimeType} payload=${payloadCaught.runtimeType} '
              'archive=${archiveCaught.runtimeType} matrix=$matrixOk',
        ),
      );
      expect(fileCaught, isA<FormatException>());
      expect(payloadCaught, isA<FormatException>());
      expect(archiveCaught, isA<FormatException>());
      expect(matrixOk, isTrue);
    });

    // 10. Report: full area coverage with passing checks and zero open
    //     findings yields a pass decision.
    test('report passes when all areas are covered and nothing is open', () {
      validator.recordResidualRisk(
        const ResidualRisk(
          area: SecurityArea.packaging,
          description:
              'Fixture integrasi lokal (temp/in-memory) — bukan proses aplikasi '
              'penuh atau data pengguna; native GUI, hosted CI, signing, '
              'hardware, public release DEFERRED/UNVERIFIABLE.',
        ),
      );
      final report = validator.report();
      for (final area in SecurityArea.all) {
        expect(
          report.checksFor(area),
          isNotEmpty,
          reason: 'missing checks for $area',
        );
      }
      expect(report.dependencyScan, isNotNull);
      expect(report.dependencyScan!.hostedWithoutSha256, 0);
      expect(report.packageScan, isNotNull);
      expect(report.packageScan!.secretFileDetected, isTrue);
      expect(
        report.findings.where((f) => f.status == FindingStatus.open),
        isEmpty,
      );
      expect(report.residualRisks, isNotEmpty);
      expect(report.decision, SecurityRevalidationDecision.pass);
    });

    // 11. Decision contract: blocked/fail paths stay honest.
    test('decision is blocked without evidence and fail on bad state', () {
      final empty = SecurityRevalidator();
      expect(empty.report().decision, SecurityRevalidationDecision.blocked);

      final failed = SecurityRevalidator();
      for (final area in SecurityArea.all) {
        failed.recordCheck(
          SecurityCheck(
            area: area,
            description: 'x',
            passed: area != SecurityArea.dependency,
            detail: 'x',
          ),
        );
      }
      expect(failed.report().decision, SecurityRevalidationDecision.fail);

      final missingArea = SecurityRevalidator();
      for (final area in SecurityArea.all) {
        if (area == SecurityArea.sharing) continue;
        missingArea.recordCheck(
          SecurityCheck(
            area: area,
            description: 'x',
            passed: true,
            detail: 'x',
          ),
        );
      }
      expect(missingArea.report().decision, SecurityRevalidationDecision.fail);

      final openFinding = SecurityRevalidator();
      for (final area in SecurityArea.all) {
        openFinding.recordCheck(
          SecurityCheck(
            area: area,
            description: 'x',
            passed: true,
            detail: 'x',
          ),
        );
      }
      openFinding.recordFinding(
        const SecurityFinding(
          id: 'F-OPEN-1',
          area: SecurityArea.redaction,
          severity: FindingSeverity.medium,
          summary: 'temuan terbuka tanpa remediation',
          status: FindingStatus.open,
        ),
      );
      expect(openFinding.report().decision, SecurityRevalidationDecision.fail);

      final remediated = SecurityRevalidator();
      for (final area in SecurityArea.all) {
        remediated.recordCheck(
          SecurityCheck(
            area: area,
            description: 'x',
            passed: true,
            detail: 'x',
          ),
        );
      }
      remediated.recordFinding(
        const SecurityFinding(
          id: 'F-FIX-1',
          area: SecurityArea.packaging,
          severity: FindingSeverity.low,
          summary: 'temuan sudah diperbaiki',
          status: FindingStatus.remediated,
        ),
      );
      remediated.recordRemediation(
        const SecurityRemediation(
          findingId: 'F-FIX-1',
          action: 'guard ditambahkan + regression test',
        ),
      );
      expect(remediated.report().decision, SecurityRevalidationDecision.pass);
    });

    // 12. Manifest & required-evidence contract.
    group('manifest', () {
      const manifestPath =
          'docs/planning/v1.2/sprint_113_security_revalidation.json';

      test('manifest exists with canonical step 113.26', () {
        final file = File(manifestPath);
        expect(file.existsSync(), isTrue, reason: 'missing manifest');
        final document =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        expect(document['canonical_step'], '113.26');
        expect(document['title'], 'Security Revalidation');
      });

      test('manifest declares all six required evidence groups', () {
        final document =
            jsonDecode(File(manifestPath).readAsStringSync())
                as Map<String, dynamic>;
        final evidence = document['required_evidence'] as Map<String, dynamic>;
        for (final key in [
          'security_tests',
          'dependency_scan',
          'package_scan',
          'findings',
          'remediations',
          'residual_risk',
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
