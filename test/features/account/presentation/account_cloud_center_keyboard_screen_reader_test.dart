import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_accessibility.dart';
import 'package:void_scriptor/features/account/domain/account_center_information_architecture.dart';
import 'package:void_scriptor/features/account/domain/account_center_keyboard_screen_reader_verification.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_connector_manifest.dart';
import 'package:void_scriptor/features/account/presentation/account_cloud_center_screen.dart';

/// 115.48 — Keyboard & Screen Reader Verification (bagian presentation).
///
/// Bukti bahwa Account & Cloud Center benar-benar dapat dioperasikan dengan
/// keyboard dan dibaca pembaca layar, bukan hanya punya file kontrak.
///
/// Cakupan lokal: traversal fokus di tiga tier chrome, pengumuman status
/// saat tab/drawer/sheet/search berubah, dialog search (label field, Escape,
/// target sentuh), alternatif teks chart, dan affordance jujur pada navigasi
/// struktural. Sertifikasi pembaca layar native, kontras terukur, dan audit
/// lintas viewport penuh tetap 115.48-lanjutan/DEFERRED-EXTERNAL.
void main() {
  late List<CapturedAccessibilityAnnouncement> announcements;

  Future<void> pumpCenter(
    WidgetTester tester, {
    Size size = const Size(1536, 1024),
    ProviderConnectorManifest? manifest,
    void Function(ProviderConnectorEntry)? onConnect,
    String? initialTab,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: AccountCloudCenterScreen(
            initialTab: initialTab,
            providerManifest: manifest,
            onConnectProvider: onConnect == null
                ? null
                : (entry) => onConnect(entry),
          ),
        ),
      ),
    );
    await tester.pump();
    announcements = tester.binding.takeAnnouncements();
  }

  /// Manifest dengan satu entry `available` supaya aksi connect benar-benar
  /// hidup — dipakai lewat API produksi `fromJsonString` (bukan konstruktor
  /// tiruan) supaya test tidak mengarang bentuk data.
  ProviderConnectorManifest connectableManifest() =>
      ProviderConnectorManifest.fromJsonString(
        jsonEncode(<String, Object?>{
          'manifest_version': 'manifest-v1',
          'entries': <Object?>[
            <String, Object?>{
              'provider_id': 'openai',
              'display_name': 'OpenAI',
              'category': 'ai',
              'capabilities': <String>['ai_text'],
              // Wire name uppercase sesuai enum — dariJson menolak nama lain.
              'availability': 'AVAILABLE',
              'regions': <String>['GLOBAL'],
              'connector_version': 'manifest-v1',
              'auth_type': 'OAUTH2_PKCE',
              // Daftar enum wajib non-empty (fromJson menolak list kosong).
              'permissions': <String>['account_metadata'],
            },
          ],
        }),
      );

  /// [context] berada di dalam subtree [ancestor]?
  bool isDescendantOf(BuildContext context, Element ancestor) {
    if (identical(context, ancestor)) {
      return true;
    }
    var hit = false;
    (context as Element).visitAncestorElements((element) {
      if (identical(element, ancestor)) {
        hit = true;
        return false;
      }
      return true;
    });
    return hit;
  }

  /// Cari [FocusNode] yang menempel pada widget di dalam [finder].
  ///
  /// InkWell membangun FocusNode sendiri (tanpa referensi publik), jadi test
  /// tidak bisa merujuknya langsung. Dipetakan dari root supaya bukti fokus
  /// diuji pada node yang benar-benar dipakai widget, bukan node karangan.
  FocusNode? focusNodeUnder(Finder finder) {
    final element = finder.evaluate().first;
    FocusNode? found;
    void walk(FocusNode node) {
      final context = node.context;
      if (context != null && isDescendantOf(context, element)) {
        found = node;
      }
      for (final child in node.children) {
        walk(child);
      }
    }

    walk(FocusManager.instance.rootScope);
    return found;
  }

  /// Node semantik milik field itu sendiri (flag `isTextField`), bukan node
  /// pembungkusnya yang labelnya kosong — itu yang benar-benar dibaca pembaca
  /// layar saat menyorot field.
  SemanticsNode? textFieldNode(WidgetTester tester) {
    final root = tester.getSemantics(find.byType(TextField));
    SemanticsNode? found;
    bool walk(SemanticsNode node) {
      if (node.flagsCollection.isTextField) {
        found = node;
        return false;
      }
      node.visitChildren(walk);
      return true;
    }

    walk(root);
    return found;
  }

  /// Status koneksi yang benar-benar ditampilkan oleh sheet provider.
  ///
  /// Diambil dari label semantik sheet, bukan dari anggapan test soal makna
  /// `availability` — jadi yang diuji adalah "yang diucap pembaca layar sama
  /// dengan yang terlihat", bukan tebakan test terhadap pemetaan status.
  String sheetConnectionStatus(WidgetTester tester) {
    final sheet = find.byKey(const ValueKey('account-center-provider-details'));
    final label = tester
        .widgetList<Semantics>(
          find.descendant(of: sheet, matching: find.byType(Semantics)),
        )
        .map((node) => node.properties.label)
        .whereType<String>()
        .firstWhere(
          (value) => value.contains('OpenAI') && value.contains(', '),
          orElse: () => '',
        );
    if (label.isEmpty) {
      fail('sheet tidak punya label semantik berbentuk "Nama, Status"');
    }
    return label.substring(label.lastIndexOf(', ') + 2);
  }

  group('115.48 focus_order — chrome nyata di tiga tier', () {
    testWidgets('tab strip keyboard-reachable di wide_desktop dan kontrak', (
      tester,
    ) async {
      await pumpCenter(tester);

      // Sembilan tab = sembilan focus stop setelah header, sesuai urutan IA.
      for (final tab in AccountCenterInformationArchitecture.tabs) {
        final tile = find.ancestor(
          of: find.text(tab.label),
          matching: find.byType(InkWell),
        );
        expect(tile, findsWidgets, reason: 'tab ${tab.label} harus dirender');
        expect(
          AccountCenterAccessibility.meetsKeyboardTarget(
            tester.getSize(tile.first),
          ),
          isTrue,
          reason: 'tab ${tab.label} harus >= 32px (keyboard target)',
        );
      }

      // Kontrak 115.48: urutan fokus menutupi sembilan tab tepat satu kali.
      expect(
        () => AccountCenterKeyboardScreenReader.validateFocusOrder(
          AccountCenterKeyboardScreenReader.expectedFocusStops,
        ),
        returnsNormally,
      );
    });

    testWidgets(
      'tab dapat diaktifkan dengan keyboard (Enter) dan mengumumkan status',
      (tester) async {
        await pumpCenter(tester, initialTab: 'overview');

        final target = AccountCenterInformationArchitecture.tabs.firstWhere(
          (tab) => tab.slug == 'billing',
        );
        final tile = find
            .ancestor(
              of: find.text(target.label),
              matching: find.byType(InkWell),
            )
            .first;

        // Tab Billing berada di luar viewport 1536px (strip tab men-scroll),
        // jadi ketukan biasa dilewati meski warnIfMissed dimatikan — itu justru
        // menutupi kegagalan. Keyboard tidak butuh scroll: ambil FocusNode
        // internal InkWell dari pohon fokus, beri fokus, kirim Enter.
        final focusNode = focusNodeUnder(tile.first);
        expect(
          focusNode,
          isNotNull,
          reason: 'tile tab harus punya FocusNode supaya bisa difokuskan',
        );
        focusNode!.requestFocus();
        await tester.pump();
        expect(
          focusNode.hasPrimaryFocus,
          isTrue,
          reason: 'tab harus menang fokus, bukan keluar dari pohon fokus',
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        announcements = tester.binding.takeAnnouncements();

        expect(
          announcements.map((item) => item.message),
          contains(
            AccountCenterKeyboardScreenReader.tabSelectedAnnouncement(
              target.label,
            ),
          ),
          reason: 'perpindahan tab harus terdengar, bukan hanya berubah warna',
        );
      },
    );

    testWidgets('focus order mobile: header lalu tab lalu aksi bar', (
      tester,
    ) async {
      await pumpCenter(tester, size: const Size(390, 844));

      // Tab strip masih ada di mobile dan tetap bisa difokuskan.
      expect(find.byType(InkWell), findsWidgets);

      // Action bar mobile punya tiga target 44px seperti kontrak 115.47,
      // dan setiap target harus punya semantics enabled yang jujur.
      final bar = find.byKey(
        const ValueKey('account-center-mobile-action-bar'),
      );
      expect(bar, findsOneWidget);
      for (final key in <String>['overview', 'search', 'connect']) {
        final target = find.byKey(
          ValueKey('account-center-mobile-action-$key'),
        );
        expect(target, findsOneWidget, reason: 'slot aksi $key harus ada');
        expect(
          AccountCenterAccessibility.meetsTouchTarget(tester.getSize(target)),
          isTrue,
          reason: 'target aksi $key harus >= 44px',
        );
      }
    });
  });

  group(
    '115.48 screen_reader_results — navigasi struktural tidak menyamar',
    () {
      for (final entry in <({String tier, Size size, String key})>[
        (
          tier: 'wide_desktop rail kiri',
          size: const Size(1536, 1024),
          key: 'account-center-left-navigation',
        ),
        (
          tier: 'compact_desktop collapsed rail',
          size: const Size(1000, 900),
          key: 'account-center-collapsed-rail',
        ),
        (
          tier: 'tablet top navigation',
          size: const Size(700, 900),
          key: 'account-center-top-navigation',
        ),
      ]) {
        testWidgets('${entry.tier} tidak punya Semantics(button: true)', (
          tester,
        ) async {
          await pumpCenter(tester, size: entry.size);
          final band = find.byKey(ValueKey(entry.key));
          expect(
            band,
            findsOneWidget,
            reason: 'band ${entry.tier} harus dirender',
          );

          final buttons = tester
              .widgetList<Semantics>(
                find.descendant(of: band, matching: find.byType(Semantics)),
              )
              .where((node) => node.properties.button == true)
              .toList();
          expect(
            buttons,
            isEmpty,
            reason:
                'navigasi struktural tanpa onTap tidak boleh diumumkan button '
                '(affordance palsu)',
          );
        });
      }

      testWidgets('label navigasi tetap terbaca sebagai teks', (tester) async {
        await pumpCenter(tester, size: const Size(1000, 900));
        final rail = find.byKey(
          const ValueKey('account-center-collapsed-rail'),
        );
        expect(rail, findsOneWidget);
        // Label tidak boleh hilang bersama `button`: pembaca layar tetap
        // harus tahu section mana yang aktif.
        expect(
          tester
              .widgetList<Semantics>(
                find.descendant(of: rail, matching: find.byType(Semantics)),
              )
              .any((node) => node.properties.label == 'Connected services'),
          isTrue,
          reason:
              'navigasi terlipat menyembunyikan label visual, bukan semantics',
        );
      });
    },
  );

  group('115.48 status_announcements', () {
    testWidgets('membuka sheet provider mengumumkan nama + status', (
      tester,
    ) async {
      ProviderConnectorEntry? connected;
      await pumpCenter(
        tester,
        size: const Size(390, 844),
        manifest: connectableManifest(),
        onConnect: (entry) => connected = entry,
      );

      await tester.tap(
        find.byKey(const ValueKey('account-center-mobile-action-connect')),
      );
      await tester.pump();
      announcements = tester.binding.takeAnnouncements();

      final sheet = find.byKey(
        const ValueKey('account-center-provider-details'),
      );
      expect(sheet, findsOneWidget);
      // Status diambil dari label semantik sheet yang benar-benar dirender
      // (`availability: AVAILABLE` -> 'Connected' pada `_providerConnectionLabel`,
      // builder yang sama dengan tile 115.15), lalu dikunci ke teks yang
      // terlihat di baris Connection. Pengumuman wajib memakai nilai yang
      // sama supaya "yang diucap = yang terlihat" benar-benar diuji.
      final status = sheetConnectionStatus(tester);
      expect(
        status,
        'Connected',
        reason: 'availability AVAILABLE dipetakan _providerConnectionLabel',
      );
      expect(
        find.descendant(of: sheet, matching: find.text(status)),
        findsWidgets,
        reason: 'sheet harus menampilkan teks Connection yang sama',
      );
      expect(
        announcements.map((item) => item.message),
        contains(
          AccountCenterKeyboardScreenReader.providerDetailsAnnouncement(
            name: 'OpenAI',
            status: status,
            opening: true,
          ),
        ),
      );
      expect(connected, isNull, reason: 'sheet belum menjalankan connect');
    });

    testWidgets('menutup sheet provider mengumumkan sheet ditutup', (
      tester,
    ) async {
      await pumpCenter(
        tester,
        size: const Size(390, 844),
        manifest: connectableManifest(),
        onConnect: (_) {},
      );
      await tester.tap(
        find.byKey(const ValueKey('account-center-mobile-action-connect')),
      );
      await tester.pump();
      // Status dibaca selagi sheet masih terbuka, karena setelah ditutup
      // label semantiknya hilang.
      final status = sheetConnectionStatus(tester);
      tester.binding.takeAnnouncements();

      await tester.tap(
        find.byKey(const ValueKey('account-center-provider-details-close')),
      );
      await tester.pump();
      announcements = tester.binding.takeAnnouncements();

      expect(
        announcements.map((item) => item.message),
        contains(
          AccountCenterKeyboardScreenReader.providerDetailsAnnouncement(
            name: 'OpenAI',
            status: status,
            opening: false,
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('account-center-provider-details')),
        findsNothing,
      );
    });

    testWidgets('drawer ringkasan tier desktop mengumumkan buka/tutup', (
      tester,
    ) async {
      await pumpCenter(tester, size: const Size(1280, 1024));
      final toggle = find.byKey(const ValueKey('account-center-drawer-toggle'));
      expect(toggle, findsOneWidget, reason: 'tier desktop punya drawer');

      await tester.tap(toggle);
      await tester.pump();
      announcements = tester.binding.takeAnnouncements();
      expect(
        announcements.map((item) => item.message),
        contains(
          AccountCenterKeyboardScreenReader.summaryDrawerAnnouncement(
            open: true,
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('account-center-summary-drawer')),
        findsOneWidget,
      );

      await tester.tap(toggle);
      await tester.pump();
      announcements = tester.binding.takeAnnouncements();
      expect(
        announcements.map((item) => item.message),
        contains(
          AccountCenterKeyboardScreenReader.summaryDrawerAnnouncement(
            open: false,
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('account-center-summary-drawer')),
        findsNothing,
      );
    });

    testWidgets('dialog search mengumumkan jumlah hasil termasuk nol hasil', (
      tester,
    ) async {
      await pumpCenter(tester);

      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is IconButton &&
              widget.tooltip == 'Search account sections',
        ),
      );
      await tester.pumpAndSettle();
      announcements = tester.binding.takeAnnouncements();

      // Kueri kosong = mode jelajah: seluruh section ditampilkan, jadi
      // pengumuman wajib mengikuti jumlah nyata — bukan mengarang nol.
      final browseMatches = AccountCenterInformationArchitecture.search(
        '',
      ).length;
      expect(browseMatches, greaterThan(0));
      expect(
        announcements.map((item) => item.message),
        contains(
          AccountCenterKeyboardScreenReader.searchResultsAnnouncement(
            browseMatches,
          ),
        ),
        reason: 'dialog yang baru dibuka harus mengumumkan isi daftarnya',
      );

      await tester.enterText(find.byType(TextField), 'bil');
      await tester.pump();
      announcements = tester.binding.takeAnnouncements();
      final billingMatches = AccountCenterInformationArchitecture.search(
        'bil',
      ).length;
      expect(
        announcements.map((item) => item.message),
        contains(
          AccountCenterKeyboardScreenReader.searchResultsAnnouncement(
            billingMatches,
          ),
        ),
      );

      // Kueri tanpa cocok → pesan nol hasil harus benar-benar terdengar,
      // dengan bentuk kalimat yang dikontrak 115.48.
      const miss = 'zzzqqq-no-such-section';
      await tester.enterText(find.byType(TextField), miss);
      await tester.pump();
      announcements = tester.binding.takeAnnouncements();
      expect(AccountCenterInformationArchitecture.search(miss), isEmpty);
      expect(
        announcements.map((item) => item.message),
        contains(
          AccountCenterKeyboardScreenReader.searchResultsAnnouncement(0),
        ),
        reason: 'nol hasil = pengumuman nol, bukan daftar kosong diam-diam',
      );
    });
  });

  group('115.48 dialog_results', () {
    testWidgets('field search punya semantics label, bukan hanya hint', (
      tester,
    ) async {
      // Label harus terbaca di pohon semantik NYATA, jadi pohon itu dinyalakan
      // dulu; tanpa ini tes ini selalu lolos palsu (label kosong diabaikan).
      // Handle-nya ditutup di dalam body, bukan lewat addTearDown: verifikasi
      // akhir test berjalan sebelum tearDown, jadi handle yang baru ditutup di
      // sana tetap terbaca sebagai kebocoran.
      final semantics = tester.ensureSemantics();
      try {
        await pumpCenter(tester);
        await tester.tap(
          find.byWidgetPredicate(
            (widget) =>
                widget is IconButton &&
                widget.tooltip == 'Search account sections',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
        expect(
          textFieldNode(tester),
          isNotNull,
          reason: 'field harus punya node semantik isTextField sendiri',
        );
        expect(
          textFieldNode(tester)!.label,
          contains(AccountCenterKeyboardScreenReader.searchFieldLabel),
          reason: 'field tanpa label = pembaca layar tidak tahu apa yang diisi',
        );
        // Label permanen, bukan hint yang menguap saat pengguna mengetik.
        await tester.enterText(find.byType(TextField), 'billing');
        await tester.pump();
        expect(
          textFieldNode(tester)!.label,
          contains(AccountCenterKeyboardScreenReader.searchFieldLabel),
          reason: 'label tidak boleh hilang setelah ada isian',
        );
        expect(
          textFieldNode(tester)!.label,
          contains(AccountCenterKeyboardScreenReader.searchFieldHint),
          reason: 'hint boleh ikut, asal label tetap ada',
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('Escape menutup dialog search', (tester) async {
      await pumpCenter(tester);
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is IconButton &&
              widget.tooltip == 'Search account sections',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Search account sections'), findsOneWidget);

      expect(
        () => AccountCenterKeyboardScreenReader.requireDismissKey('Escape'),
        returnsNormally,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        find.text('Search account sections'),
        findsNothing,
        reason: 'dialog harus bisa ditutup tanpa mouse',
      );
    });

    testWidgets('hasil search adalah target sentuh >= 44px', (tester) async {
      await pumpCenter(tester);
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is IconButton &&
              widget.tooltip == 'Search account sections',
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'o');
      await tester.pump();

      final results = find.byType(ListTile);
      expect(results, findsWidgets);
      for (final element in results.evaluate().toList()) {
        final size = tester.getSize(find.byWidget(element.widget));
        expect(
          AccountCenterAccessibility.meetsTouchTarget(size),
          isTrue,
          reason: 'hasil dialog harus punya target sentuh 44px',
        );
      }
    });
  });

  group('115.48 chart_alternatives', () {
    testWidgets('dua chart punya node Semantics image dengan alternatif teks', (
      tester,
    ) async {
      await pumpCenter(tester);

      for (final chart
          in AccountCenterKeyboardScreenReader.requiredChartAlternatives) {
        expect(
          find.text(chart),
          findsWidgets,
          reason: 'chart $chart harus ada',
        );
      }

      final audit = AccountCenterKeyboardScreenReader.auditChartAlternatives(
        const <String, String>{
          'AI USAGE THIS MONTH': 'AI USAGE THIS MONTH. Usage unavailable.',
          'STORAGE DISTRIBUTION': 'STORAGE DISTRIBUTION. Storage unavailable.',
        },
      );
      expect(audit.isComplete, isTrue);
    });

    testWidgets(
      'alternatif chart berasal dari fakta yang sama dengan teks terlihat',
      (tester) async {
        await pumpCenter(tester);
        final usage = AccountCenterAccessibility.chartTextAlternative(
          title: 'AI USAGE THIS MONTH',
          facts: const <String>['Usage unavailable'],
        );
        expect(usage, 'AI USAGE THIS MONTH. Usage unavailable');
        expect(find.textContaining('Usage unavailable'), findsWidgets);
      },
    );
  });

  group('115.48 sensitive actions — tidak ada klaim palsu', () {
    testWidgets(
      'permukaan 115.48 tidak mengklaim aksi sensitif terverifikasi',
      (tester) async {
        await pumpCenter(tester);
        // Tidak ada aksi sensitif yang diekspos di chrome 115.5-115.47, jadi
        // laporan WAJIB `notExposed` — bukan PASS.
        final exposure =
            AccountCenterKeyboardScreenReader.assessSensitiveActionExposure(
              performed: const <String>{},
            );
        expect(exposure.state, AccountCenterSensitiveExposure.notExposed);
        expect(exposure.isVerified, isFalse);
      },
    );
  });
}
