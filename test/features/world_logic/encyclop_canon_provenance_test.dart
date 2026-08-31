// Sprint 111.4 - Canon, Provenance & Confidence Model.
// Domain-only contract for canon_status, source_reference, author_or_culture,
// confidence, assumptions, and revision_history.
// No persistence, UI, locale, network, wall clock, or random input.

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclop_canon_provenance.dart';

void main() {
  group('111.4 canon_status', () {
    test('CanonStatus enum exposes canon/rumor/myth/hypothesis/generated', () {
      expect(
        CanonStatus.values,
        containsAll(<CanonStatus>[
          CanonStatus.canon,
          CanonStatus.rumor,
          CanonStatus.myth,
          CanonStatus.hypothesis,
          CanonStatus.generated,
        ]),
      );
    });
  });

  group('111.4 source_reference', () {
    test('SourceReference.validated rejects empty reference id', () {
      expect(
        () => SourceReference.validated(referenceId: '', kind: 'text'),
        throwsArgumentError,
      );
      expect(
        () => SourceReference.validated(referenceId: '   ', kind: 'text'),
        throwsArgumentError,
      );
    });

    test('SourceReference.validated rejects empty kind', () {
      expect(
        () => SourceReference.validated(referenceId: 'ref1', kind: ''),
        throwsArgumentError,
      );
    });
  });

  group('111.4 author_or_culture', () {
    test('AuthorAttribution.validated rejects empty id and label', () {
      expect(
        () => AuthorAttribution.validated(id: '', label: 'A'),
        throwsArgumentError,
      );
      expect(
        () => AuthorAttribution.validated(id: 'a1', label: ''),
        throwsArgumentError,
      );
    });
  });

  group('111.4 confidence', () {
    test('CanonClaim.validated rejects confidence outside [0, 1]', () {
      expect(
        () => CanonClaim.validated(
          claimId: 'c1',
          status: CanonStatus.canon,
          sourceReference: 'src1',
          authorOrCulture: 'a1',
          confidence: -0.1,
        ),
        throwsArgumentError,
      );
      expect(
        () => CanonClaim.validated(
          claimId: 'c1',
          status: CanonStatus.canon,
          sourceReference: 'src1',
          authorOrCulture: 'a1',
          confidence: 1.5,
        ),
        throwsArgumentError,
      );
    });

    test('CanonClaim.validated accepts boundary 0.0 and 1.0', () {
      final zero = CanonClaim.validated(
        claimId: 'c1',
        status: CanonStatus.rumor,
        sourceReference: 'src1',
        authorOrCulture: 'a1',
        confidence: 0.0,
      );
      expect(zero.confidence, 0.0);
      final one = CanonClaim.validated(
        claimId: 'c2',
        status: CanonStatus.canon,
        sourceReference: 'src1',
        authorOrCulture: 'a1',
        confidence: 1.0,
      );
      expect(one.confidence, 1.0);
    });
  });

  group('111.4 assumptions', () {
    test('CanonClaim rejects empty assumption entries', () {
      expect(
        () => CanonClaim.validated(
          claimId: 'c1',
          status: CanonStatus.canon,
          sourceReference: 'src1',
          authorOrCulture: 'a1',
          assumptions: ['valid', '  '],
        ),
        throwsArgumentError,
      );
    });

    test('CanonClaim trims assumption strings', () {
      final claim = CanonClaim.validated(
        claimId: 'c1',
        status: CanonStatus.canon,
        sourceReference: 'src1',
        authorOrCulture: 'a1',
        assumptions: ['  verified field study  ', 'untested'],
      );
      expect(claim.assumptions, ['verified field study', 'untested']);
    });
  });

  group('111.4 revision_history', () {
    test('RevisionEntry.validated rejects empty revisionId and reason', () {
      expect(
        () => RevisionEntry.validated(
          revisionId: '',
          recordedAtTick: 0,
          reason: 'r',
          priorConfidence: 0.5,
          newConfidence: 0.6,
        ),
        throwsArgumentError,
      );
      expect(
        () => RevisionEntry.validated(
          revisionId: 'r1',
          recordedAtTick: 0,
          reason: '',
          priorConfidence: 0.5,
          newConfidence: 0.6,
        ),
        throwsArgumentError,
      );
    });

    test('RevisionEntry.validated rejects negative tick', () {
      expect(
        () => RevisionEntry.validated(
          revisionId: 'r1',
          recordedAtTick: -1,
          reason: 'r',
          priorConfidence: 0.5,
          newConfidence: 0.6,
        ),
        throwsArgumentError,
      );
    });

    test('RevisionEntry.validated rejects confidences outside [0, 1]', () {
      expect(
        () => RevisionEntry.validated(
          revisionId: 'r1',
          recordedAtTick: 0,
          reason: 'r',
          priorConfidence: -0.1,
          newConfidence: 0.6,
        ),
        throwsArgumentError,
      );
      expect(
        () => RevisionEntry.validated(
          revisionId: 'r1',
          recordedAtTick: 0,
          reason: 'r',
          priorConfidence: 0.5,
          newConfidence: 1.1,
        ),
        throwsArgumentError,
      );
    });

    test('CanonClaim.appendRevision appends and updates confidence', () {
      var claim = CanonClaim.validated(
        claimId: 'c1',
        status: CanonStatus.rumor,
        sourceReference: 'src1',
        authorOrCulture: 'a1',
        confidence: 0.5,
      );
      for (var i = 0; i < 5; i++) {
        final tick = i;
        final nc = (0.5 + i * 0.05).clamp(0.0, 1.0).toDouble();
        claim = claim.appendRevision(
          revisionId: 'r$tick',
          recordedAtTick: tick,
          reason: 'rev $tick',
          newConfidence: nc,
        );
      }
      expect(claim.history, hasLength(5));
      expect(claim.confidence, closeTo(0.7, 1e-9));
      expect(claim.history.last.reason, 'rev 4');
    });
  });

  group('111.4 cross-requirement coherence', () {
    test(
      'CanonClaim requires non-empty claimId, sourceReference, authorOrCulture',
      () {
        expect(
          () => CanonClaim.validated(
            claimId: '',
            status: CanonStatus.canon,
            sourceReference: 'src1',
            authorOrCulture: 'a1',
          ),
          throwsArgumentError,
        );
        expect(
          () => CanonClaim.validated(
            claimId: 'c1',
            status: CanonStatus.canon,
            sourceReference: '',
            authorOrCulture: 'a1',
          ),
          throwsArgumentError,
        );
        expect(
          () => CanonClaim.validated(
            claimId: 'c1',
            status: CanonStatus.canon,
            sourceReference: 'src1',
            authorOrCulture: '',
          ),
          throwsArgumentError,
        );
      },
    );

    test('structural equality is by value not identity', () {
      final a = CanonClaim.validated(
        claimId: 'c1',
        status: CanonStatus.myth,
        sourceReference: 'src1',
        authorOrCulture: 'a1',
      );
      final b = CanonClaim.validated(
        claimId: 'c1',
        status: CanonStatus.myth,
        sourceReference: 'src1',
        authorOrCulture: 'a1',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
