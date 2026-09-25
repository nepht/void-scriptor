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
      'AI PROVIDERS',
      'DEVELOPER TOOLS',
      'CREATIVE TOOLS',
      'PAYMENT METHODS',
      'API KEYS MANAGER',
      'TEAM & COLLABORATION',
      'ACTIVITY LOG',
      'BACKUP & SYNC',
      'SECURITY CENTER',
      'AI USAGE THIS MONTH',
      'STORAGE DISTRIBUTION',
    ]) {
      expect(find.text(title), findsWidgets, reason: title);
    }

    await tester.tap(find.text('Sign in or connect account'));
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

    await tester.tap(find.text('Connected Accounts'));
    await tester.pump();
    expect(find.text('Sign in or connect account'), findsOneWidget);

    await tester.tap(find.text('AI Providers').first);
    await tester.pump();
    final openProviders = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Open AI Providers'),
    );
    openProviders.onPressed!();
    expect(aiProvidersOpened, isTrue);

    await tester.tap(find.text('Cloud Storage').first);
    await tester.pump();
    expect(find.text('Google Drive'), findsOneWidget);
  });

  testWidgets('canonical tabs select focused account areas', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: AccountCloudCenterScreen())),
      ),
    );

    await tester.tap(find.text('AI Providers').first);
    await tester.pump();

    expect(find.text('API PROVIDERS'), findsOneWidget);
    expect(find.text('CONNECTED SERVICES'), findsNothing);
    expect(find.text('Overview'), findsOneWidget);

    final backupSyncTab = tester.widget<InkWell>(
      find.ancestor(
        of: find.text('Backup & Sync'),
        matching: find.byType(InkWell),
      ),
    );
    backupSyncTab.onTap!();
    await tester.pump();

    expect(find.text('BACKUP & SYNC'), findsOneWidget);
    expect(find.text('Local project storage'), findsOneWidget);
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
    // Mode lokal (tanpa onTabChanged): pilihan hasil search mengganti tab
    // langsung dari state screen.
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AccountCloudCenterScreen())),
    );

    await tester.tap(find.widgetWithIcon(IconButton, Icons.search));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'billing');
    await tester.pump();

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
    await tester.tap(find.widgetWithIcon(IconButton, Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'no-such-section');
    await tester.pump();
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
