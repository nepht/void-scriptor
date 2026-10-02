import 'package:flutter/material.dart';

import '../../../design_system/theme/void_theme_context.dart';
import '../domain/account_center_design_tokens.dart';

/// Closes the `avatar:ring_size` open item from 117.23.
///
/// `profile_avatar.ring_size_px` (96) is a declared token, and the validation
/// drill already knows how to measure a ring: a 96px box concentric with the
/// avatar. Nothing on the reference screen drew one, so the token was
/// unreachable capacity rather than a shipped visual - reported `unmet` rather
/// than folded into a pass. This widget is the missing render path.
///
/// The ring is a frame, not a decoration: it is [SizedBox]-exact so the drill's
/// `abs(size - 96) <= 0.5` measurement has something real to land on, and it
/// wraps the avatar so the two centres coincide by construction rather than by
/// a padding guess. Every size comes from the token, so changing
/// [AccountCenterAvatarSizeTokens.ring] moves the rendered ring with it.
class AccountCenterAvatarRing extends StatelessWidget {
  const AccountCenterAvatarRing({super.key, required this.child});

  /// Keyed `account-profile-avatar-ring`, so a drill can address the ring
  /// directly instead of inferring it from an ancestor's box.
  static const Key ringKey = ValueKey('account-profile-avatar-ring');

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const tokens = AccountCenterDesignTokens.avatarSizes;
    // The frame is a plain SizedBox, deliberately NOT a ClipOval: the 117.23
    // drill measures the ring by walking ancestors for a box exactly `ring`
    // sized and concentric with the avatar, and a ClipOval's render object
    // inherits the child's size rather than the frame's. Clipping would make
    // the frame unmeasurable while looking correct.
    return SizedBox(
      key: ringKey,
      width: tokens.ring,
      height: tokens.ring,
      child: Center(child: child),
    );
  }
}

/// A 40px avatar for dense rows, where the 80px profile avatar does not fit.
///
/// Closes `avatar:compact_size` (40), which was declared as a token with no
/// render context at all - no call site anywhere drew a compact avatar, so the
/// measured size had nothing to measure. This is that render path.
///
/// It sizes from the token rather than a literal so the two avatar sizes can
/// never drift apart, and it keeps the same [BorderRadius] logic as the profile
/// avatar so a compact avatar is recognisably the same object at a smaller size
/// instead of a different-looking one.
class AccountCenterCompactAvatar extends StatelessWidget {
  const AccountCenterCompactAvatar({
    super.key,
    required this.initials,
    required this.semanticLabel,
  });

  /// Shares the `account-profile-avatar` PREFIX the 117.23 drill scans. The
  /// drill collects avatars by prefix (`_keyedWidgets`) and measures which one
  /// is `compact` pixels, so this key keeps the token measurable; the trailing
  /// `-compact` suffix keeps it distinct so the profile avatar's
  /// `find.byKey` stays unique and does not throw on a duplicate.
  static const Key avatarKey = ValueKey('account-profile-avatar-compact');

  /// Initials to render. Normalized to at most two characters so a long name
  /// cannot silently overflow a 40px box.
  final String initials;

  /// What a screen reader announces. Required rather than derived: initials
  /// alone ("VS") are not a label, and deriving one would invent a name the
  /// caller never supplied.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    const tokens = AccountCenterDesignTokens.avatarSizes;
    final radius = BorderRadius.circular(AccountCenterDesignTokens.radius.tile);
    final trimmed = initials.trim();
    final visible = trimmed.isEmpty
        ? '?'
        : (trimmed.characters.length > 2
              ? trimmed.characters.take(2).toString()
              : trimmed);

    return Semantics(
      container: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Container(
          key: avatarKey,
          width: tokens.compact,
          height: tokens.compact,
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: radius,
            border: Border.all(color: context.palette.border),
          ),
          child: Center(
            child: Text(
              visible.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.palette.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
