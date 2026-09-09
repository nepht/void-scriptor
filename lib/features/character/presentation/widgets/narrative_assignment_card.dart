import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';
import '../../../character_mode/presentation/character_mode_controller.dart';
import '../../../projects/presentation/project_persistence_providers.dart';
import '../../../workspaces/application/narrative_assignment_repository.dart';
import '../../../workspaces/domain/narrative_assignment.dart';
import '../../../../database/project/project_database.dart' as data;

/// One selectable novel (story context) for narrative assignment editing.
class NarrativeNovelOption {
  const NarrativeNovelOption({required this.id, required this.name});

  final String id;
  final String name;
}

typedef NarrativeAssignmentRepositoryFactory =
    NarrativeAssignmentRepository Function(
      data.ProjectDatabase database,
      String projectId,
    );

/// Test-overridable construction seam for the narrative repository. The
/// default factory builds the storage-backed repository bound to the active
/// project session; widget tests override it to inject a deterministic
/// double. Mirrors the repo's established pattern of test-overridable
/// providers (e.g. currentProjectIdProvider).
final narrativeAssignmentRepositoryFactoryProvider =
    Provider<NarrativeAssignmentRepositoryFactory>(
      (ref) =>
          (database, projectId) => NarrativeAssignmentRepository(
            database: database,
            projectId: projectId,
          ),
    );

/// Story context for the character's narrative assignments: the active
/// project's story assets (the same records the Novel workspace opens).
final narrativeNovelOptionsProvider =
    FutureProvider<List<NarrativeNovelOption>>((ref) async {
      final session = ref.watch(projectSessionProvider).valueOrNull;
      if (session == null) return const [];
      final assets = await ref.watch(projectAssetsProvider.future);
      return assets
          .where((asset) => asset.type == 'story')
          .map((asset) => NarrativeNovelOption(id: asset.id, name: asset.name))
          .toList(growable: false);
    });

/// Backlog `character-roles-support` phase_one UI: edit narrative role,
/// importance and POV per novel in the Character Workspace with a visible
/// story context. One character keeps one profile; assignments are keyed per
/// novel, so editing one novel never touches another. Saving with no roles
/// selected removes the assignment for the selected novel only (optional
/// fields default to unspecified; clearing never deletes character data).
class NarrativeAssignmentCard extends ConsumerStatefulWidget {
  const NarrativeAssignmentCard({super.key, required this.characterId});

  final String characterId;

  @override
  ConsumerState<NarrativeAssignmentCard> createState() =>
      _NarrativeAssignmentCardState();
}

