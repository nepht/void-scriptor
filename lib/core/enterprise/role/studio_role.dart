import 'permission.dart';

/// Studio roles with permission matrix (Step 37.2).
enum StudioRole {
  admin,
  member,
  viewer;

  bool can(Permission permission) {
    switch (this) {
      case StudioRole.admin:
        return true;
      case StudioRole.member:
        return permission == Permission.viewContent ||
            permission == Permission.editContent ||
            permission == Permission.managePlugins;
      case StudioRole.viewer:
        return permission == Permission.viewContent;
    }
  }
}
