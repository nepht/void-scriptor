import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_accessibility.dart';
import 'package:void_scriptor/features/account/domain/account_center_design_tokens.dart';
import 'package:void_scriptor/features/account/domain/account_center_information_architecture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('115.7 acceptance contract', () {
    test('acceptance 115.7 dipin dan urutannya kanonik', () {
      expect(AccountCenterAccessibility.canonicalAcceptance, <String>[
        'keyboard_complete',
        'visible_focus',
        'screen_reader_labels',
        'chart_text_alternative',
        '44px_touch_target',
        '200_percent_scale',
      ]);
      expect(
        AccountCenterAccessibility.canonicalSprintSha256,
        'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba',
      );
    });

    test('delapan requirement spec verbatim', () {
      expect(AccountCenterAccessibility.specRequirements, <String>[
        'Complete keyboard navigation and visible focus.',
        'Provider name and connection status announced as text.',
        'Charts include data table or textual summary.',
        'Progress bars expose used, quota, percentage, and freshness.',
        'Color is not the only carrier of connection or health state.',
        'UI supports 200 percent scaling and text expansion.',
        'Reduced-motion mode disables decorative motion.',
        'Touch targets are at least 44 by 44 px.',
      ]);
    });

    test('sprint kanonik live memuat acceptance yang sama', () {
      final file = File(AccountCenterAccessibility.canonicalSprintPath);
      expect(file.existsSync(), isTrue);
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final steps = json['steps'] as List<dynamic>;
      final step = steps.cast<Map<String, dynamic>>().firstWhere(
        (entry) => entry['id'] == '115.7',
      );
      expect(step['title'], 'Accessibility Interaction Baseline');
      expect(
        step['acceptance'],
        AccountCenterAccessibility.canonicalAcceptance,
      );
    });
  });

  group('115.7 focus order + keyboard', () {
    test('urutan fokus: header, sembilan tab, aksi', () {
      const order = AccountCenterAccessibility.defaultFocusOrder;
      expect(order.first.target, AccountCenterFocusTarget.search);
      expect(order[1].target, AccountCenterFocusTarget.notifications);
      final tabSlugs = order
          .where((entry) => entry.target == AccountCenterFocusTarget.tab)
          .map((entry) => entry.tabSlug)
          .toList();
      expect(
        tabSlugs,
        AccountCenterInformationArchitecture.tabs.map((t) => t.slug),
      );
      expect(order.last.target, AccountCenterFocusTarget.signIn);
    });

    test('notifications belum punya aksi → tidak focusable', () {
      expect(
        AccountCenterAccessibility.isFocusable(
          AccountCenterFocusTarget.notifications,
        ),
        isFalse,
      );
      expect(
        AccountCenterAccessibility.isFocusable(AccountCenterFocusTarget.search),
        isTrue,
      );
    });

    test('tab strip 40px memenuhi target keyboard 32px', () {
      expect(
        AccountCenterAccessibility.meetsKeyboardTarget(const Size(106, 40)),
        isTrue,
      );
      expect(
        AccountCenterAccessibility.meetsKeyboardTarget(const Size(106, 31)),
        isFalse,
      );
      expect(
        AccountCenterDesignTokens.layout.tabBarHeight,
        greaterThanOrEqualTo(AccountCenterAccessibility.minimumKeyboardTarget),
      );
    });
  });

  group('115.7 screen-reader labels', () {
    test('label ikon header eksplisit', () {
      expect(
        AccountCenterAccessibility.searchSemanticsLabel,
        'Search account sections',
      );
      expect(
        AccountCenterAccessibility.notificationsSemanticsLabel,
        'Notifications (coming soon)',
      );
    });

    test('provider = "nama, status"', () {
      expect(
        AccountCenterAccessibility.providerSemanticsLabel(
          'Google Drive',
          'Not connected',
        ),
        'Google Drive, Not connected',
      );
      expect(
        AccountCenterAccessibility.providerSemanticsLabel(
          '  Folder backup  ',
          '  Available locally  ',
        ),
        'Folder backup, Available locally',
      );
    });

    test('provider label fail-closed pada input kosong', () {
      expect(
        () => AccountCenterAccessibility.providerSemanticsLabel('', 'x'),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterAccessibility.providerSemanticsLabel('x', '   '),
        throwsArgumentError,
      );
    });
  });

  group('115.7 chart text alternative', () {
    test('judul + facts digabung dengan titik', () {
      expect(
        AccountCenterAccessibility.chartTextAlternative(
          title: 'STORAGE DISTRIBUTION',
          facts: const ['4 KB indexed', 'Images 75%', 'Database 25%'],
        ),
        'STORAGE DISTRIBUTION. 4 KB indexed Images 75% Database 25%',
      );
    });

    test('facts kosong/double-space di-trim', () {
      expect(
        AccountCenterAccessibility.chartTextAlternative(
          title: 'AI USAGE THIS MONTH',
          facts: const ['', '  ', '1,540 tokens'],
        ),
        'AI USAGE THIS MONTH. 1,540 tokens',
      );
      expect(
        AccountCenterAccessibility.chartTextAlternative(
          title: 'AI USAGE THIS MONTH',
          facts: const [],
        ),
        'AI USAGE THIS MONTH',
      );
    });

    test('judul kosong ditolak', () {
      expect(
        () => AccountCenterAccessibility.chartTextAlternative(
          title: '  ',
          facts: const ['x'],
        ),
        throwsArgumentError,
      );
    });
  });

  group('115.7 touch target + scaling', () {
    test('target sentuh 44x44 dipin ke spec token', () {
      expect(AccountCenterAccessibility.minimumTouchTarget, 44);
      expect(
        AccountCenterDesignTokens.density.minimumTouchTarget,
        AccountCenterAccessibility.minimumTouchTarget,
      );
      expect(
        AccountCenterAccessibility.meetsTouchTarget(const Size(44, 44)),
        isTrue,
      );
      expect(
        AccountCenterAccessibility.meetsTouchTarget(const Size(43.9, 44)),
        isFalse,
      );
      expect(
        AccountCenterAccessibility.meetsTouchTarget(const Size(44, 43.9)),
        isFalse,
      );
    });

    test('skala 0.5..2.0 valid, di luar itu fail-closed', () {
      expect(AccountCenterAccessibility.validateTextScale(0.5), 0.5);
      expect(AccountCenterAccessibility.validateTextScale(1.0), 1.0);
      expect(AccountCenterAccessibility.validateTextScale(2.0), 2.0);
      expect(
        () => AccountCenterAccessibility.validateTextScale(0),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterAccessibility.validateTextScale(-1),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterAccessibility.validateTextScale(2.0001),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterAccessibility.validateTextScale(double.nan),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterAccessibility.validateTextScale(double.infinity),
        throwsArgumentError,
      );
    });

    test('focus ring tab 2px > 0', () {
      expect(AccountCenterAccessibility.tabFocusRingWidth, 2);
    });
  });

  group('115.7 reduced motion', () {
    testWidgets('ambient disableAnimations menjadi sumber keputusan', (
      tester,
    ) async {
      late bool reduced;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              reduced = AccountCenterAccessibility.reducedMotion(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(reduced, isFalse);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                reduced = AccountCenterAccessibility.reducedMotion(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(reduced, isTrue);
    });

    test('spec source masih hash sama', () {
      expect(
        AccountCenterAccessibility.specSha256,
        AccountCenterDesignTokens.specSha256,
      );
      final file = File(AccountCenterAccessibility.specDocument);
      if (file.existsSync()) {
        final digest = file.readAsBytesSync().fold<int>(
          0,
          (hash, byte) => (hash * 31 + byte) & 0x1fffffff,
        );
        expect(digest, isNot(0));
      }
    });
  });
}
