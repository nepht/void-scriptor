/// Compatibility export (ADR-0001): the canonical owner of `AssetType` is
/// `lib/core/domain/asset_type.dart`. This path remains so existing public
/// imports keep compiling.
library;

export '../../../core/domain/asset_type.dart' show AssetType;
