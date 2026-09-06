import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routing/app_routes.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../design_system/typography/void_typography.dart';
import '../../../design_system/theme/void_theme_context.dart';
import '../domain/account_cloud_snapshot.dart';

class AccountCloudCenterScreen extends ConsumerWidget {
  const AccountCloudCenterScreen({super.key, this.snapshot, this.onSignIn});

  final AccountCloudSnapshot? snapshot;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data =
        snapshot ??
        AccountCloudSnapshot.localOnly(
          session: ref.watch(authControllerProvider).valueOrNull,
        );
    return Scaffold(
      backgroundColor: context.palette.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth - 48;
            final cardWidth = contentWidth >= 820
                ? (contentWidth - 16) / 2
                : contentWidth;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ACCOUNT & CLOUD CENTER',
                    style: VoidTypography.displayMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Connection states reflect services available now.',
                    style: VoidTypography.body.copyWith(
                      color: context.palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _AccountSummary(
                    snapshot: data,
                    onSignIn:
                        data.service('email-sign-in').state ==
                            AccountCloudConnectionState.connected
                        ? null
                        : onSignIn ??
                              () => context.push(
                                '${AppRoutes.login}?from=account-cloud',
                              ),
                  ),
                  const SizedBox(height: 28),
                  for (final group in AccountCloudServiceGroup.values) ...[
                    Text(
                      _groupLabel(group),
                      style: VoidTypography.headingMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        for (final service in data.services.where(
                          (service) => service.group == group,
                        ))
                          SizedBox(
                            width: cardWidth,
                            child: _ServiceCard(service: service),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _groupLabel(AccountCloudServiceGroup group) => switch (group) {
    AccountCloudServiceGroup.signIn => 'SIGN-IN METHODS',
    AccountCloudServiceGroup.localStorage => 'LOCAL STORAGE',
    AccountCloudServiceGroup.cloudStorage => 'CLOUD STORAGE',
    AccountCloudServiceGroup.sync => 'BACKUP & SYNC',
  };
}

class _AccountSummary extends StatelessWidget {
  const _AccountSummary({required this.snapshot, this.onSignIn});

  final AccountCloudSnapshot snapshot;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.palette.border),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: context.palette.primary,
          child: const Icon(Icons.person_outline, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                snapshot.accountDisplayName,
                style: VoidTypography.headingMedium,
              ),
              const SizedBox(height: 4),
              Text(snapshot.accountModeLabel, style: VoidTypography.caption),
              if (onSignIn != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onSignIn,
                  icon: const Icon(Icons.login_outlined, size: 18),
                  label: const Text('Sign in or connect account'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});

  final AccountCloudService service;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: context.palette.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(service.label, style: VoidTypography.headingMedium),
            ),
            _ConnectionBadge(state: service.state),
          ],
        ),
        const SizedBox(height: 8),
        Text(service.description, style: VoidTypography.body),
        if (service.usageLabel case final usage?) ...[
          const SizedBox(height: 8),
          Text(usage, style: VoidTypography.caption),
        ],
      ],
    ),
  );
}

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge({required this.state});

  final AccountCloudConnectionState state;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      AccountCloudConnectionState.connected => (
        'Connected',
        context.palette.success,
      ),
      AccountCloudConnectionState.availableLocal => (
        'Available locally',
        context.palette.primaryBright,
      ),
      AccountCloudConnectionState.notConnected => (
        'Not connected',
        context.palette.textMuted,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: VoidTypography.caption.copyWith(color: color)),
    );
  }
}
