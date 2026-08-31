import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routing/app_routes.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/auth/auth_status.dart';
import '../../character/presentation/character_controller.dart';
import '../../projects/presentation/project_persistence_providers.dart';
import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'widgets/local_only_status.dart';
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
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _createCharacter(BuildContext context, WidgetRef ref) async {
    final session = ref.read(projectSessionProvider).valueOrNull;
    if (session == null) {
      if (context.mounted) context.go(AppRoutes.studio);
      return;
    }
    var name = '';
    final submitted = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Character'),
        content: TextField(
          autofocus: true,
          onChanged: (value) => name = value.trim(),
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (name.isNotEmpty) Navigator.pop(dialogContext, name);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (submitted == null || !context.mounted) return;
    await CharacterActions(
      ref,
      session.manifest.id,
      session.database,
    ).create(submitted);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Character created.')));
    context.go(AppRoutes.workspace);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: context.palette.background,
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
                    const SizedBox(height: 10),
                    LocalOnlyStatusBadge(
                      isLocalOnly:
                          authSession.status == AuthStatus.guest ||
                          authSession.status == AuthStatus.offline,
                    ),
                    const SizedBox(height: 28),
                    WelcomeCard(
                      displayName: authSession.displayName ?? 'Creator',
                    ),
                    const SizedBox(height: 20),
                    QuickActions(
                      onOpenStudio: () => context.go(AppRoutes.studio),
                      onCreateCharacter: () => _createCharacter(context, ref),
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
