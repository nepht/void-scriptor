import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../assets/presentation/widgets/asset_thumbnail_card.dart';
import '../../projects/presentation/project_persistence_providers.dart';
import '../data/environment_repository_impl.dart';
import '../domain/environment_model.dart';
import '../domain/environment_workspace_data.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

final environmentWorkspaceProvider =
    FutureProvider.family<EnvironmentModel?, String>((
      ref,
      environmentId,
    ) async {
      final session = ref.watch(projectSessionProvider).value;
      if (session == null) return null;
      return EnvironmentRepositoryImpl(
        database: session.database,
        projectId: session.manifest.id,
      ).getEnvironment(environmentId);
    });

/// Persisted profile data behind the LIGHTING/WEATHER/ZONES/CONTINUITY cards
/// (vs-hunt-20260913-environment ENV-BUG-002): the cards must render real
/// database values, never hardcoded stubs. Without a session the honest empty
/// state applies.
final environmentWorkspaceDataProvider =
    FutureProvider.family<EnvironmentWorkspaceData, String>((
      ref,
      environmentId,
    ) async {
      final session = ref.watch(projectSessionProvider).value;
      if (session == null) return const EnvironmentWorkspaceData();
      return EnvironmentRepositoryImpl(
        database: session.database,
        projectId: session.manifest.id,
      ).getWorkspaceData(environmentId);
    });

class EnvironmentWorkspaceScreen extends ConsumerWidget {
  const EnvironmentWorkspaceScreen({super.key, required this.environmentId});
  final String environmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(environmentWorkspaceProvider(environmentId)).value;
    final workspaceData = ref
        .watch(environmentWorkspaceDataProvider(environmentId))
        .value;
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
                  Column(
                    children: [
                      _EnvironmentLightingCard(
                        lighting: workspaceData?.lighting,
                      ),
                      const SizedBox(height: 12),
                      _EnvironmentWeatherCard(weather: workspaceData?.weather),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _EnvironmentLightingCard(
                          lighting: workspaceData?.lighting,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _EnvironmentWeatherCard(
                          weather: workspaceData?.weather,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                _EnvironmentZonesCard(zones: workspaceData?.zones ?? const []),
                const SizedBox(height: 12),
                _EnvironmentContinuityCard(
                  stateName: workspaceData?.continuityStateName,
                ),
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
        // ENV-BUG-004: the model defaults its strings to '' (and the DB
        // columns default to empty), so `?? '—'` alone rendered blank rows.
        _PropertyRow('Type', _orDash(model?.environmentType)),
        _PropertyRow('Location', _orDash(model?.location)),
        _PropertyRow('Architecture', _orDash(model?.architecture)),
        _PropertyRow('Terrain', _orDash(model?.terrain)),
        _PropertyRow('Notes', _orDash(model?.notes)),
      ],
    ),
  );
}

/// Null or blank values render the visible dash fallback.
String _orDash(String? value) {
  if (value == null || value.trim().isEmpty) return '—';
  return value;
}

/// Renders a stored profile enum name ('goldenHour') as a readable label.
String _humanize(String raw) {
  if (raw.isEmpty) return '—';
  final spaced = raw.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
  return spaced
      .split(' ')
      .map(
        (word) =>
            word.isEmpty ? word : word[0].toUpperCase() + word.substring(1),
      )
      .join(' ');
}

class _EnvironmentLightingCard extends StatelessWidget {
  const _EnvironmentLightingCard({required this.lighting});
  final EnvironmentLightingData? lighting;
  @override
  Widget build(BuildContext context) => _EnvironmentCard(
    title: 'LIGHTING',
    child: Column(
      children: [
        _PropertyRow('Time', _humanize(lighting?.time ?? '')),
        _PropertyRow('Key', _orDash(lighting?.keyLight)),
        _PropertyRow(
          'Fog',
          lighting == null ? '—' : lighting!.fogDensity.toString(),
        ),
      ],
    ),
  );
}

class _EnvironmentWeatherCard extends StatelessWidget {
  const _EnvironmentWeatherCard({required this.weather});
  final EnvironmentWeatherData? weather;
  @override
  Widget build(BuildContext context) => _EnvironmentCard(
    title: 'WEATHER',
    child: Column(
      children: [
        _PropertyRow('Condition', _humanize(weather?.condition ?? '')),
        _PropertyRow(
          'Intensity',
          weather == null ? '—' : weather!.intensity.toString(),
        ),
        _PropertyRow(
          'Visibility',
          weather == null ? '—' : weather!.visibility.toString(),
        ),
      ],
    ),
  );
}

class _EnvironmentZonesCard extends StatelessWidget {
  const _EnvironmentZonesCard({required this.zones});
  final List<String> zones;
  @override
  Widget build(BuildContext context) => _EnvironmentCard(
    title: 'ZONES',
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (zones.isEmpty)
          const Chip(label: Text('No zones yet'))
        else
          for (final zone in zones) Chip(label: Text(zone)),
      ],
    ),
  );
}

class _EnvironmentContinuityCard extends StatelessWidget {
  const _EnvironmentContinuityCard({required this.stateName});
  final String? stateName;
  @override
  Widget build(BuildContext context) => _EnvironmentCard(
    title: 'CONTINUITY',
    child: _PropertyRow('Current State', _orDash(stateName)),
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
