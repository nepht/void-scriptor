import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../design_system/colors/void_colors.dart';
import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import '../../../design_system/widgets/void_button.dart';
import '../../../design_system/widgets/void_card.dart';
import '../../../app/routing/app_routes.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: VoidColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VoidSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              session.when(
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text('$error'),
                data: (session) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome ${session.displayName ?? 'Creator'}',
                      style: VoidTypography.displayMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Creative Universe Studio',
                      style: VoidTypography.body,
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        VoidButton(
                          label: 'New Project',
                          icon: Icons.add,
                          onPressed: () {},
                        ),
                        VoidButton(
                          label: 'Open Project',
                          icon: Icons.folder_open_outlined,
                          onPressed: () {},
                        ),
                        VoidButton(
                          label: 'AI Studio',
                          icon: Icons.auto_awesome_outlined,
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Continue Working',
                      style: VoidTypography.headingMedium,
                    ),
                    const SizedBox(height: 16),
                    VoidCard(
                      child: Row(
                        children: [
                          Container(
                            width: 90,
                            height: 70,
                            decoration: BoxDecoration(
                              color: VoidColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Void Universe',
                                  style: VoidTypography.title,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Last opened recently',
                                  style: VoidTypography.caption,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: VoidColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text('Overview', style: VoidTypography.headingMedium),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.4,
                      children: const [
                        _StatCard(title: 'Characters', value: '0'),
                        _StatCard(title: 'Assets', value: '0'),
                        _StatCard(title: 'Projects', value: '0'),
                      ],
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: () {
                        context.go(AppRoutes.studio);
                      },
                      child: const Text('Open Studio'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        ref.read(authControllerProvider.notifier).logout();
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) {
    return VoidCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: VoidTypography.displayMedium),
          const SizedBox(height: 4),
          Text(title, style: VoidTypography.caption),
        ],
      ),
    );
  }
}
