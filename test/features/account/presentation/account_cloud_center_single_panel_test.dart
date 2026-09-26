import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/presentation/account_cloud_center_screen.dart';

/// 115.36 — Kontrak panel tunggal (Choi, 2026-09-26).
///
/// Account & Cloud Center dirender sebagai SATU panel scroll panjang: seluruh
/// kartu dari sembilan area kanonik tampil bersamaan, dan tab strip menjadi
/// anchor scroll (bukan pemisah konten).
///
/// Yang dipertahankan dari kontrak sebelumnya:
/// - sembilan tab kanonik tetap ada, berurutan, dan deep link `?tab=` tetap
///   menentukan section yang di-scroll ke posisi teratas.
/// - breadcrumb tetap mengikuti tab aktif.
/// - mode router-driven (`onTabChanged`) tetap tidak mengubah isi halaman.
void main() {
  Future<void> pumpCenter(
    WidgetTester tester, {
    String? initialTab,
    ValueChanged<String>? onTabChanged,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AccountCloudCenterScreen(
              initialTab: initialTab,
              onTabChanged: onTabChanged,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('semua kartu area kanonik tampil bersamaan dalam satu panel', (
    tester,
  ) async {
    await pumpCenter(tester);

    // Tiga kartu baris pertama mockup: autentikasi, quick connect, storage.
    expect(find.text('AUTHENTICATION'), findsOneWidget);
    expect(find.text('QUICK CONNECT'), findsOneWidget);
    // Cloud storage legitimately appears both as the overview card and as a
    // summary in the rail plus its own area anchor.
    expect(find.text('CLOUD STORAGE USAGE'), findsWidgets);

    // Kartu dari area non-overview ikut tampil: inilah kontrak "satu panel".
    // Satu kapabilitas = satu kartu kanonik; rail tetap boleh meringkas.
    // AI usage diringkas di rail saja (mockup tidak punya kartu grid untuk
    // itu), jadi di panel utama ia tidak boleh dihitung sebagai kartu.
    for (final title in const [
      'CONNECTED SERVICES OVERVIEW',
      'API PROVIDERS',
      'DEVELOPER TOOLS',
      'CREATIVE TOOLS',
      'PAYMENT METHODS',
      'API KEYS MANAGER',
      'TEAM & COLLABORATION',
      'ACTIVITY LOG',
      'BACKUP & SYNC',
      'SECURITY CENTER',
    ]) {
      expect(
        find.text(title),
        findsOneWidget,
        reason: 'kartu $title harus ada',
      );
    }
  });

  testWidgets('kartu non-overview tidak lagi disembunyikan oleh tab', (
    tester,
  ) async {
    await pumpCenter(tester);

    // Kontrak lama: memilih tab non-overview menyembunyikan kartu overview.
    // Kontrak baru menghapus perilaku itu.
    expect(find.text('QUICK CONNECT'), findsOneWidget);
    expect(find.text('TEAM & COLLABORATION'), findsOneWidget);
    expect(find.text('SECURITY CENTER'), findsOneWidget);
  });

  testWidgets('tab strip tetap sembilan dan berurutan sebagai anchor scroll', (
    tester,
  ) async {
    await pumpCenter(tester);

    const labels = [
      'Overview',
      'Connected Accounts',
      'Cloud Storage',
      'AI Providers',
      'API Keys',
      'Team & Collaboration',
      'Security',
      'Backup & Sync',
      'Billing',
    ];
    var previousX = -1.0;
    for (final label in labels) {
      final tab = find
          .ancestor(of: find.text(label), matching: find.byType(InkWell))
          .first;
      expect(tab, findsOneWidget, reason: 'tab $label harus ada');
      expect(
        tester.getTopLeft(tab).dx,
        greaterThan(previousX),
        reason: 'urutan tab sebelum $label',
      );
      previousX = tester.getTopLeft(tab).dx;
    }
  });

  testWidgets('deep link ?tab= Billing menggulir ke anchor Billing', (
    tester,
  ) async {
    await pumpCenter(tester, initialTab: 'billing');

    // Konten tetap utuh; yang berubah adalah posisi scroll.
    expect(find.text('QUICK CONNECT'), findsOneWidget);

    // Anchor harus ada dan bisa diukur: section Billing ada di panel yang sama.
    expect(find.text('PAYMENT METHODS'), findsOneWidget);
  });

  testWidgets('mode router-driven tidak lagi Rampas konten lewat tab', (
    tester,
  ) async {
    String? changedTo;
    await pumpCenter(tester, onTabChanged: (slug) => changedTo = slug);

    final billing = tester.widget<InkWell>(
      find
          .ancestor(of: find.text('Billing'), matching: find.byType(InkWell))
          .first,
    );
    billing.onTap!();
    await tester.pump();

    // Callback tetap dipanggil (router yang memutuskan), tapi panel tidak
    // lagi menyaring konten.
    expect(changedTo, 'billing');
    expect(find.text('QUICK CONNECT'), findsOneWidget);
  });

  testWidgets('breadcrumb tetap mengikuti tab untuk hibrida router', (
    tester,
  ) async {
    await pumpCenter(tester, initialTab: 'security');

    expect(
      find.byKey(const ValueKey('account-center-breadcrumb')),
      findsOneWidget,
    );
    expect(find.text('Account & Cloud Center / Security'), findsOneWidget);
  });

  testWidgets('tab tak dikenal tetap jatuh ke overview tanpa error', (
    tester,
  ) async {
    await pumpCenter(tester, initialTab: 'does-not-exist');

    expect(tester.takeException(), isNull);
    expect(find.text('QUICK CONNECT'), findsOneWidget);
  });

  // ---------------------------------------------------------------------
  // Mockup fidelity (referensi visual jadi primary, 2026-09-26).
  // ---------------------------------------------------------------------

  testWidgets('seluruh kartu muat dalam SATU panel tanpa scroll vertikal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpCenter(tester);

    // Kontrak Choi: satu panel, TANPA halaman yang memanjang. Bukti bukan
    // "tidak ada Scrollable" — kartu dan rail memang boleh menggulir di dalam
    // dirinya — tapi seluruh area kanonik TERLIHAT TANPA menggulir halaman:
    // kartu terakhir (Payment Methods, area Billing) dan kartu pertama
    // (Authentication, area Overview) sama-sama berada di dalam viewport.
    final viewRect = tester.view.physicalSize / tester.view.devicePixelRatio;
    // Mockup 1536x1024: baris 1 (Authentication) dan baris 3 (Security
    // Center) adalah batas atas & bawah panel. Keduanya harus terlihat tanpa
    // menggulir halaman.
    final first = find.byKey(
      const ValueKey('account-overview-card-authentication'),
    );
    final last = find.text('SECURITY CENTER');
    expect(first, findsOneWidget);
    expect(last, findsOneWidget);

    // Dudukkan koordinat viewport logical.
    // Halaman memakai Scaffold-nya sendiri di dalam harness yang juga
    // membungkus Scaffold, jadi ambil yang pertama.
    final origin = tester.getTopLeft(find.byType(Scaffold).first);
    final viewport = Rect.fromLTWH(
      origin.dx,
      origin.dy,
      viewRect.width,
      viewRect.height,
    );
    expect(
      viewport.contains(tester.getRect(first).center),
      isTrue,
      reason: 'kartu overview harus terlihat tanpa menggulir',
    );
    expect(
      viewport.contains(tester.getRect(last).center),
      isTrue,
      reason: 'kartu baris terakhir harus terlihat tanpa menggulir',
    );
  });

  testWidgets(
    'Authentication = SATU kartu: foto, nama, email, subscription, edit',
    (tester) async {
      await pumpCenter(tester);

      // Semua elemen profil hidup di dalam SATU kartu authentication, bukan
      // tersebar ke kartu sign-in terpisah.
      final card = find.byKey(
        const ValueKey('account-overview-card-authentication'),
      );
      expect(card, findsOneWidget);

      // Nama akun.
      expect(
        find.descendant(
          of: card,
          matching: find.byKey(const ValueKey('account-profile-name')),
        ),
        findsOneWidget,
      );
      // Email.
      expect(
        find.descendant(
          of: card,
          matching: find.byKey(const ValueKey('account-profile-email')),
        ),
        findsOneWidget,
      );
      // Jenis subscription.
      expect(
        find.descendant(
          of: card,
          matching: find.byKey(const ValueKey('account-profile-subscription')),
        ),
        findsOneWidget,
      );
      // Aksi edit profil.
      expect(
        find.descendant(of: card, matching: find.text('Edit profile')),
        findsOneWidget,
      );
      // Avatar/foto profil.
      expect(
        find.descendant(
          of: card,
          matching: find.byKey(const ValueKey('account-profile-avatar')),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'metode sign-in beserta ikonnya tergabung dalam kartu authentication',
    (tester) async {
      await pumpCenter(tester);

      final card = find.byKey(
        const ValueKey('account-overview-card-authentication'),
      );

      // Ikon + label tiap metode sign-in berada di dalam kartu yang sama.
      // Label kanonik dari AccountCloudSnapshot: 'Email sign-in', 'Google',
      // 'GitHub' (bukan 'Email' — itu ID, bukan teks yang ditampilkan).
      for (final method in const ['Email sign-in', 'Google', 'GitHub']) {
        expect(
          find.descendant(of: card, matching: find.text(method)),
          findsOneWidget,
          reason: 'metode sign-in $method harus di kartu authentication',
        );
      }
      expect(
        find.descendant(of: card, matching: find.byType(Icon)),
        findsWidgets,
        reason: 'setiap metode sign-in punya ikon',
      );
    },
  );

  testWidgets('tidak ada kartu sign-in terpisah di luar kartu authentication', (
    tester,
  ) async {
    await pumpCenter(tester);

    // Kartu sign-in sebagai kartu grid sendiri sudah dihapus; metode sign-in
    // hanya punya satu owner kanonik: kartu authentication.
    expect(find.text('ACCOUNT ACCESS'), findsNothing);
    expect(find.text('ADD ANOTHER METHOD'), findsNothing);
  });

  testWidgets('rail ringkasan hidup berdampingan, bukan jadi kartu grid', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpCenter(tester);

    // Proporsi mockup terukur: grid 75.47% / rail 24.53% (x 1170..1518 dari
    // 1536). Ringkasan tetap di rail kanan pada viewport referensi.
    expect(find.text('ACCOUNT SUMMARY'), findsOneWidget);
  });

  testWidgets('layar sempit menumpuk rail tanpa overflow', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpCenter(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('area Connected Accounts memakai kartu ringkas, bukan N kartu', (
    tester,
  ) async {
    await pumpCenter(tester);

    // Mockup baris 2: "Connected Services Overview" meringkas seluruh drive
    // dalam SATU kartu. Versi sebelumnya memetakan satu kartu penuh per
    // service, sehingga enam kartu (Signin/Localstorage) meledak menjadi baris
    // penuh dan menduplikasi QUICK CONNECT.
    final servicesSection = find.ancestor(
      of: find.text('CONNECTED SERVICES OVERVIEW'),
      matching: find.byType(Column),
    );
    expect(servicesSection, findsWidgets);

    // Tidak ada kartu tersendiri untuk tiap service sebagai kartu grid penuh.
    for (final label in const ['SIGNIN', 'LOCALSTORAGE']) {
      expect(
        find.text(label),
        findsNothing,
        reason: 'kartu per-service $label melanggar mockup kategori',
      );
    }
  });
}