class _NarrativeAssignmentCardState
    extends ConsumerState<NarrativeAssignmentCard> {
  String? _selectedNovelId;
  NarrativeNovelOption? _selectedNovel;
  Set<NarrativeRole> _roles = <NarrativeRole>{};
  NarrativeImportance _importance = NarrativeImportance.unspecified;
  NarrativePov _pov = NarrativePov.unspecified;
  bool _loadedForCurrentNovel = false;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  /// Terminal failure marker for the current load (hunt-run157 BUG-08): a
  /// failed load must REPLACE the editor with an explicit error + Retry
  /// control instead of leaving the eternal "Loading assignment..." line
  /// rendered alongside the error.
  bool _failed = false;

  /// Monotonic request token for [NarrativeNovelOption] loads. A completion
  /// from an older token (superseded by a newer novel pick or a character
  /// switch) must never write editor state — a stale completion left
  /// unguarded used to leave another novel's roles in [_roles], which Save
  /// then persisted under the CURRENT novel's coordinates (hunt-run157
  /// BUG-01, Referee REAL BUG Medium).
  int _loadEpoch = 0;

  @override
  void didUpdateWidget(NarrativeAssignmentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.characterId != widget.characterId) {
      _loadEpoch++;
      _selectedNovelId = null;
      _selectedNovel = null;
      _loadedForCurrentNovel = false;
      _roles = <NarrativeRole>{};
      _importance = NarrativeImportance.unspecified;
      _pov = NarrativePov.unspecified;
      _failed = false;
      _error = null;
    }
  }

  NarrativeAssignmentRepository? _repository() {
    final session = ref.read(projectSessionProvider).valueOrNull;
    if (session == null) return null;
    return NarrativeAssignmentRepository(
      database: session.database,
      projectId: session.manifest.id,
    );
  }

  Future<void> _loadFor(NarrativeNovelOption novel) async {
    final epoch = ++_loadEpoch;
    final characterId = widget.characterId;
    final session = ref.read(projectSessionProvider).valueOrNull;
    if (session == null) {
      // hunt-run157 BUG-09: a vanished session between the options-provider
      // build and this pick used to return silently, leaving the card stuck
      // on "Loading assignment..." with no error. Surface it explicitly.
      setState(() {
        _error = 'No project session.';
        _failed = true;
        _loading = false;
      });
      return;
    }
    final repositoryFactory = ref.read(
      narrativeAssignmentRepositoryFactoryProvider,
    );
    final repo = repositoryFactory(session.database, session.manifest.id);
    setState(() {
      _loading = true;
      _error = null;
      _failed = false;
    });
    try {
      final assignment = await repo.getAssignment(
        novelWorkspaceId: novel.id,
        characterId: characterId,
      );
      if (!mounted || epoch != _loadEpoch) return;
      setState(() {
        _roles = assignment?.roles ?? <NarrativeRole>{};
        _importance = assignment?.importance ?? NarrativeImportance.unspecified;
        _pov = assignment?.pov ?? NarrativePov.unspecified;
        _loadedForCurrentNovel = true;
        _loading = false;
        _failed = false;
      });
    } catch (error) {
      if (!mounted || epoch != _loadEpoch) return;
      setState(() {
        _error = '$error';
        // Terminal failed state: the build renders error + Retry INSTEAD of
        // the editor and the eternal loading line (BUG-08).
        _failed = true;
        _loading = false;
      });
    }
  }

  /// Retry after a terminal load failure: re-run the load for the currently
  /// selected novel (hunt-run157 BUG-08).
  void _retryLoad() {
    final novel = _selectedNovel;
    if (novel == null) return;
    _loadFor(novel);
  }

  Future<void> _save() async {
    final repo = _repository();
    final novel = _selectedNovel;
    if (repo == null || novel == null || _saving) return;
    setState(() => _saving = true);
    try {
      if (_roles.isEmpty) {
        await repo.removeAssignment(
          novelWorkspaceId: novel.id,
          characterId: widget.characterId,
        );
      } else {
        await repo.saveAssignment(
          NarrativeAssignment(
            novelWorkspaceId: novel.id,
            characterId: widget.characterId,
            roles: _roles,
            importance: _importance,
            pov: _pov,
          ),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Narrative assignment saved.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _selectNovel(NarrativeNovelOption novel) {
    setState(() {
      _selectedNovelId = novel.id;
      _selectedNovel = novel;
      _loadedForCurrentNovel = false;
    });
    _loadFor(novel);
  }

  @override
  Widget build(BuildContext context) {
    final novels = ref.watch(narrativeNovelOptionsProvider);
    return novels.when(
      loading: () => const VoidCard(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Narrative Assignment', style: VoidTypography.headingMedium),
              SizedBox(height: 12),
              Text('Loading novels...'),
            ],
          ),
        ),
      ),
      error: (error, _) => VoidCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Narrative Assignment',
                style: VoidTypography.headingMedium,
              ),
              const SizedBox(height: 12),
              Text('Could not load novels: $error'),
            ],
          ),
        ),
      ),
      data: (options) {
        if (options.isEmpty) {
          return const VoidCard(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Narrative Assignment',
                    style: VoidTypography.headingMedium,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No novels yet. Create a novel first to assign '
                    'narrative roles.',
                  ),
                ],
              ),
            ),
          );
        }
        final hasSelected = options.any(
          (option) => option.id == _selectedNovelId,
        );
        if (!hasSelected) {
          // Initial pick, or the selected novel disappeared from the project:
          // repair the selection after the build (never setState in build).
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _selectNovel(options.first);
          });
        }
        return _buildCard(options, hasSelected ? _selectedNovelId : null);
      },
    );
  }

  Widget _buildCard(
    List<NarrativeNovelOption> options,
    String? effectiveNovelId,
  ) => VoidCard(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Narrative Assignment',
            style: VoidTypography.headingMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Roles, importance and POV per novel. Empty roles remove the '
            'assignment for the selected novel.',
            style: VoidTypography.caption,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Novel'),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: effectiveNovelId,
                  items: options
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option.id,
                          child: Text(
                            option.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (id) {
                    final novel = options.firstWhere(
                      (option) => option.id == id,
                    );
                    _selectNovel(novel);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_failed) ...[
            Text('Could not load assignment: $_error'),
            const SizedBox(height: 8),
            ActionChip(
              avatar: const Icon(Icons.refresh, size: 14),
              label: const Text('Retry'),
              onPressed: _retryLoad,
            ),
          ] else if (_loading || !_loadedForCurrentNovel)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Loading assignment...'),
            )
          else ...[
            const Text('Roles'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final role in NarrativeRole.values)
                  FilterChip(
                    label: Text(roleLabel(role)),
                    selected: _roles.contains(role),
                    onSelected: (selected) => setState(() {
                      selected ? _roles.add(role) : _roles.remove(role);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Importance'),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<NarrativeImportance>(
                    isExpanded: true,
                    value: _importance,
                    items: [
                      for (final value in NarrativeImportance.values)
                        DropdownMenuItem<NarrativeImportance>(
                          value: value,
                          child: Text(importanceLabel(value)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _importance = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('POV'),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<NarrativePov>(
                    isExpanded: true,
                    value: _pov,
                    items: [
                      for (final value in NarrativePov.values)
                        DropdownMenuItem<NarrativePov>(
                          value: value,
                          child: Text(povLabel(value)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _pov = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: const Text('Save'),
            ),
          ],
        ],
      ),
    ),
  );
}

String roleLabel(NarrativeRole role) => switch (role) {
  NarrativeRole.protagonist => 'Protagonist',
  NarrativeRole.antagonist => 'Antagonist',
  NarrativeRole.supporting => 'Supporting',
  NarrativeRole.background => 'Background',
};

String importanceLabel(NarrativeImportance importance) => switch (importance) {
  NarrativeImportance.major => 'Major',
  NarrativeImportance.supporting => 'Supporting',
  NarrativeImportance.minor => 'Minor',
  NarrativeImportance.unspecified => '—',
};

String povLabel(NarrativePov pov) => switch (pov) {
  NarrativePov.yes => 'Yes',
  NarrativePov.no => 'No',
  NarrativePov.unspecified => '—',
};
