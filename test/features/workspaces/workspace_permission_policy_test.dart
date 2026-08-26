import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_permission_policy.dart';

void main() {
  const policy = WorkspacePermissionPolicy();

  test('cross-workspace read requires both grants and an explicit link', () {
    const novelOnly = WorkspaceAccess(readableNovelWorkspaceIds: {'novel-1'});
    const both = WorkspaceAccess(
      readableNovelWorkspaceIds: {'novel-1'},
      readableCharacterWorkspaceIds: {'character-1'},
    );

    expect(
      policy.canReadCharacterProjection(
        access: novelOnly,
        novelWorkspaceId: 'novel-1',
        characterWorkspaceId: 'character-1',
        hasExplicitLink: true,
      ),
      isFalse,
    );
    expect(
      policy.canReadCharacterProjection(
        access: both,
        novelWorkspaceId: 'novel-1',
        characterWorkspaceId: 'character-1',
        hasExplicitLink: false,
      ),
      isFalse,
    );
    expect(
      policy.canReadCharacterProjection(
        access: both,
        novelWorkspaceId: 'novel-1',
        characterWorkspaceId: 'character-1',
        hasExplicitLink: true,
      ),
      isTrue,
    );
  });

  test(
    'cross-workspace write requires owner API and character write grant',
    () {
      const access = WorkspaceAccess(
        writableNovelWorkspaceIds: {'novel-1'},
        writableCharacterWorkspaceIds: {'character-1'},
      );

      expect(
        policy.canWriteCharacterCanon(
          access: access,
          novelWorkspaceId: 'novel-1',
          characterWorkspaceId: 'character-1',
          throughCharacterOwnerApi: false,
        ),
        isFalse,
      );
      expect(
        policy.canWriteCharacterCanon(
          access: access,
          novelWorkspaceId: 'novel-1',
          characterWorkspaceId: 'character-1',
          throughCharacterOwnerApi: true,
        ),
        isTrue,
      );
    },
  );

  test('private character fields are hidden unless explicitly granted', () {
    expect(
      policy.canReadPrivateCharacterFields(
        access: const WorkspaceAccess(),
        characterWorkspaceId: 'character-1',
      ),
      isFalse,
    );
    expect(
      policy.canReadPrivateCharacterFields(
        access: const WorkspaceAccess(
          privateCharacterWorkspaceIds: {'character-1'},
        ),
        characterWorkspaceId: 'character-1',
      ),
      isTrue,
    );
  });

  test(
    'explicit local project owner grant covers both workspace boundaries',
    () {
      const access = WorkspaceAccess(isLocalProjectOwner: true);

      expect(
        policy.canReadCharacterProjection(
          access: access,
          novelWorkspaceId: 'novel-1',
          characterWorkspaceId: 'character-1',
          hasExplicitLink: true,
        ),
        isTrue,
      );
      expect(
        policy.canReadPrivateCharacterFields(
          access: access,
          characterWorkspaceId: 'character-1',
        ),
        isFalse,
      );
    },
  );
}
