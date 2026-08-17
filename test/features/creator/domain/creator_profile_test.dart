import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/domain/creator_profile.dart';

void main() {
  group('CreatorProfile', () {
    test('creates with required fields', () {
      // RED: This will fail because class does not exist yet
      final profile = CreatorProfile(
        id: 'test-id',
        userId: 'user-123',
        displayName: 'Test Creator',
        visibility: CreatorVisibility.public,
      );
      expect(profile.displayName, 'Test Creator');
      expect(profile.visibility, CreatorVisibility.public);
    });

    test('copyWith creates new instance with changed fields', () {
      final original = CreatorProfile(
        id: 'id1',
        userId: 'user1',
        displayName: 'Original',
        visibility: CreatorVisibility.private,
      );
      final updated = original.copyWith(
        displayName: 'Updated',
        bio: 'Bio added',
      );
      expect(updated.displayName, 'Updated');
      expect(updated.bio, 'Bio added');
      expect(updated.visibility, CreatorVisibility.private);
      expect(updated.id, original.id);
    });

    test('toJson and fromJson roundtrip', () {
      final original = CreatorProfile(
        id: 'id1',
        userId: 'user1',
        displayName: 'Test',
        bio: 'Bio',
        avatarAssetId: 'avatar1',
        bannerAssetId: 'banner1',
        skills: ['Flutter', 'Dart'],
        specialties: ['UI'],
        portfolioProjectIds: ['proj1'],
        visibility: CreatorVisibility.unlisted,
      );
      final json = original.toJson();
      final restored = CreatorProfile.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.displayName, original.displayName);
      expect(restored.visibility, original.visibility);
      expect(restored.skills, original.skills);
    });
  });
}
