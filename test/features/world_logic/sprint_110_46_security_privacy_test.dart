// Sprint 110.46 - Security & Privacy Verification.
//
// Verifier-style slice for the 110.46 acceptance required_outputs:
//   threat_review, isolation_tests, secret_data_tests,
//   diagnostic_export_tests, fix_status.
//
// Domain-only, deterministic, no persistence/UI/wall clock/locale/random/network.

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/security_privacy.dart';

SecretDataRecord _publicSecret({int tick = 0, int? released}) {
  return SecretDataRecord.validated(
    id: 'pub-1',
    label: 'public lore',
    classification: SecretClassification.public,
    visibility: SecretVisibility.global,
    concealedTick: tick,
    releasedTick: released,
    reason: 'baseline visible lore',
  );
}

SecretDataRecord _factionSecret({List<String>? factionIds}) {
  return SecretDataRecord.validated(
    id: 'fs-1',
    label: 'faction pact',
    classification: SecretClassification.factionSecret,
    visibility: SecretVisibility.factionScoped,
    concealedTick: 5,
    allowedFactionIds: factionIds ?? ['faction-a'],
    reason: 'restricted to faction-a',
  );
}

SecretDataRecord _characterSecret({List<String>? characterIds}) {
  return SecretDataRecord.validated(
    id: 'cs-1',
    label: 'character motive',
    classification: SecretClassification.characterSecret,
    visibility: SecretVisibility.characterScoped,
    concealedTick: 7,
    allowedCharacterIds: characterIds ?? ['char-a'],
    reason: 'private to character-a',
  );
}

SecretDataRecord _writerOnly() {
  return SecretDataRecord.validated(
    id: 'wo-1',
    label: 'plot twist true culprit',
    classification: SecretClassification.plotTwist,
    visibility: SecretVisibility.writerOnly,
    concealedTick: 0,
    reason: 'writer-only reveal',
  );
}

SecretDataRecord _plotTwist({int tick = 0, int? released}) {
  return SecretDataRecord.validated(
    id: 'pt-1',
    label: 'plot twist',
    classification: SecretClassification.plotTwist,
    visibility: SecretVisibility.global,
    concealedTick: tick,
    releasedTick: released,
    reason: 'planned spoiler',
  );
}

