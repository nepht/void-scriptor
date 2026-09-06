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
import 'widgets/quick_actions.dart';
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
                    Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Dashboard',
                          style: VoidTypography.displayMedium,
                        ),
                        LocalOnlyStatusBadge(
                          isLocalOnly:
                              authSession.status == AuthStatus.guest ||
                              authSession.status == AuthStatus.offline,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    WelcomeCard(
                      displayName: authSession.displayName ?? 'Creator',
                    ),
                    const SizedBox(height: 16),
                    QuickActions(
                      onCreateCharacter: () => _createCharacter(context, ref),
                    ),
                    const SizedBox(height: 24),
                    if (desktop)
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: RecentProjects()),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: [
                                StatisticsPanel(),
                                SizedBox(height: 16),
                                StorageCard(),
                              ],
                            ),
                          ),
                        ],
                      )
                    else ...[
                      const RecentProjects(),
                      const SizedBox(height: 16),
                      const StatisticsPanel(),
                      const SizedBox(height: 16),
                      const StorageCard(),
                    ],
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
