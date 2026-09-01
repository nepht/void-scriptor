import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';
import '../../../projects/presentation/project_persistence_providers.dart';
import '../../data/character_repository_impl.dart';
import '../../domain/character_scope_layers.dart';

/// Resolves the three Character Scope Layers for one character through the
/// live project session repository (the same production path the workspace
/// uses for all other character data).
final characterScopeStatesProvider =
    FutureProvider.family<
      Map<CharacterScopeLayer, CharacterScopeState>,
      String
    >((ref, characterId) async {
      final session = ref.watch(projectSessionProvider).valueOrNull;
      if (session == null) return const {};
      return CharacterRepositoryImpl(
        database: session.database,
        projectId: session.manifest.id,
        paths: ref.read(projectPathsProvider),
      ).getScopeStates(characterId);
    });

String _scopeLabel(CharacterScopeLayer layer) => switch (layer) {
  CharacterScopeLayer.canonical => 'Canonical',
  CharacterScopeLayer.universeTimeline => 'Universe-Timeline',
  CharacterScopeLayer.novelSpecific => 'Novel-Specific',
};

/// Step 145.26 Workspace source-scope display: reveals WHICH scope layer each
/// effective identity field currently resolves from, so an override can never
/// be silent. Layers without any data are not claimed.
class CharacterScopeStatusCard extends ConsumerWidget {
  const CharacterScopeStatusCard({super.key, required this.characterId});

  final String characterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final states = ref.watch(characterScopeStatesProvider(characterId));

    return VoidCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Character Scope', style: VoidTypography.headingMedium),
            const SizedBox(height: 12),
            states.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Loading scopes...'),
              ),
              error: (error, _) => Text('Scope error: $error'),
              data: (map) {
                if (map.isEmpty) {
                  return const SizedBox.shrink();
                }
                final canonical =
                    map[CharacterScopeLayer.canonical] ??
                    const CharacterScopeState.empty();
                final universe =
                    map[CharacterScopeLayer.universeTimeline] ??
                    const CharacterScopeState.empty();
                final novel =
                    map[CharacterScopeLayer.novelSpecific] ??
                    const CharacterScopeState.empty();

                final rows = <Widget>[];
                void addLayerBadge(
                  CharacterScopeLayer layer,
                  CharacterScopeState s,
                ) {
                  final hasData =
                      s.identity != null ||
                      s.baseVoice != null ||
                      s.baseVisualProfile != null ||
                      s.baseRelationReferences != null ||
                      s.alternateHistory != null ||
                      s.alternateRelationships != null ||
                      s.eraSpecificFacts != null ||
                      s.role != null ||
                      s.arc != null ||
                      s.currentLocation != null ||
                      s.currentAge != null ||
                      s.currentStatus != null ||
                      s.scenePov != null ||
                      s.novelRelationState != null;
                  if (!hasData) return;
                  rows.add(
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Chip(
                        label: Text(_scopeLabel(layer)),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  );
                }

                String sourceOf(
                  String? novelV,
                  String? universeV,
                  String? canonicalV,
                ) {
                  if (novelV != null) {
                    return _scopeLabel(CharacterScopeLayer.novelSpecific);
                  }
                  if (universeV != null) {
                    return _scopeLabel(CharacterScopeLayer.universeTimeline);
                  }
                  return _scopeLabel(CharacterScopeLayer.canonical);
                }

                void addSourceRow(
                  String label,
                  String? novelV,
                  String? universeV,
                  String? canonicalV,
                ) {
                  final effective = novelV ?? universeV ?? canonicalV;
                  if (effective == null) return;
                  final source = sourceOf(novelV, universeV, canonicalV);
                  rows.add(
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '$label $effective (from $source)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }

                addLayerBadge(CharacterScopeLayer.canonical, canonical);
                addLayerBadge(CharacterScopeLayer.universeTimeline, universe);
                addLayerBadge(CharacterScopeLayer.novelSpecific, novel);

                addSourceRow(
                  'Identity:',
                  novel.identity,
                  universe.identity,
                  canonical.identity,
                );
                addSourceRow(
                  'Voice:',
                  novel.baseVoice,
                  universe.baseVoice,
                  canonical.baseVoice,
                );
                addSourceRow(
                  'Role:',
                  novel.role,
                  universe.role,
                  canonical.role,
                );
                addSourceRow(
                  'Status:',
                  novel.currentStatus,
                  universe.currentStatus,
                  canonical.currentStatus,
                );
                addSourceRow(
                  'Location:',
                  novel.currentLocation,
                  universe.currentLocation,
                  canonical.currentLocation,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: rows,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
