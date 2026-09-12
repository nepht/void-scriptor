import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../assets/presentation/widgets/asset_thumbnail_card.dart';
import '../../projects/presentation/project_persistence_providers.dart';
import '../data/environment_repository_impl.dart';
import '../domain/environment_model.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

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
      color: context.palette.background,
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
                      _EnvironmentPreviewCard(environmentId: environmentId),
                      const SizedBox(height: 12),
                      _EnvironmentInfoCard(model: model),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _EnvironmentPreviewCard(
                          environmentId: environmentId,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _EnvironmentInfoCard(model: model)),
                    ],
                  ),
                const SizedBox(height: 12),
                if (width < 760)
                  const Column(
                    children: [
                      _EnvironmentLightingCard(),
                      SizedBox(height: 12),
                      _EnvironmentWeatherCard(),
                    ],
                  )
                else
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
      Icon(Icons.landscape_outlined, color: context.palette.primaryBright),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(type, style: TextStyle(color: context.palette.textMuted)),
          ],
        ),
      ),
      const IconButton(
        tooltip: 'More environment actions (deferred)',
        onPressed: null,
        icon: Icon(Icons.more_horiz),
      ),
    ],
  );
}

/// Location preview: the same package-owned image binding used by the
/// character portrait and wardrobe/weapon/accessory workspaces (run235/236).
class _EnvironmentPreviewCard extends StatelessWidget {
  const _EnvironmentPreviewCard({required this.environmentId});
  final String environmentId;
  @override
  Widget build(BuildContext context) => AssetThumbnailCard(
    assetId: environmentId,
    title: 'LOCATION PREVIEW',
    placeholderIcon: Icons.landscape_outlined,
    aspectRatio: 16 / 9,
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
    color: context.palette.panelSecondary,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: context.palette.primaryBright,
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
            style: TextStyle(color: context.palette.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: context.palette.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
