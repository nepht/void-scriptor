import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../projects/presentation/project_persistence_providers.dart';
import '../data/creature_repository.dart';
import '../domain/creature_model.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

final creatureWorkspaceProvider =
    FutureProvider.family<
      (
        CreatureModel?,
        CreaturePhysicalProfile?,
        List<CreatureAbilityModel>,
        List<CreatureModeModel>,
      ),
      String
    >((ref, creatureId) async {
      final session = ref.watch(projectSessionProvider).valueOrNull;
      if (session == null) {
        return (
          null,
          null,
          const <CreatureAbilityModel>[],
          const <CreatureModeModel>[],
        );
      }
      final repository = CreatureRepository(session.database);
      return (
        await repository.getCreature(creatureId),
        await repository.getPhysicalProfile(creatureId),
        await repository.abilitiesFor(creatureId),
        await repository.modesFor(creatureId),
      );
    });

class CreatureWorkspaceScreen extends ConsumerWidget {
  const CreatureWorkspaceScreen({
    super.key,
    required this.creatureId,
    this.activeSection,
  });
  final String creatureId;
  final String? activeSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(creatureWorkspaceProvider(creatureId));
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text('Creature could not be loaded: $error')),
      data: (data) {
        final creature = data.$1;
        if (creature == null) {
          return const Center(
            child: Text('Creature not found in this project.'),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (activeSection == null ||
                      activeSection == 'Profile' ||
                      activeSection == 'Ecology')
                    _CreatureHero(creature: creature),
                  if (activeSection == null ||
                      activeSection == 'Profile' ||
                      activeSection == 'Ecology')
                    const SizedBox(height: 16),
                  if (activeSection == null ||
                      activeSection == 'Anatomy' ||
                      activeSection == 'Abilities')
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 760;
                        final profile = activeSection == 'Abilities'
                            ? const SizedBox.shrink()
                            : _PhysicalCard(profile: data.$2);
                        final abilities = _ListCard(
                          title: 'Abilities',
                          icon: Icons.auto_awesome_outlined,
                          empty: 'No abilities recorded yet.',
                          children: [
                            for (final ability in data.$3)
                              ListTile(
                                title: Text(ability.name),
                                subtitle: ability.description.isEmpty
                                    ? null
                                    : Text(ability.description),
                              ),
                          ],
                        );
                        if (activeSection == 'Anatomy') return profile;
                        if (activeSection == 'Abilities') return abilities;
                        if (!wide) {
                          return Column(
                            children: [
                              profile,
                              const SizedBox(height: 16),
                              abilities,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: profile),
                            const SizedBox(width: 16),
                            Expanded(child: abilities),
                          ],
                        );
                      },
                    ),
                  if (activeSection == null || activeSection == 'Modes') ...[
                    const SizedBox(height: 16),
                    _ListCard(
                      title: 'Forms & Modes',
                      icon: Icons.view_in_ar_outlined,
                      empty: 'No alternate form or mode recorded yet.',
                      children: [
                        for (final mode in data.$4)
                          ListTile(
                            leading: Icon(
                              mode.defaultMode
                                  ? Icons.check_circle_outline
                                  : Icons.circle_outlined,
                            ),
                            title: Text(mode.name),
                            subtitle: mode.description.isEmpty
                                ? null
                                : Text(mode.description),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CreatureHero extends StatelessWidget {
  const _CreatureHero({required this.creature});
  final CreatureModel creature;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: context.palette.primary.withValues(alpha: 0.14),
            child: Icon(
              creature.category == CreatureCategory.companion
                  ? Icons.pets_outlined
                  : Icons.cruelty_free_outlined,
              color: context.palette.primaryBright,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  creature.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  _categoryLabel(creature.category),
                  style: TextStyle(color: context.palette.primaryBright),
                ),
                const SizedBox(height: 12),
                Text(
                  creature.description.isEmpty
                      ? 'No creature description yet.'
                      : creature.description,
                ),
                if (creature.behavior.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Behavior',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(creature.behavior),
                ],
                if (creature.origin.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Origin', style: Theme.of(context).textTheme.titleSmall),
                  Text(creature.origin),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _PhysicalCard extends StatelessWidget {
  const _PhysicalCard({required this.profile});
  final CreaturePhysicalProfile? profile;
  @override
  Widget build(BuildContext context) => _ListCard(
    title: 'Physical profile',
    icon: Icons.straighten_outlined,
    empty: 'No physical profile recorded yet.',
    children: profile == null
        ? const []
        : [
            _value('Height', profile!.heightCm, 'cm'),
            _value('Length', profile!.lengthCm, 'cm'),
            _value('Weight', profile!.weightKg, 'kg'),
            if (profile!.bodyStructure.isNotEmpty)
              ListTile(
                title: const Text('Body structure'),
                subtitle: Text(profile!.bodyStructure),
              ),
            if (profile!.distinguishingFeatures.isNotEmpty)
              ListTile(
                title: const Text('Distinctive features'),
                subtitle: Text(profile!.distinguishingFeatures),
              ),
          ],
  );

  static Widget _value(String label, double? value, String unit) =>
      value == null
      ? const SizedBox.shrink()
      : ListTile(
          title: Text(label),
          trailing: Text('${value.toStringAsFixed(1)} $unit'),
        );
}

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.title,
    required this.icon,
    required this.empty,
    required this.children,
  });
  final String title;
  final IconData icon;
  final String empty;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final visible = children.where((child) => child is! SizedBox).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 10),
            if (visible.isEmpty)
              Text(empty, style: TextStyle(color: context.palette.textMuted))
            else
              ...visible,
          ],
        ),
      ),
    );
  }
}

String _categoryLabel(CreatureCategory category) =>
    category.name[0].toUpperCase() + category.name.substring(1);