void main() {
  group('110.46 secret_data_tests', () {
    test('factory rejects empty id / label / reason', () {
      expect(
        () => SecretDataRecord.validated(
          id: '',
          label: 'x',
          classification: SecretClassification.public,
          visibility: SecretVisibility.global,
          concealedTick: 0,
          reason: 'r',
        ),
        throwsArgumentError,
      );
      expect(
        () => SecretDataRecord.validated(
          id: 'a',
          label: '',
          classification: SecretClassification.public,
          visibility: SecretVisibility.global,
          concealedTick: 0,
          reason: 'r',
        ),
        throwsArgumentError,
      );
      expect(
        () => SecretDataRecord.validated(
          id: 'a',
          label: 'x',
          classification: SecretClassification.public,
          visibility: SecretVisibility.global,
          concealedTick: 0,
          reason: '',
        ),
        throwsArgumentError,
      );
    });

    test(
      'factory rejects concealedTick negative and releasedTick < concealedTick',
      () {
        expect(
          () => SecretDataRecord.validated(
            id: 'a',
            label: 'x',
            classification: SecretClassification.public,
            visibility: SecretVisibility.global,
            concealedTick: -1,
            reason: 'r',
          ),
          throwsArgumentError,
        );
        expect(
          () => SecretDataRecord.validated(
            id: 'a',
            label: 'x',
            classification: SecretClassification.public,
            visibility: SecretVisibility.global,
            concealedTick: 10,
            releasedTick: 5,
            reason: 'r',
          ),
          throwsArgumentError,
        );
      },
    );

    test('factory enforces scope visibility requires allowed ids', () {
      expect(
        () => SecretDataRecord.validated(
          id: 'a',
          label: 'x',
          classification: SecretClassification.factionSecret,
          visibility: SecretVisibility.factionScoped,
          concealedTick: 0,
          allowedFactionIds: const [],
          reason: 'r',
        ),
        throwsArgumentError,
      );
      expect(
        () => SecretDataRecord.validated(
          id: 'a',
          label: 'x',
          classification: SecretClassification.characterSecret,
          visibility: SecretVisibility.characterScoped,
          concealedTick: 0,
          allowedCharacterIds: const [],
          reason: 'r',
        ),
        throwsArgumentError,
      );
    });

    test(
      'global visibility grants read to any observer; writerOnly denies',
      () {
        final global = _publicSecret();
        expect(global.canObserverRead(), isTrue);
        expect(global.isReleasedAt(0), isFalse);

        final writerOnly = _writerOnly();
        expect(writerOnly.canObserverRead(isWriter: true), isTrue);
        expect(
          writerOnly.canObserverRead(
            observerFactionId: 'any',
            observerCharacterId: 'any',
          ),
          isFalse,
        );
      },
    );

    test(
      'factionScoped restricts to listed factions; characterScoped to characters',
      () {
        final factionSecret = _factionSecret();
        expect(
          factionSecret.canObserverRead(observerFactionId: 'faction-a'),
          isTrue,
        );
        expect(
          factionSecret.canObserverRead(observerFactionId: 'faction-b'),
          isFalse,
        );
        expect(factionSecret.canObserverRead(), isFalse);

        final characterSecret = _characterSecret();
        expect(
          characterSecret.canObserverRead(observerCharacterId: 'char-a'),
          isTrue,
        );
        expect(
          characterSecret.canObserverRead(observerCharacterId: 'char-b'),
          isFalse,
        );
      },
    );

    test('isReleasedAt respects null and inclusive releasedTick', () {
      final unreleased = _plotTwist();
      expect(unreleased.isReleasedAt(0), isFalse);
      expect(unreleased.isReleasedAt(99), isFalse);

      final released = _plotTwist(tick: 5, released: 10);
      expect(released.isReleasedAt(5), isFalse);
      expect(released.isReleasedAt(10), isTrue);
      expect(released.isReleasedAt(11), isTrue);
    });
  });

  group('110.46 isolation_tests', () {
    ProjectNamespace makeLocal() => ProjectNamespace.validated(
      projectId: 'project-a',
      knownIds: {'char-a', 'char-b', 'faction-a', 'place-1'},
    );

    test('foreignIdsIn returns ordered ids not in namespace', () {
      final ns = makeLocal();
      final foreign = ns.foreignIdsIn(['char-a', 'ghost', 'faction-x', 'zz']);
      expect(foreign, ['ghost', 'faction-x', 'zz']);
    });

    test('containsAll true when every id is local', () {
      final ns = makeLocal();
      expect(ns.containsAll(['char-a', 'faction-a']), isTrue);
      expect(ns.containsAll(['char-a', 'foreign']), isFalse);
    });

    test('auditor detects cross-project leakage deterministically', () {
      final local = makeLocal();
      final foreign = ProjectNamespace.validated(
        projectId: 'project-b',
        knownIds: {'char-z', 'faction-z'},
      );
      final auditor = ProjectIsolationAuditor(local: local, foreign: foreign);
      final report = auditor.audit(['char-a', 'char-z', 'ghost']);
      expect(report.isClean, isFalse);
      expect(report.isFullyContained, isFalse);
      expect(report.leakedForeignIds, ['char-z', 'ghost']);
      expect(report.explain(), contains('leaked=char-z,ghost'));
    });

    test('auditor reports clean when all ids belong to local', () {
      final local = makeLocal();
      final foreign = ProjectNamespace.validated(
        projectId: 'project-b',
        knownIds: {'char-z'},
      );
      final auditor = ProjectIsolationAuditor(local: local, foreign: foreign);
      final report = auditor.audit(['char-a', 'char-b']);
      expect(report.isClean, isTrue);
      expect(report.isFullyContained, isTrue);
      expect(report.explain(), contains('clean'));
    });

    test('auditor rejects same projectId for local and foreign', () {
      final local = makeLocal();
      final foreign = ProjectNamespace.validated(
        projectId: 'project-a',
        knownIds: {},
      );
      expect(
        () => ProjectIsolationAuditor(local: local, foreign: foreign),
        throwsArgumentError,
      );
    });
  });

  group('110.46 diagnostic_export_tests', () {
    test('standard filter redacts label for non-readers; keeps id', () {
      final filter = DiagnosticExportFilter.standard();
      final factionSecret = _factionSecret();
      final view = filter.project(
        record: factionSecret,
        observerFactionId: 'faction-b',
      );
      expect(view.visible, isFalse);
      expect(view.label, '[REDACTED]');
      expect(view.id, 'fs-1');
      expect(view.classification, SecretClassification.factionSecret);
    });

    test('writerOnly redaction hides label from readers', () {
      final filter = DiagnosticExportFilter.standard();
      final view = filter.project(record: _writerOnly());
      expect(view.visible, isFalse);
      expect(view.label, '[REDACTED]');
      expect(view.classification, SecretClassification.plotTwist);
    });

    test('writer context sees full label for any record', () {
      final filter = DiagnosticExportFilter.standard();
      final view = filter.project(record: _writerOnly(), isWriter: true);
      expect(view.visible, isTrue);
      expect(view.label, 'plot twist true culprit');
    });

    test('allowed faction sees the full record', () {
      final filter = DiagnosticExportFilter.standard();
      final view = filter.project(
        record: _factionSecret(),
        observerFactionId: 'faction-a',
      );
      expect(view.visible, isTrue);
      expect(view.label, 'faction pact');
    });

    test('projectBatch preserves input order', () {
      final filter = DiagnosticExportFilter.standard();
      final batch = filter.projectBatch(
        [_publicSecret(), _factionSecret(), _writerOnly(), _characterSecret()],
        observerFactionId: 'faction-a',
        observerCharacterId: 'char-a',
      );
      expect(batch.length, 4);
      expect(batch[0].visible, isTrue);
      expect(batch[1].visible, isTrue);
      expect(batch[2].visible, isFalse);
      expect(batch[3].visible, isTrue);
    });
  });

  group('110.46 threat_review & fix_status', () {
    test('finding factory rejects invalid severity and empty strings', () {
      expect(
        () => ThreatFinding.validated(
          code: ThreatCode.crossProjectLeak,
          severity: -1,
          summary: 'x',
          affectedIds: const [],
          recommendation: 'r',
        ),
        throwsArgumentError,
      );
      expect(
        () => ThreatFinding.validated(
          code: ThreatCode.crossProjectLeak,
          severity: 5,
          summary: '',
          affectedIds: const [],
          recommendation: 'r',
        ),
        throwsArgumentError,
      );
      expect(
        () => ThreatFinding.validated(
          code: ThreatCode.crossProjectLeak,
          severity: 5,
          summary: 'x',
          affectedIds: const [],
          recommendation: '',
        ),
        throwsArgumentError,
      );
    });

    test('report sorts findings by severity desc then code.index asc', () {
      final low = ThreatFinding.validated(
        code: ThreatCode.unknownOrigin,
        severity: 2,
        summary: 'low',
        affectedIds: const ['x'],
        recommendation: 'investigate',
      );
      final midA = ThreatFinding.validated(
        code: ThreatCode.unredactedSecret,
        severity: 5,
        summary: 'mid-a',
        affectedIds: const ['y'],
        recommendation: 'redact',
      );
      final midB = ThreatFinding.validated(
        code: ThreatCode.factionSecretExposure,
        severity: 5,
        summary: 'mid-b',
        affectedIds: const ['z'],
        recommendation: 'review',
      );
      final critical = ThreatFinding.validated(
        code: ThreatCode.writerOnlyLeak,
        severity: 9,
        summary: 'critical',
        affectedIds: const ['w'],
        recommendation: 'revoke',
      );
      final report = ThreatReviewReport.from([low, midA, midB, critical]);
      expect(report.findings.map((f) => f.severity).toList(), [9, 5, 5, 2]);
      expect(report.findings[1].code, ThreatCode.unredactedSecret);
      expect(report.findings[2].code, ThreatCode.factionSecretExposure);
      expect(report.fixStatus, FixStatus.actionRequired);
      expect(report.requiresAction, isTrue);
      expect(report.explain(), contains('status=actionRequired'));
    });

    test('empty report is clean with status acceptable', () {
      final report = ThreatReviewReport.from(const []);
      expect(report.isClean, isTrue);
      expect(report.fixStatus, FixStatus.acceptable);
      expect(report.explain(), contains('status=acceptable'));
    });

    test('report fixStatus stays acceptable when severity under threshold', () {
      final finding = ThreatFinding.validated(
        code: ThreatCode.unknownOrigin,
        severity: 7,
        summary: 'minor',
        affectedIds: const ['x'],
        recommendation: 'check',
      );
      final report = ThreatReviewReport.from([finding]);
      expect(report.fixStatus, FixStatus.acceptable);
      expect(report.requiresAction, isFalse);
    });
  });
}
