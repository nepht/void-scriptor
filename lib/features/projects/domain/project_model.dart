/// Compatibility export (ADR-0001): the canonical owner of `ProjectModel` is
/// `lib/core/domain/project_model.dart`. This path remains so existing public
/// imports keep compiling.
library;

export '../../../core/domain/project_model.dart' show ProjectModel;
