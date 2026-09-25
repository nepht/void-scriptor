import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/application/account_operational_metrics.dart';
import 'package:void_scriptor/features/account/domain/account_center_accessibility.dart';
import 'package:void_scriptor/features/account/domain/account_center_information_architecture.dart';
import 'package:void_scriptor/features/account/presentation/account_cloud_center_screen.dart';

/// 115.7 — Accessibility Interaction Baseline: bukti screen Account & Cloud
/// Center benar-benar memakai kontrak aksesibilitas (bukan hanya punya file).
///
/// Cakupan lokal: traversal keyboard + fokus terlihat, Semantics label ikon
/// header, provider "nama + status", alternatif teks chart, target sentuh 44,
/// dan render 200% pada mobile + reference. Sertifikasi screen reader native,
/// kontras terukur, dan audit seluruh surface tetap 115.48.
void main() {
  Future<void> pumpCenter(
    WidgetTester tester, {
    Size size = const Size(1536, 1024),
    double textScale = 1.0,
    AccountOperationalMetrics? metrics,
    void Function()? onSignIn,
    String? initialTab,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (metrics != null)
            accountOperationalMetricsProvider.overrideWith(
              (ref) async => metrics,
            ),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: AccountCloudCenterScreen(
              operationalMetrics: metrics,
              initialTab: initialTab,
              onSignIn: onSignIn ?? () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder tabInk(String label) =>
      find.ancestor(of: find.text(label), matching: find.byType(InkWell)).first;

  group('115.7 keyboard_complete + visible_focus', () {
    testWidgets('Tab melewati header lalu sembilan tab lalu aksi sign-in', (
      tester,
    ) async {
      await pumpCenter(tester);
      final search = find.widgetWithIcon(IconButton, Icons.search);
      final notifications = find.widgetWithIcon(
        IconButton,
        Icons.notifications_none,
      );
      final signIn = find.widgetWithText(
        OutlinedButton,
        'Sign in or connect account',
      );

      // Header search adalah stop fokus pertama.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(tester.getRect(search).overlaps(_focusRect(tester)), isTrue);

      // Notifications belum punya aksi → tidak boleh menjadi keyboard stop.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focusedRect = _focusRect(tester);
      expect(
        focusedRect.overlaps(tester.getRect(notifications)),
        isFalse,
        reason: 'notifikasi disabled-by-design bukan focus stop',
      );

      // Sembilan tab berikutnya mengikuti urutan IA kanonik.
      final tabLabels = AccountCenterInformationArchitecture.tabs
          .map((tab) => tab.label)
          .toList();
      for (var index = 0; index < tabLabels.length; index++) {
        final rect = _focusRect(tester);
        expect(
          rect.overlaps(tester.getRect(tabInk(tabLabels[index]))),
          isTrue,
          reason: 'fokus #${index + 3} harus tab ${tabLabels[index]}',
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }

      // Setelah tab terakhir: aksi sign-in.
      expect(_focusRect(tester).overlaps(tester.getRect(signIn)), isTrue);
    });

    testWidgets('Enter pada tab terfokus memindah tab, fokus tidak nyangkut', (
      tester,
    ) async {
      await pumpCenter(tester);
      // search → Overview → Connected Accounts.
      final search = find.widgetWithIcon(IconButton, Icons.search);
      for (final stop in const ['Search', 'Overview', 'Connected Accounts']) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final rect = _focusRect(tester);
        final target = stop == 'Search'
            ? tester.getRect(search)
            : tester.getRect(tabInk(stop));
        expect(rect.overlaps(target), isTrue, reason: 'fokus harus $stop');
      }

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('ACCOUNT ACCESS'), findsOneWidget);
      // Tab aktif switched ke Connected Accounts.
      final activeSemantics = tester
          .getSemantics(tabInk('Connected Accounts'))
          .getSemanticsData();
      expect(
        activeSemantics.flagsCollection.isSelected == Tristate.isTrue,
        isTrue,
      );
      // Fokus tidak nyangkut di konten lama (Overview cards hilang).
      expect(find.text('QUICK CONNECT'), findsNothing);
    });

    testWidgets('fokus terlihat: focus ring 2px + Semantics isFocused', (
      tester,
    ) async {
      await pumpCenter(tester);
      BoxDecoration focusRing() =>
          tester
                  .widget<AnimatedContainer>(
                    find
                        .descendant(
                          of: tabInk('Overview'),
                          matching: find.byType(AnimatedContainer),
                        )
                        .first,
                  )
                  .decoration!
              as BoxDecoration;

      final before = focusRing();
      expect(
        _borderWidth(before),
        AccountCenterAccessibility.tabFocusRingWidth,
      );
      expect(
        _borderColor(before),
        Colors.transparent,
        reason: 'belum fokus → ring transparan',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final focusedSemantics = tester
          .getSemantics(tabInk('Overview'))
          .getSemanticsData();
      expect(
        focusedSemantics.flagsCollection.isFocused == Tristate.isTrue,
        isTrue,
      );
      expect(
        focusedSemantics.flagsCollection.isSelected == Tristate.isTrue,
        isTrue,
        reason: 'tab aktif diumumkan selected',
      );
      // Focus ring berubah dari transparent ke primaryBright.
      final after = focusRing();
      expect(
        _borderColor(after),
        isNot(Colors.transparent),
        reason: 'focus ring harus terlihat',
      );
      expect(_borderWidth(after), AccountCenterAccessibility.tabFocusRingWidth);
    });
  });

  group('115.7 screen_reader_labels', () {
    testWidgets('ikon header punya Semantics label eksplisit', (tester) async {
      await pumpCenter(tester);
      expect(
        find.bySemanticsLabel(AccountCenterAccessibility.searchSemanticsLabel),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          AccountCenterAccessibility.notificationsSemanticsLabel,
        ),
        findsOneWidget,
      );
    });

    testWidgets('provider diumumkan sebagai satu node "nama, status"', (
      tester,
    ) async {
      await pumpCenter(tester);
      // QUICK CONNECT overview: tiga provider cloudStorage.
      expect(
        find.bySemanticsLabel('Google Drive, Not connected'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('OneDrive, Not connected'), findsOneWidget);
      expect(find.bySemanticsLabel('Dropbox, Not connected'), findsOneWidget);

      // Status lokal "Available locally" pada tab Backup & Sync (dirender lewat
      // initialTab; tab strip horizontal, tab ke-8 berada di luar viewport
      // 1536 sehingga tidak di-tap lewat pointer).
      await pumpCenter(tester, initialTab: 'backup_sync');
      expect(
        find.bySemanticsLabel('Folder backup, Available locally'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Cloud sync, Not connected'),
        findsOneWidget,
      );
    });
  });

  group('115.7 chart_text_alternative', () {
    const metrics = AccountOperationalMetrics(
      promptTokens: 1200,
      completionTokens: 340,
      estimatedCost: 1.25,
      totalStorageBytes: 4096,
      storageBytesByCategory: {'Images': 3072, 'Database': 1024},
    );

    testWidgets('kedua chart punya alternatif teks dari data nyata', (
      tester,
    ) async {
      await pumpCenter(tester, metrics: metrics);
      final usage = AccountCenterAccessibility.chartTextAlternative(
        title: 'AI USAGE THIS MONTH',
        facts: const ['1,540 tokens', r'$1.25 estimated'],
      );
      final storage = AccountCenterAccessibility.chartTextAlternative(
        title: 'STORAGE DISTRIBUTION',
        facts: const ['4 KB indexed', 'Images 75%', 'Database 25%'],
      );
      expect(find.bySemanticsLabel(usage), findsOneWidget);
      expect(find.bySemanticsLabel(storage), findsOneWidget);
    });

    testWidgets('chart tanpa data tetap punya judul sebagai alternatif', (
      tester,
    ) async {
      await pumpCenter(tester);
      expect(find.bySemanticsLabel('AI USAGE THIS MONTH'), findsOneWidget);
      expect(find.bySemanticsLabel('STORAGE DISTRIBUTION'), findsOneWidget);
    });
  });

  group('115.7 44px_touch_target', () {
    testWidgets('semua target actionable >= 44x44', (tester) async {
      await pumpCenter(tester);
      final targets = <String, Finder>{
        'icon search': find.widgetWithIcon(IconButton, Icons.search),
        'sign-in': find.widgetWithText(
          OutlinedButton,
          'Sign in or connect account',
        ),
        'quick action row': find
            .ancestor(
              of: find.text('Backup Project'),
              matching: find.byType(ListTile),
            )
            .first,
        'tab strip': tabInk('Overview'),
      };
      targets.forEach((name, finder) {
        final size = tester.getSize(finder);
        expect(
          size.height,
          greaterThanOrEqualTo(
            AccountCenterAccessibility.minimumKeyboardTarget,
          ),
          reason: '$name tinggi ${size.height}',
        );
        if (name != 'tab strip') {
          expect(
            AccountCenterAccessibility.meetsTouchTarget(size),
            isTrue,
            reason: '$name size $size < 44x44',
          );
        }
      });

      // Dialog search: tombol Close harus >= 44 tinggi (target sentuh).
      await tester.tap(find.widgetWithIcon(IconButton, Icons.search));
      await tester.pumpAndSettle();
      final close = find.widgetWithText(TextButton, 'Close');
      expect(
        AccountCenterAccessibility.meetsTouchTarget(tester.getSize(close)),
        isTrue,
        reason: 'Close dialog ${tester.getSize(close)}',
      );
    });
  });

  group('115.7 200_percent_scale', () {
    for (final entry in <({String name, Size size})>[
      (name: 'mobile 390x844 @200%', size: const Size(390, 844)),
      (name: 'reference 1536x1024 @200%', size: const Size(1536, 1024)),
    ]) {
      testWidgets('${entry.name} render tanpa overflow', (tester) async {
        await pumpCenter(
          tester,
          size: entry.size,
          textScale: AccountCenterAccessibility.maximumSupportedTextScale,
        );
        expect(tester.takeException(), isNull, reason: entry.name);
        expect(find.text('ACCOUNT & CLOUD CENTER'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: entry.name);
      });
    }

    testWidgets('skala > 200% ditolak fail-closed oleh domain', (tester) async {
      expect(
        () => AccountCenterAccessibility.validateTextScale(2.5),
        throwsArgumentError,
      );
    });
  });

  group('115.7 reduced motion', () {
    testWidgets('disableAnimations=true dihonori tanpa motion dekoratif', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: AccountCloudCenterScreen(onSignIn: () {}),
            ),
          ),
        ),
      );
      await tester.pump();
      final context = tester.element(find.byType(AccountCloudCenterScreen));
      expect(AccountCenterAccessibility.reducedMotion(context), isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}

Rect _focusRect(WidgetTester tester) {
  final focus = FocusManager.instance.primaryFocus;
  final context = focus?.context;
  expect(context, isNotNull, reason: 'primaryFocus harus ada');
  final renderObject = (context! as Element).renderObject;
  expect(renderObject, isA<RenderBox>());
  final box = renderObject! as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}

double _borderWidth(BoxDecoration decoration) =>
    (decoration.border! as Border).top.width;

Color? _borderColor(BoxDecoration decoration) {
  final border = decoration.border as Border?;
  return border?.top.color;
}
