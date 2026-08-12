import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routing/app_routes.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../design_system/colors/void_colors.dart';
import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'widgets/ai_activity_card.dart';
import 'widgets/donation_card.dart';
import 'widgets/marketplace_card.dart';
import 'widgets/notifications_card.dart';
import 'widgets/quick_actions.dart';
import 'widgets/recent_assets.dart';
import 'widgets/recent_projects.dart';
import 'widgets/statistics_panel.dart';
import 'widgets/storage_card.dart';
import 'widgets/welcome_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: VoidColors.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: session.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('$error')),
          data: (authSession) => LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 1200;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(VoidSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dashboard',
                      style: VoidTypography.displayMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Welcome ${authSession.displayName ?? 'Creator'}',
                      style: VoidTypography.body,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your creative universe at a glance.',
                      style: VoidTypography.body,
                    ),
                    const SizedBox(height: 28),
                    WelcomeCard(
                      displayName: authSession.displayName ?? 'Creator',
                    ),
                    const SizedBox(height: 20),
                    QuickActions(
                      onOpenStudio: () => context.go(AppRoutes.studio),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => context.go(AppRoutes.studio),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open Studio'),
                    ),
                    const SizedBox(height: 20),
                    if (desktop)
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: RecentProjects()),
                          SizedBox(width: 16),
                          Expanded(child: StatisticsPanel()),
                        ],
                      )
                    else ...[
                      const RecentProjects(),
                      const SizedBox(height: 16),
                      const StatisticsPanel(),
                    ],
                    const SizedBox(height: 20),
                    if (desktop)
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: RecentAssets()),
                          SizedBox(width: 16),
                          Expanded(child: AiActivityCard()),
                        ],
                      )
                    else ...[
                      const RecentAssets(),
                      const SizedBox(height: 16),
                      const AiActivityCard(),
                    ],
                    const SizedBox(height: 20),
                    if (desktop)
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: StorageCard()),
                          SizedBox(width: 16),
                          Expanded(child: NotificationsCard()),
                          SizedBox(width: 16),
                          Expanded(child: MarketplaceCard()),
                        ],
                      )
                    else ...[
                      const StorageCard(),
                      const SizedBox(height: 16),
                      const NotificationsCard(),
                      const SizedBox(height: 16),
                      const MarketplaceCard(),
                    ],
                    const SizedBox(height: 20),
                    const DonationCard(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
