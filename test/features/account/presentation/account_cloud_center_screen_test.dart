import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/auth/auth_session.dart';
import 'package:void_scriptor/features/account/application/account_operational_metrics.dart';
import 'package:void_scriptor/features/account/domain/account_cloud_snapshot.dart';
import 'package:void_scriptor/features/account/presentation/account_cloud_center_screen.dart';

void main() {
  final snapshot = AccountCloudSnapshot.localOnly(
    session: const AuthSession.guest(),
  );

  testWidgets('shows honest local and remote capability states', (
    tester,
  ) async {
    var signInRequested = false;
    await tester.pumpWidget(
      MaterialApp(
        home: AccountCloudCenterScreen(
          snapshot: snapshot,
          onSignIn: () => signInRequested = true,
        ),
      ),
    );

    expect(find.text('ACCOUNT & CLOUD CENTER'), findsOneWidget);
    expect(find.text('Guest mode'), findsWidgets);
    expect(find.text('Google Drive'), findsWidgets);
    expect(find.text('Not connected'), findsWidgets);
    expect(find.textContaining('GB of'), findsNothing);
    final syncAction = tester.widget<ListTile>(
      find.ancestor(of: find.text('Sync Now'), matching: find.byType(ListTile)),
    );
    final backupAction = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('Backup Project'),
        matching: find.byType(ListTile),
      ),
    );
    expect(syncAction.onTap, isNull);
    expect(syncAction.trailing, isNull);
    expect(backupAction.onTap, isNotNull);
    final search = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.search),
    );
    final notifications = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.notifications_none),
    );
    // 115.3: the search button now runs the account IA search index; the
    // notifications action remains an honest coming-soon extension point.
    expect(search.onPressed, isNotNull);
    expect(notifications.onPressed, isNull);
    for (final tab in [
      'Overview',
      'Connected Accounts',
      'Cloud Storage',
      'AI Providers',
      'API Keys',
      'Team & Collaboration',
      'Security',
      'Backup & Sync',
      'Billing',
    ]) {
      expect(find.text(tab), findsWidgets, reason: tab);
    }
    for (final title in [
      'CLOUD STORAGE USAGE',
      'CONNECTED SERVICES OVERVIEW',
      'API PROVIDERS',
      'DEVELOPER TOOLS',
      'CREATIVE TOOLS',
      'PAYMENT METHODS',
      // Mockup 1536x1024: kartu area API Keys bernama "API KEYS MANAGER".
      'API KEYS MANAGER',
      'TEAM & COLLABORATION',
      'ACTIVITY LOG',
      'BACKUP & SYNC',
      'SECURITY CENTER',
    ]) {
      expect(find.text(title), findsWidgets, reason: title);
    }
    // AI usage dan storage distribution diringkas di RAIL, bukan kartu grid
    // — mockup tidak punya kartu grid untuk keduanya.
    for (final title in [
      'AI USAGE THIS MONTH',
      'STORAGE DISTRIBUTION',
    ]) {
      expect(find.text(title), findsWidgets, reason: title);
    }

    // 115.36: aksi kartu AUTHENTICATION mengikuti mockup — tombolnya
    // "+ Add Another Method" di panel metode. Di tier mobile panel itu bisa
    // berada di luar viewport, jadi digulir dulu (bukan mengikat posisi scroll).
    await tester.ensureVisible(find.text('+ Add Another Method'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ Add Another Method'));
    await tester.pump();
    expect(signInRequested, isTrue);
  });

  testWidgets('renders live project usage and storage metrics when available', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountOperationalMetricsProvider.overrideWith(
            (ref) async => const AccountOperationalMetrics(
              promptTokens: 1200,
              completionTokens: 340,
              estimatedCost: 1.25,
              totalStorageBytes: 4096,
              storageBytesByCategory: {'Images': 3072, 'Database': 1024},
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AccountCloudCenterScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('1,540 tokens'), findsOneWidget);
    expect(find.textContaining(r'$1.25 estimated'), findsOneWidget);
    expect(find.textContaining('4 KB indexed'), findsOneWidget);
    expect(find.textContaining('Images 75%'), findsOneWidget);
    expect(find.textContaining('Database 25%'), findsOneWidget);
  });

  testWidgets(
    'reports metric read failures without claiming no project is open',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountOperationalMetricsProvider.overrideWith(
              (ref) => Future<AccountOperationalMetrics?>.error(
                StateError('database unavailable'),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AccountCloudCenterScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Could not read active project metrics'),
        findsWidgets,
      );
      expect(find.textContaining('database unavailable'), findsNothing);
    },
  );

  testWidgets('future action callbacks activate preserved extension points', (
    tester,
  ) async {
    var searched = false;
    var notificationsOpened = false;
    var syncRequested = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AccountCloudCenterScreen(
              onSearch: () => searched = true,
              onNotifications: () => notificationsOpened = true,
              onSyncNow: () => syncRequested = true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithIcon(IconButton, Icons.search));
    await tester.tap(find.widgetWithIcon(IconButton, Icons.notifications_none));
    final syncAction = tester.widget<ListTile>(
      find.ancestor(of: find.text('Sync Now'), matching: find.byType(ListTile)),
    );
    syncAction.onTap!();

    expect(searched, isTrue);
    expect(notificationsOpened, isTrue);
    expect(syncRequested, isTrue);
  });

  testWidgets('focused areas expose real destinations without shell rewrites', (
    tester,
  ) async {
    var aiProvidersOpened = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AccountCloudCenterScreen(
              onOpenAiProviders: () => aiProvidersOpened = true,
            ),
          ),
        ),
      ),
    );

    // 115.36: aksi "AI Providers" kini hidup di rail (kartu QUICK ACTIONS),
    // bukan sebagai kartu grid terpisah. Baris aksi memakai `ListTile`
    // (bukan `TextButton`) supaya target sentuh 44px terpenuhi dari token
    // density, dan label mockup adalah "AI Providers".
    //
    // Di tier non-wide rail berada di bawah grid tiga baris dan ikut bergulir
    // bersama halaman (diukur y=2894 pada viewport 800x600), jadi baris ini
    // harus digulir ke tampilan sebelum ditekan.
    final aiProvidersRow = find.widgetWithText(ListTile, 'AI Providers');
    expect(aiProvidersRow, findsOneWidget);
    await tester.ensureVisible(aiProvidersRow);
    await tester.pumpAndSettle();
    await tester.tap(aiProvidersRow);
    await tester.pump();
    expect(aiProvidersOpened, isTrue);

    // 115.36: panel tidak lagi digulir, jadi tab tidak lagi pemicu scroll —
    // tab menandai anchor dan breadcrumb. Memilih tab tidak boleh menyaring
    // atau menyembunyikan kartu area lain.
    await tester.tap(find.text('Cloud Storage').first);
    await tester.pump();
    expect(find.text('CLOUD STORAGE USAGE'), findsWidgets);
    // Panel tunggal: ringkasan rail dan kartu area boleh sama-sama tampil.
    expect(find.text('Google Drive'), findsWidgets);
  });

  testWidgets('canonical tabs reveal their area inside the single panel', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: AccountCloudCenterScreen())),
      ),
    );

    // Semua area hidup bersamaan; tab menandai anchor dan breadcrumb.
    expect(find.text('API PROVIDERS'), findsOneWidget);
    expect(find.text('BACKUP & SYNC'), findsOneWidget);

    // Tab strip digulir horizontal. Pada viewport 800px tab ke-8 berada di
    // luar layar (x=1572 saat diukur), jadi harus digulir ke tampilan dulu —
    // tab tetap reachable, hanya tidak terlihat tanpa scroll.
    final backupTab = find.text('Backup & Sync').first;
    await tester.ensureVisible(backupTab);
    await tester.pumpAndSettle();
    await tester.tap(backupTab);
    await tester.pump();

    expect(find.text('BACKUP & SYNC'), findsOneWidget);
    expect(find.text('Local project storage'), findsWidgets);
    expect(find.text('Available locally'), findsWidgets);
  });

  testWidgets('remains usable on a narrow phone viewport', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: AccountCloudCenterScreen(snapshot: snapshot)),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('ACCOUNT & CLOUD CENTER'), findsOneWidget);
  });

  testWidgets('initial tab, breadcrumb, and tab-change callback follow IA', (
    tester,
  ) async {
    String? changedTo;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: AccountCloudCenterScreen(
            initialTab: 'security',
            onTabChanged: (slug) => changedTo = slug,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('account-center-breadcrumb')),
      findsOneWidget,
    );
    expect(find.text('Account & Cloud Center / Security'), findsOneWidget);
    expect(find.text('SECURITY CENTER'), findsOneWidget);

    // Tab strip overflow di viewport uji 800px; ikuti idiom repo: panggil
    // onTap tab langsung (bukan hit-test) untuk tab di luar viewport.
    final apiKeysTab = tester.widget<InkWell>(
      find.ancestor(of: find.text('API Keys'), matching: find.byType(InkWell)),
    );
    apiKeysTab.onTap!();
    await tester.pump();

    // Mode router-driven: callback menerima slug, halaman saat ini tidak
    // berubah (tab state hidup di URL supaya back-navigation konsisten).
    expect(changedTo, 'api_keys');
    expect(find.text('Account & Cloud Center / Security'), findsOneWidget);

    // Simulasi rebuild router dengan tab param baru (deep-link sync).
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AccountCloudCenterScreen(initialTab: 'billing'),
        ),
      ),
    );

    expect(find.text('Account & Cloud Center / Billing'), findsOneWidget);
    expect(find.text('PAYMENT METHODS'), findsOneWidget);
  });

  testWidgets('unknown deep-link tab falls back to overview without errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AccountCloudCenterScreen(initialTab: 'does-not-exist'),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Account & Cloud Center / Overview'), findsOneWidget);
    expect(find.text('QUICK CONNECT'), findsOneWidget);
  });

  testWidgets('account section search navigates through the IA index', (
    tester,
  ) async {
    // 115.36: memilih section = menggulir ke anchor. Karena itu test ini memakai
    // seam search (bukan tap koordinat header yang bisa ter-scroll keluar).
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AccountCloudCenterScreen())),
    );

    Future<void> openSearch(String query) async {
      // 115.36: header ikut panel yang bisa digulir, jadi kembali ke atas dulu
      // (menurut skill: jangan ikat test ke posisi scroll).
      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      scrollable.position.jumpTo(0);
      await tester.pumpAndSettle();
      final search = find.widgetWithIcon(IconButton, Icons.search);
      expect(search, findsOneWidget);
      await tester.tap(search);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), query);
      await tester.pump();
    }

    await openSearch('billing');
    expect(find.byType(AlertDialog), findsOneWidget);

    final billingTile = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Billing'),
    );
    expect(billingTile, findsOneWidget);

    await tester.tap(billingTile);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Account & Cloud Center / Billing'), findsOneWidget);

    // Empty result state stays honest instead of inventing sections.
    await openSearch('no-such-section');
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('No account sections match that search.'),
      ),
      findsOneWidget,
    );
    final dismiss = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Close'),
    );
    expect(dismiss, findsOneWidget);
    await tester.tap(dismiss);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all nine canonical tabs render in IA order', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: AccountCloudCenterScreen())),
      ),
    );

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
      final dx = tester.getTopLeft(tab).dx;
      expect(dx, greaterThan(previousX), reason: 'tab order before $label');
      previousX = dx;
    }
  });
}
