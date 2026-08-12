import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors/void_colors.dart';
import '../../projects/presentation/project_persistence_providers.dart';
import '../data/environment_repository_impl.dart';
import '../domain/environment_model.dart';

final environmentWorkspaceProvider =
    FutureProvider.family<EnvironmentModel?, String>((
      ref,
      environmentId,
    ) async {
      final session = ref.watch(projectSessionProvider).valueOrNull;
      if (session == null) return null;
      return EnvironmentRepositoryImpl(
        database: session.database,
        projectId: session.manifest.id,
      ).getEnvironment(environmentId);
    });

class EnvironmentWorkspaceScreen extends ConsumerWidget {
  const EnvironmentWorkspaceScreen({super.key, required this.environmentId});
  final String environmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref
        .watch(environmentWorkspaceProvider(environmentId))
        .valueOrNull;
    final width = MediaQuery.sizeOf(context).width;
    return ColoredBox(
      color: VoidColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EnvironmentHeader(
                  name: model?.name ?? environmentId,
                  type: model?.environmentType ?? 'Environment',
                ),
                const SizedBox(height: 16),
                if (width < 760)
                  Column(
                    children: [
                      const _EnvironmentPreviewCard(),
                      const SizedBox(height: 12),
                      _EnvironmentInfoCard(model: model),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(child: _EnvironmentPreviewCard()),
                      const SizedBox(width: 12),
                      Expanded(child: _EnvironmentInfoCard(model: model)),
                    ],
                  ),
                const SizedBox(height: 12),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _EnvironmentLightingCard()),
                    SizedBox(width: 12),
                    Expanded(child: _EnvironmentWeatherCard()),
                  ],
                ),
                const SizedBox(height: 12),
                const _EnvironmentZonesCard(),
                const SizedBox(height: 12),
                const _EnvironmentContinuityCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EnvironmentHeader extends StatelessWidget {
  const _EnvironmentHeader({required this.name, required this.type});
  final String name;
  final String type;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.landscape_outlined, color: VoidColors.primaryBright),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: VoidColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(type, style: const TextStyle(color: VoidColors.textMuted)),
          ],
        ),
      ),
      IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
    ],
  );
}

class _EnvironmentPreviewCard extends StatelessWidget {
  const _EnvironmentPreviewCard();
  @override
  Widget build(BuildContext context) => const _EnvironmentCard(
    title: 'LOCATION PREVIEW',
    child: AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: VoidColors.panel,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: Center(
          child: Icon(
            Icons.landscape_outlined,
            size: 54,
            color: VoidColors.textMuted,
          ),
        ),
      ),
    ),
  );
}

class _EnvironmentInfoCard extends StatelessWidget {
  const _EnvironmentInfoCard({required this.model});
  final EnvironmentModel? model;
  @override
  Widget build(BuildContext context) => _EnvironmentCard(
    title: 'ENVIRONMENT INFO',
    child: Column(
      children: [
        _PropertyRow('Type', model?.environmentType ?? '—'),
        _PropertyRow('Location', model?.location ?? '—'),
        _PropertyRow('Architecture', model?.architecture ?? '—'),
        _PropertyRow('Terrain', model?.terrain ?? '—'),
        _PropertyRow('Notes', model?.notes ?? '—'),
      ],
    ),
  );
}

class _EnvironmentLightingCard extends StatelessWidget {
  const _EnvironmentLightingCard();
  @override
  Widget build(BuildContext context) => const _EnvironmentCard(
    title: 'LIGHTING',
    child: Column(
      children: [
        _PropertyRow('Time', 'Noon'),
        _PropertyRow('Key', '—'),
        _PropertyRow('Fog', '0.0'),
      ],
    ),
  );
}

class _EnvironmentWeatherCard extends StatelessWidget {
  const _EnvironmentWeatherCard();
  @override
  Widget build(BuildContext context) => const _EnvironmentCard(
    title: 'WEATHER',
    child: Column(
      children: [
        _PropertyRow('Condition', 'Clear'),
        _PropertyRow('Intensity', '1.0'),
        _PropertyRow('Visibility', '1.0'),
      ],
    ),
  );
}

class _EnvironmentZonesCard extends StatelessWidget {
  const _EnvironmentZonesCard();
  @override
  Widget build(BuildContext context) => const _EnvironmentCard(
    title: 'ZONES',
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [Chip(label: Text('No zones yet'))],
    ),
  );
}

class _EnvironmentContinuityCard extends StatelessWidget {
  const _EnvironmentContinuityCard();
  @override
  Widget build(BuildContext context) => const _EnvironmentCard(
    title: 'CONTINUITY',
    child: _PropertyRow('Current State', 'Normal'),
  );
}

class _EnvironmentCard extends StatelessWidget {
  const _EnvironmentCard({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    color: VoidColors.panelSecondary,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: VoidColors.primaryBright,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

class _PropertyRow extends StatelessWidget {
  const _PropertyRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: const TextStyle(color: VoidColors.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: VoidColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
