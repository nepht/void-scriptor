enum ProfileAvatarKind { none, image, initials }

class ProfileAvatar {
  const ProfileAvatar._(this.kind, this.value);

  const ProfileAvatar.none() : this._(ProfileAvatarKind.none, null);
  const ProfileAvatar.image(String assetId)
    : this._(ProfileAvatarKind.image, assetId);
  const ProfileAvatar.initials(String value)
    : this._(ProfileAvatarKind.initials, value);

  final ProfileAvatarKind kind;
  final String? value;

  Map<String, Object?> toJson() => {'kind': kind.name, 'value': value};
}

enum AccountPlan { free, pro, team, enterprise }

enum SignInMethod { email, google, github, apple }

enum AccountProfileState {
  active,
  signedOut,
  reauthRequired,
  suspended,
  offline,
}

class AuthenticationProfileCard {
  AuthenticationProfileCard({
    required this.avatar,
    required String displayName,
    required String email,
    required this.plan,
    required Iterable<SignInMethod> signInMethods,
    required this.primaryIdentity,
    required this.accountState,
  }) : displayName = _required(displayName, 'displayName'),
       email = _required(email, 'email'),
       signInMethods = Set.unmodifiable(signInMethods) {
    if (this.signInMethods.isEmpty) {
      throw ArgumentError.value(signInMethods, 'signInMethods');
    }
    if (!this.signInMethods.contains(primaryIdentity)) {
      throw ArgumentError.value(primaryIdentity, 'primaryIdentity');
    }
  }

  AuthenticationProfileCard.authenticated({
    required ProfileAvatar avatar,
    required String displayName,
    required String email,
    required AccountPlan plan,
    required Iterable<SignInMethod> signInMethods,
    required SignInMethod primaryIdentity,
  }) : this(
         avatar: avatar,
         displayName: displayName,
         email: email,
         plan: plan,
         signInMethods: signInMethods,
         primaryIdentity: primaryIdentity,
         accountState: AccountProfileState.active,
       );

  final ProfileAvatar avatar;
  final String displayName;
  final String email;
  final AccountPlan plan;
  final Set<SignInMethod> signInMethods;
  final SignInMethod primaryIdentity;
  final AccountProfileState accountState;

  static String _required(String value, String field) {
    final normalized = value.trim();
    if (normalized.isEmpty) throw ArgumentError.value(value, field);
    return normalized;
  }
}

class EditProfileRequest {
  EditProfileRequest({required String displayName, required String email})
    : displayName = _required(displayName, 'displayName'),
      email = _required(email, 'email');

  final String displayName;
  final String email;

  static String _required(String value, String field) {
    final normalized = value.trim();
    if (normalized.isEmpty) throw ArgumentError.value(value, field);
    return normalized;
  }
}
