import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/domain/collaboration_request.dart';

void main() {
  group('CollaborationRequest', () {
    test('holds invitation flow fields', () {
      const req = CollaborationRequest(
        id: 'r1',
        fromCreatorId: 'a',
        toCreatorId: 'b',
        projectId: 'p1',
        role: 'Artist',
      );
      expect(req.fromCreatorId, 'a');
      expect(req.role, 'Artist');
      expect(req.status, CollaborationRequestStatus.pending);
      expect(req.acceptedAt, isNull);
    });

    test('accept transitions to active', () {
      const req = CollaborationRequest(
        id: 'r1',
        fromCreatorId: 'a',
        toCreatorId: 'b',
        projectId: 'p1',
        role: 'Writer',
      );
      final accepted = req.accept();
      expect(accepted.status, CollaborationRequestStatus.active);
      expect(accepted.acceptedAt, isNotNull);
    });

    test('decline transitions to declined', () {
      const req = CollaborationRequest(
        id: 'r1',
        fromCreatorId: 'a',
        toCreatorId: 'b',
        projectId: 'p1',
        role: 'Writer',
      );
      final declined = req.decline();
      expect(declined.status, CollaborationRequestStatus.declined);
    });
  });
}
