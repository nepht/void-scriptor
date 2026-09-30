// Sprint 117.19 — member removal and membership governance for StudioRegistry.
//
// The external product spec that pins the Account & Cloud Center declares
// `remove_team_member` among its `sensitive_actions` and declares
// `reauth_before_sensitive_action` and `audit_redaction` alongside it. Before
// this suite the seam honoured none of the three: `removeMember` took no actor,
// consulted no permission, and asked nobody whether the user was still there.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/enterprise/license/seat_license.dart';
import 'package:void_scriptor/core/enterprise/role/permission.dart';
import 'package:void_scriptor/core/enterprise/role/studio_role.dart';
import 'package:void_scriptor/core/enterprise/registry/studio_registry.dart';
import 'package:void_scriptor/core/enterprise/studio/studio.dart';

StudioRegistry _registry({int maxSeats = 4}) => StudioRegistry(
  studio: const Studio(id: 'st1', name: 'Void Studio', plan: 'enterprise'),
  seats: SeatLicense(maxSeats: maxSeats),
);

void main() {
  group('117.19 membership identity', () {
    test('a user id can occupy exactly one seat', () {
      final registry = _registry();

      expect(registry.addMember(userId: 'u1', role: StudioRole.admin), isTrue);
      // The same person added twice is one member, not two.
      expect(
        registry.addMember(userId: 'u1', role: StudioRole.viewer),
        isFalse,
      );

      expect(registry.members.map((member) => member.userId), <String>['u1']);
      expect(registry.seats.usedSeats, 1);
    });

    test('a refused add is audited rather than silently dropped', () {
      final registry = _registry(maxSeats: 1);
      registry.addMember(userId: 'u1', role: StudioRole.admin);

      expect(
        registry.addMember(userId: 'u2', role: StudioRole.viewer),
        isFalse,
      );
      expect(registry.audit.byAction('add-member'), hasLength(1));
      expect(registry.audit.byAction('denied_add_member'), hasLength(1));
    });
  });

  group('117.19 member removal is a gated sensitive action', () {
    test(
      'removal requires reauthentication and defaults to refusing',
      () async {
        final registry = _registry();
        registry.addMember(userId: 'owner', role: StudioRole.admin);
        registry.addMember(userId: 'bob', role: StudioRole.member);

        // No gate supplied at all: the seam must fail closed.
        expect(
          await registry.removeMember('bob', actor: 'owner'),
          isFalse,
          reason: 'a removal with no reauthentication gate must be refused',
        );
        expect(
          registry.members.map((member) => member.userId),
          contains('bob'),
        );
        expect(registry.seats.usedSeats, 2);

        // A gate that refuses is a refusal, not a technical failure.
        expect(
          await registry.removeMember(
            'bob',
            actor: 'owner',
            reauthenticate: () async => false,
          ),
          isFalse,
        );
        expect(
          registry.members.map((member) => member.userId),
          contains('bob'),
        );
        expect(registry.seats.usedSeats, 2);

        // A gate that agrees lets the removal through.
        expect(
          await registry.removeMember(
            'bob',
            actor: 'owner',
            reauthenticate: () async => true,
          ),
          isTrue,
        );
        expect(
          registry.members.map((member) => member.userId),
          isNot(contains('bob')),
        );
        expect(registry.seats.usedSeats, 1);
      },
    );

    test('only a member who may manage members may remove one', () async {
      final registry = _registry();
      registry.addMember(userId: 'admin', role: StudioRole.admin);
      registry.addMember(userId: 'ed', role: StudioRole.member);
      registry.addMember(userId: 'bob', role: StudioRole.viewer);

      // A non-member cannot remove anybody.
      expect(
        await registry.removeMember(
          'bob',
          actor: 'stranger',
          reauthenticate: () async => true,
        ),
        isFalse,
      );
      // A member without the manage-members permission cannot either.
      expect(
        await registry.removeMember(
          'bob',
          actor: 'ed',
          reauthenticate: () async => true,
        ),
        isFalse,
      );
      // The permission itself is the one the matrix defines for this.
      expect(StudioRole.member.can(Permission.manageMembers), isFalse);
      expect(StudioRole.admin.can(Permission.manageMembers), isTrue);

      expect(
        await registry.removeMember(
          'bob',
          actor: 'admin',
          reauthenticate: () async => true,
        ),
        isTrue,
      );
    });

    test('a refused removal is audited with the actor that asked', () async {
      final registry = _registry();
      registry.addMember(userId: 'admin', role: StudioRole.admin);
      registry.addMember(userId: 'bob', role: StudioRole.member);

      await registry.removeMember('ghost', actor: 'admin');

      final denials = registry.audit.byAction('denied_remove_member');
      expect(denials, hasLength(1));
      expect(denials.single.actor, 'admin');
      expect(denials.single.target, 'ghost');
      expect(registry.audit.byAction('remove-member'), isEmpty);
    });

    test(
      'a successful removal attributes the actor that performed it',
      () async {
        final registry = _registry();
        registry.addMember(userId: 'admin', role: StudioRole.admin);
        registry.addMember(userId: 'bob', role: StudioRole.member);

        await registry.removeMember(
          'bob',
          actor: 'admin',
          reauthenticate: () async => true,
        );

        final removals = registry.audit.byAction('remove-member');
        expect(removals, hasLength(1));
        expect(removals.single.actor, 'admin');
        expect(removals.single.target, 'bob');
      },
    );

    test('an organization keeps at least one administrator', () async {
      final registry = _registry();
      registry.addMember(userId: 'admin', role: StudioRole.admin);
      registry.addMember(userId: 'bob', role: StudioRole.member);

      expect(
        await registry.removeMember(
          'admin',
          actor: 'admin',
          reauthenticate: () async => true,
        ),
        isFalse,
        reason: 'removing the only administrator would orphan the organization',
      );
      expect(
        registry.members.where((member) => member.role == StudioRole.admin),
        hasLength(1),
      );

      // Once a second administrator exists, either may step down.
      registry.addMember(userId: 'admin2', role: StudioRole.admin);
      expect(
        await registry.removeMember(
          'admin',
          actor: 'admin2',
          reauthenticate: () async => true,
        ),
        isTrue,
      );
    });

    test('audit rows carry no permission or credential material', () async {
      final registry = _registry();
      registry.addMember(userId: 'owner', role: StudioRole.admin);
      registry.addMember(userId: 'bob', role: StudioRole.member);
      await registry.removeMember(
        'bob',
        actor: 'owner',
        reauthenticate: () async => true,
      );
      await registry.removeMember('ghost', actor: 'owner');

      final fields = <String>{
        for (final event in registry.audit.events) ...<String>[
          event.actor,
          event.action,
          event.target,
        ],
      };
      // The role a member holds is a permission decision, and a secret is a
      // secret: neither belongs in an audit row. Compared field by field
      // rather than by substring, because `member` is also half of the action
      // name `remove-member` and a substring test here could never fail.
      for (final forbidden in <String>[
        ...StudioRole.values.map((role) => role.name),
        ...Permission.values.map((permission) => permission.name),
        'reauthenticate',
      ]) {
        expect(
          fields,
          isNot(contains(forbidden)),
          reason: 'an audit row must not carry "$forbidden"',
        );
      }
      // What a row must carry: who did it, what they tried, to whom.
      expect(fields, containsAll(<String>['owner', 'bob', 'ghost']));
      expect(registry.audit.byAction('remove-member'), hasLength(1));
      expect(registry.audit.byAction('denied_remove_member'), hasLength(1));
    });
  });
}
