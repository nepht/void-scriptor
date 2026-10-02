import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_design_tokens.dart';
import 'package:void_scriptor/features/account/presentation/account_center_avatar_ring.dart';

/// Closes the `avatar:ring_size` and `avatar:compact_size` open items from
/// 117.23. Both tokens were declared and both were measurable, yet nothing on
/// the reference screen drew either one, so the validation drill reported them
/// `unmet` rather than folding them into a pass.
///
/// These tests measure rendered geometry, not declarations: a token that is
/// merely declared proves nothing, and the failure these guard against is
/// exactly a widget that ignores the token and hardcodes a size that happens to
/// match today.
void main() {
  const tokens = AccountCenterDesignTokens.avatarSizes;

  Future<void> pumpRing(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: AccountCenterAvatarRing(child: child)),
        ),
      ),
    );
  }

  group('AccountCenterAvatarRing renders the declared ring size', () {
    testWidgets('the ring box measures exactly the ring token', (tester) async {
      await pumpRing(tester, const SizedBox(width: 80, height: 80));

      final rect = tester.getRect(find.byKey(AccountCenterAvatarRing.ringKey));

      expect(rect.width, tokens.ring);
      expect(rect.height, tokens.ring);
    });

    testWidgets('the ring is concentric with the avatar it wraps', (
      tester,
    ) async {
      await pumpRing(
        tester,
        const SizedBox(key: ValueKey('inner'), width: 80, height: 80),
      );

      final ring = tester.getRect(find.byKey(AccountCenterAvatarRing.ringKey));
      final inner = tester.getRect(find.byKey(const ValueKey('inner')));

      expect((ring.center.dx - inner.center.dx).abs(), lessThanOrEqualTo(0.5));
      expect((ring.center.dy - inner.center.dy).abs(), lessThanOrEqualTo(0.5));
      expect(ring.width, greaterThan(inner.width));
    });

    testWidgets('the ring is addressable without walking ancestors', (
      tester,
    ) async {
      await pumpRing(tester, const SizedBox(width: 80, height: 80));

      expect(find.byKey(AccountCenterAvatarRing.ringKey), findsOneWidget);
    });

    testWidgets('the ring token is distinguishable from the image token', (
      tester,
    ) async {
      // The failure this guards against is a ring that silently reads
      // `image` (80) or a hardcoded 96. Since the token set is a const, the
      // meaningful witness is that the ring size is not the image size: if the
      // ring were wired to the wrong token, these would be equal and this test
      // would have caught it at authoring time.
      expect(tokens.ring, isNot(tokens.image));
      await pumpRing(tester, const SizedBox(width: 80, height: 80));
      final rect = tester.getRect(find.byKey(AccountCenterAvatarRing.ringKey));
      expect(rect.width, isNot(tokens.image));
      expect(rect.width, tokens.ring);
    });

    testWidgets('a wide child cannot paint outside the ring frame', (
      tester,
    ) async {
      await pumpRing(tester, const SizedBox(width: 400, height: 400));

      final ring = tester.getRect(find.byKey(AccountCenterAvatarRing.ringKey));

      expect(ring.width, tokens.ring);
      expect(ring.height, tokens.ring);
    });
  });

  group('AccountCenterCompactAvatar renders the declared compact size', () {
    Future<void> pumpCompact(
      WidgetTester tester, {
      String initials = 'CS',
      String label = 'Email account',
    }) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AccountCenterCompactAvatar(
              initials: initials,
              semanticLabel: label,
            ),
          ),
        ),
      ),
    );

    testWidgets('the compact avatar measures exactly the compact token', (
      tester,
    ) async {
      await pumpCompact(tester);

      final rect = tester.getRect(
        find.byKey(AccountCenterCompactAvatar.avatarKey),
      );

      expect(rect.width, tokens.compact);
      expect(rect.height, tokens.compact);
    });

    testWidgets('it is smaller than the profile avatar', (tester) async {
      await pumpCompact(tester);

      final rect = tester.getRect(
        find.byKey(AccountCenterCompactAvatar.avatarKey),
      );

      expect(rect.width, lessThan(tokens.image));
      expect(rect.width, lessThan(tokens.ring));
    });

    testWidgets('it announces the supplied label, not bare initials', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpCompact(
        tester,
        initials: 'CS',
        label: 'Email account choirudin@x',
      );

      expect(
        find.bySemanticsLabel('Email account choirudin@x'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('a long value is trimmed to two characters', (tester) async {
      await pumpCompact(tester, initials: 'Choirudin');

      final text = tester.widget<Text>(
        find.descendant(
          of: find.byKey(AccountCenterCompactAvatar.avatarKey),
          matching: find.byType(Text),
        ),
      );

      expect(text.data, 'CH');
    });

    testWidgets('a blank value renders a placeholder, not an empty box', (
      tester,
    ) async {
      await pumpCompact(tester, initials: '   ');

      final text = tester.widget<Text>(
        find.descendant(
          of: find.byKey(AccountCenterCompactAvatar.avatarKey),
          matching: find.byType(Text),
        ),
      );

      expect(text.data, '?');
    });

    testWidgets('the compact avatar stays exact under a large text scale', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
                child: const AccountCenterCompactAvatar(
                  initials: 'CS',
                  semanticLabel: 'Email account',
                ),
              ),
            ),
          ),
        ),
      );

      // Text scaling must not change the box: the token is a layout contract,
      // not a text metric, so the avatar stays 40px even at 200%.
      final rect = tester.getRect(
        find.byKey(AccountCenterCompactAvatar.avatarKey),
      );
      expect(rect.width, tokens.compact);
      expect(rect.height, tokens.compact);
      handle.dispose();
    });
  });
}
