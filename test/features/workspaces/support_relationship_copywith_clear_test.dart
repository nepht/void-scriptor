import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/workspaces/domain/narrative_assignment.dart';

/// Regression coverage for hunt-run157 BUG-10 (Referee REAL BUG, Low):
/// `SupportRelationship.copyWith` could never clear `purpose` or
/// `separationReason` — `null` meant "keep current value", the standard
/// copyWith ambiguity. The repository convention for nullable clears is an
/// explicit `clearX` flag (see ProjectModel-style clear-sentinel guidance in
/// the development contract).
///
/// RED note: pre-fix these named parameters do not exist, so this file fails
/// to compile — that is the exact RED for the missing API.
void main() {
  final support = SupportRelationship(
    sourceCharacterId: 'a',
    supportedId: 'b',
    storyNovelWorkspaceId: 'novel-1',
    type: SupportType.mentor,
    purpose: 'trains the protagonist',
    separationReason: 'betrayal',
  );

  test('clearPurpose removes the purpose without touching other fields', () {
    final cleared = support.copyWith(clearPurpose: true);
    expect(cleared.purpose, isNull);
    expect(cleared.separationReason, 'betrayal');
    expect(cleared.type, SupportType.mentor);
    expect(cleared.sourceCharacterId, 'a');
    expect(cleared.supportedId, 'b');
    expect(cleared.storyNovelWorkspaceId, 'novel-1');
  });

  test('clearSeparationReason removes the reason without touching purpose', () {
    final cleared = support.copyWith(clearSeparationReason: true);
    expect(cleared.separationReason, isNull);
    expect(cleared.purpose, 'trains the protagonist');
  });

  test('both flags clear together; absent flags keep current values', () {
    final both = support.copyWith(
      clearPurpose: true,
      clearSeparationReason: true,
    );
    expect(both.purpose, isNull);
    expect(both.separationReason, isNull);

    final kept = support.copyWith(status: SupportStatus.separated);
    expect(kept.purpose, 'trains the protagonist');
    expect(kept.separationReason, 'betrayal');
    expect(kept.status, SupportStatus.separated);
  });

  test('a value passed alongside its clear flag wins', () {
    final replaced = support.copyWith(
      clearPurpose: true,
      purpose: 'new purpose',
    );
    expect(replaced.purpose, 'new purpose');
  });
}
