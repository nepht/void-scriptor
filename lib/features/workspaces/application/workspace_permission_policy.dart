final class WorkspaceAccess {
  const WorkspaceAccess({
    this.readableNovelWorkspaceIds = const {},
    this.writableNovelWorkspaceIds = const {},
    this.readableCharacterWorkspaceIds = const {},
    this.writableCharacterWorkspaceIds = const {},
    this.privateCharacterWorkspaceIds = const {},
    this.isLocalProjectOwner = false,
  });

  final Set<String> readableNovelWorkspaceIds;
  final Set<String> writableNovelWorkspaceIds;
  final Set<String> readableCharacterWorkspaceIds;
  final Set<String> writableCharacterWorkspaceIds;
  final Set<String> privateCharacterWorkspaceIds;
  final bool isLocalProjectOwner;
}

final class WorkspacePermissionPolicy {
  const WorkspacePermissionPolicy();

  bool canReadCharacterProjection({
    required WorkspaceAccess access,
    required String novelWorkspaceId,
    required String characterWorkspaceId,
    required bool hasExplicitLink,
  }) =>
      hasExplicitLink &&
      (access.isLocalProjectOwner ||
          access.readableNovelWorkspaceIds.contains(novelWorkspaceId)) &&
      (access.isLocalProjectOwner ||
          access.readableCharacterWorkspaceIds.contains(characterWorkspaceId));

  bool canWriteCharacterCanon({
    required WorkspaceAccess access,
    required String novelWorkspaceId,
    required String characterWorkspaceId,
    required bool throughCharacterOwnerApi,
  }) =>
      throughCharacterOwnerApi &&
      (access.isLocalProjectOwner ||
          access.writableNovelWorkspaceIds.contains(novelWorkspaceId)) &&
      (access.isLocalProjectOwner ||
          access.writableCharacterWorkspaceIds.contains(characterWorkspaceId));

  bool canReadPrivateCharacterFields({
    required WorkspaceAccess access,
    required String characterWorkspaceId,
  }) => access.privateCharacterWorkspaceIds.contains(characterWorkspaceId);
}
