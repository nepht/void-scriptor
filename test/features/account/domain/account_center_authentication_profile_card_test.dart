import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_authentication_profile_card.dart';

void main() {
  group('115.13 authentication and profile card', () {
    test('authenticated profile exposes identity, plan, methods, and active state', () {
      final profile = AuthenticationProfileCard.authenticated(
        avatar: const ProfileAvatar.initials('VC'),
        displayName: 'Verified Creator',
        email: 'verified@example.com',
        plan: AccountPlan.pro,
        signInMethods: const [SignInMethod.email, SignInMethod.google],
        primaryIdentity: SignInMethod.email,
      );

      expect(profile.avatar.kind, ProfileAvatarKind.initials);
      expect(profile.avatar.value, 'VC');
      expect(profile.displayName, 'Verified Creator');
      expect(profile.email, 'verified@example.com');
      expect(profile.plan, AccountPlan.pro);
      expect(profile.signInMethods, containsAll([SignInMethod.email, SignInMethod.google]));
      expect(profile.primaryIdentity, SignInMethod.email);
      expect(profile.accountState, AccountProfileState.active);
    });

    test('avatar states and account states are explicit and serializable', () {
      expect(const ProfileAvatar.none().toJson(), {
        'kind': 'none',
        'value': null,
      });
      expect(const ProfileAvatar.image('avatar-id').toJson(), {
        'kind': 'image',
        'value': 'avatar-id',
      });
      expect(const ProfileAvatar.initials('AB').toJson(), {
        'kind': 'initials',
        'value': 'AB',
      });
      expect(AccountProfileState.values.map((state) => state.name), {
        'active',
        'signedOut',
        'reauthRequired',
        'suspended',
        'offline',
      });
    });

    test('edit profile request trims fields and rejects invalid identity', () {
      final request = EditProfileRequest(
        displayName: '  Creator  ',
        email: ' creator@example.com ',
      );

      expect(request.displayName, 'Creator');
      expect(request.email, 'creator@example.com');
      expect(
        () => EditProfileRequest(displayName: ' ', email: 'creator@example.com'),
        throwsArgumentError,
      );
      expect(
        () => EditProfileRequest(displayName: 'Creator', email: ' '),
        throwsArgumentError,
      );
    });
  });
}
