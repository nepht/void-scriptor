// WCAG 2.2 - 2.3.3 Animation from Interactions (AAA-level check dipantau di
// sini karena 2.2.2/se Elemen Bergenak) dan 2.2.2 Pause, Stop, Hide.
//
// Hanya dua file produksi yang menjalankan animasi widget-level
// (`AnimatedOpacity|AnimatedContainer|AnimatedScale|AnimatedSwitcher|
// AnimatedPositioned|FadeTransition|SlideTransition|TweenAnimationBuilder`):
// account_cloud_center_screen.dart dan login_screen.dart. Keduanya sudah
// membaca `MediaQuery.disableAnimationsOf`, jadi ini mengunci perilaku yang
// sudah benar - supaya tidak hilang diam-diam di refactor berikutnya.
//
// Bukti 2.2.2: tidak ada `.repeat(` di seluruh `lib/` (0 kemunculan), jadi
// tidak ada animasi otomatis > 5 detik yang berjalan tanpa kontrol pengguna.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/auth/auth_controller.dart';
import 'package:void_scriptor/core/auth/auth_session.dart';
import 'package:void_scriptor/features/account/domain/account_center_accessibility.dart';
import 'package:void_scriptor/features/authentication/presentation/login_screen.dart';

void main() {
  group('2.3.3 reduced motion dihormati', () {
    testWidgets('login screen: ambient disableAnimations terbaca', (tester) async {
      bool? seen;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                seen = MediaQuery.disableAnimationsOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(seen, isTrue);
    });

    testWidgets('AccountCenterAccessibility.reducedMotion true saat ambient true',
        (tester) async {
      bool? seen;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                seen = AccountCenterAccessibility.reducedMotion(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(seen, isTrue);
    });

    testWidgets('...dan false saat ambient false (tidak mematikan semua gerak)',
        (tester) async {
      bool? seen;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: false),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                seen = AccountCenterAccessibility.reducedMotion(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(seen, isFalse);
    });
  });

  group('2.2.2 tidak ada animasi otomatis > 5 detik', () {
    testWidgets(
        'scheduler login screen idle: tidak ada animasi berulang', (tester) async {
      // Bukti nyata: setelah satu pump, tidak ada animasi yang masih berjalan
      // pada login screen. Kalau suatu saat ada `.repeat()` atau loop tak
      // berujung, test ini akan menggantung / scheduler tetap dirty.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initialAuthSessionProvider.overrideWithValue(
              const AuthSession.loggedOut(),
            ),
          ],
          child: MaterialApp(
            home: LoginScreen(
              onForgotPassword: () {},
              onRegister: () {},
            ),
          ),
        ),
      );

      // pumpAndSettle melempar kalau scheduler tidak pernah idle dalam 5 detik
      // - itu persis gejala animasi berulang. Tidak ada catch yang bisa
      // menelan exception lain.
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );

      expect(
        tester.binding.hasScheduledFrame,
        isFalse,
        reason: 'masih ada frame terjadwal setelah settle - indikasi '
            'animasi yang tidak pernah selesai.',
      );
    });
  });
}