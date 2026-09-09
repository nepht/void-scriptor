import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/project/project_database.dart';
import '../../../../design_system/theme/void_theme_context.dart';
import '../../../character_mode/presentation/character_mode_controller.dart';
import '../../../projects/presentation/project_persistence_providers.dart';
import '../../../workspaces/application/narrative_assignment_repository.dart';
import '../../../workspaces/domain/narrative_assignment.dart';

/// One selectable novel (story context) for support relationships.
class SupportNovelOption {
  const SupportNovelOption({required this.id, required this.name});
  final String id;
  final String name;
}

/// Story context for the character's support relationships: the active
/// project's story assets (the same records the Novel workspace opens).
/// Derives from the project asset graph (like narrativeNovelOptionsProvider)
/// instead of a raw DAO snapshot, so a novel created mid-session appears
/// here as soon as that graph is refreshed (hunt-run157 BUG-05).
final supportNovelOptionsProvider = FutureProvider<List<SupportNovelOption>>((
  ref,
) async {
  final session = ref.watch(projectSessionProvider).valueOrNull;
  if (session == null) return const [];
  final assets = await ref.watch(projectAssetsProvider.future);
  return assets
      .where((asset) => asset.type == 'story')
      .map((asset) => SupportNovelOption(id: asset.id, name: asset.name))
      .toList(growable: false);
});

/// Relationships surface for backlog `character-roles-support` phase_one
/// item 2: edit support relationship attributes (type/duration/status and
/// optional purpose/separation reason) from the character Inspector.
/// Persistence runs through the production [NarrativeAssignmentRepository]
/// keyed on (project, source, supported, story), so editing one row can
/// never touch another relationship or the narrative assignment fields.
class SupportRelationshipSection extends ConsumerStatefulWidget {
  const SupportRelationshipSection({super.key, required this.assetId});

  final String assetId;

  @override
  ConsumerState<SupportRelationshipSection> createState() =>
      _SupportRelationshipSectionState();
}

class _SupportRelationshipSectionState
    extends ConsumerState<SupportRelationshipSection> {
  List<SupportRelationship>? _supports;
  Map<String, String> _characterNames = const {};
  String? _loadedSessionId;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(SupportRelationshipSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetId != widget.assetId) {
      // Character switched in place (no key change): drop this character's
      // stale rows immediately so the next frame can never render the
      // previous character's relationships (hunt-run157 referee observation),
      // then reload for the new asset.
      _supports = null;
      _characterNames = const {};
      _load();
    }
  }

  Future<void> _load() async {
    final session = ref.read(projectSessionProvider).valueOrNull;
    if (session == null || !mounted) {
      if (mounted) {
        setState(() {
          _supports = const [];
          _characterNames = const {};
          _loadError = null;
        });
      }
      return;
    }
    final repository = NarrativeAssignmentRepository(
      database: session.database,
      projectId: session.manifest.id,
    );
    try {
      final supports = await repository.listSupports(widget.assetId);
      final assets = await session.database.assetDao.getAllAssets();
      if (!mounted) return;
      setState(() {
        _supports = supports;
        _loadedSessionId = session.manifest.id;
        _characterNames = {
          for (final asset in assets.where((a) => a.type == 'character'))
            asset.id: asset.name,
        };
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      // Failure is a distinct state: never render a fake empty list that
      // would hide real relationships behind "No support relationships yet".
      setState(() {
        _supports = null;
        _loadError = '$error';
      });
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

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(projectSessionProvider).valueOrNull;
    final sessionId = session?.manifest.id;
    if (sessionId != _loadedSessionId) {
      // Project switched under this section: drop stale rows and reload so a
      // selection can never render another project's relationships.
      _loadedSessionId = sessionId;
      _supports = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _load();
        }
      });
    }
    final supports = _supports;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Support',
                style: TextStyle(
                  color: context.palette.primaryBright,
                  fontSize: 13,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: session == null ? null : () => _addSupport(),
              icon: const Icon(Icons.add, size: 15),
              label: const Text('Add Support'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_loadError != null) ...[
          Text(
            'Support relationships failed to load: $_loadError',
            style: TextStyle(color: context.palette.danger),
          ),
          const SizedBox(height: 4),
          ActionChip(
            avatar: const Icon(Icons.refresh, size: 14),
            label: const Text('Retry'),
            onPressed: _load,
          ),
        ] else if (supports == null)
          Text('Loading...', style: TextStyle(color: context.palette.textMuted))
        else if (supports.isEmpty)
          Text(
            'No support relationships yet',
            style: TextStyle(color: context.palette.textMuted),
          )
        else
          ...supports.map((support) => _supportRow(context, support)),
      ],
    );
  }

  Widget _supportRow(BuildContext context, SupportRelationship support) {
    final supportedName =
        _characterNames[support.supportedId] ?? support.supportedId;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.volunteer_activism_outlined, size: 16),
      title: Text(supportedName),
      subtitle: Text(
        '${support.type.wireName} · ${support.duration.wireName} · '
        '${support.status.wireName}',
        style: TextStyle(color: context.palette.textMuted),
      ),
      trailing: IconButton(
        tooltip: 'Delete support',
        icon: const Icon(Icons.delete_outline, size: 16),
        color: context.palette.textMuted,
        onPressed: () => _deleteSupport(support, supportedName),
      ),
      onTap: () => _editSupport(support),
    );
  }

  Future<void> _addSupport() async {
    final repository = _repository();
    if (repository == null || !mounted) return;
    final result = await _showEditDialog(repository, null);
    if (result == null || !mounted) return;
    try {
      await repository.saveSupport(result);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save support relationship: $error')),
      );
      return;
    }
    await _load();
  }

  Future<void> _editSupport(SupportRelationship support) async {
    final repository = _repository();
    if (repository == null || !mounted) return;
    final result = await _showEditDialog(repository, support);
    if (result == null || !mounted) return;
    try {
      if (result.supportedId != support.supportedId ||
          result.storyNovelWorkspaceId != support.storyNovelWorkspaceId) {
        // Coordinates changed (picker locked, defensive): drop the old row so
        // the edit cannot duplicate a relationship under new coordinates.
        await repository.removeSupport(
          sourceCharacterId: support.sourceCharacterId,
          supportedId: support.supportedId,
          storyNovelWorkspaceId: support.storyNovelWorkspaceId,
        );
      }
      await repository.saveSupport(result);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save support relationship: $error')),
      );
      return;
    }
    await _load();
  }

  Future<void> _deleteSupport(
    SupportRelationship support,
    String supportedName,
  ) async {
    final repository = _repository();
    if (repository == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete support?'),
        content: Text(
          'This removes only the support relationship. $supportedName '
          'will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete support'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await repository.removeSupport(
        sourceCharacterId: support.sourceCharacterId,
        supportedId: support.supportedId,
        storyNovelWorkspaceId: support.storyNovelWorkspaceId,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete support relationship: $error'),
        ),
      );
      return;
    }
    await _load();
  }

  Future<SupportRelationship?> _showEditDialog(
    NarrativeAssignmentRepository repository,
    SupportRelationship? initial,
  ) async {
    final List<SupportNovelOption> novels;
    final List<Asset> characters;
    try {
      novels = await ref.read(supportNovelOptionsProvider.future);
      final assets = await repository.database.assetDao.getAllAssets();
      characters = assets
          .where(
            (asset) => asset.type == 'character' && asset.id != widget.assetId,
          )
          .toList(growable: false);
    } catch (error) {
      if (!mounted) return null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to open editor: $error')));
      return null;
    }
    if (!mounted) return null;
    return showDialog<SupportRelationship>(
      context: context,
      builder: (dialogContext) => _SupportEditDialog(
        sourceCharacterId: widget.assetId,
        characters: characters,
        novels: novels,
        initial: initial,
      ),
    );
  }
}

class _SupportEditDialog extends StatefulWidget {
  const _SupportEditDialog({
    required this.sourceCharacterId,
    required this.characters,
    required this.novels,
    required this.initial,
  });

  final String sourceCharacterId;
  final List<Asset> characters;
  final List<SupportNovelOption> novels;
  final SupportRelationship? initial;

  @override
  State<_SupportEditDialog> createState() => _SupportEditDialogState();
}

class _SupportEditDialogState extends State<_SupportEditDialog> {
  String? _supportedId;
  String? _novelId;
  SupportType _type = SupportType.supporter;
  SupportDuration _duration = SupportDuration.unspecified;
  SupportStatus _status = SupportStatus.unspecified;
  final _purposeController = TextEditingController();
  final _separationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _supportedId = initial.supportedId;
      _novelId = initial.storyNovelWorkspaceId;
      _type = initial.type;
      _duration = initial.duration;
      _status = initial.status;
      _purposeController.text = initial.purpose ?? '';
      _separationController.text = initial.separationReason ?? '';
    }
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _separationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.initial == null ? 'Add Support' : 'Edit Support'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _supportedId,
              decoration: const InputDecoration(
                labelText: 'Supported character',
              ),
              items: widget.characters
                  .map(
                    (asset) => DropdownMenuItem(
                      value: asset.id,
                      child: Text(
                        asset.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: widget.initial == null
                  ? (value) => setState(() => _supportedId = value)
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _novelId,
              decoration: const InputDecoration(labelText: 'Story (novel)'),
              items: widget.novels
                  .map(
                    (novel) => DropdownMenuItem(
                      value: novel.id,
                      child: Text(
                        novel.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: widget.initial == null
                  ? (value) => setState(() => _novelId = value)
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<SupportType>(
              isExpanded: true,
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Support type'),
              items: SupportType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.wireName),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<SupportDuration>(
              isExpanded: true,
              initialValue: _duration,
              decoration: const InputDecoration(labelText: 'Duration'),
              items: SupportDuration.values
                  .map(
                    (duration) => DropdownMenuItem(
                      value: duration,
                      child: Text(duration.wireName),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _duration = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<SupportStatus>(
              isExpanded: true,
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: SupportStatus.values
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.wireName),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _status = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _purposeController,
              decoration: const InputDecoration(
                labelText: 'Purpose (optional)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _separationController,
              decoration: const InputDecoration(
                labelText: 'Separation reason (optional)',
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _supportedId == null || _novelId == null ? null : _save,
        child: const Text('Save Support'),
      ),
    ],
  );

  void _save() {
    final supportedId = _supportedId;
    final novelId = _novelId;
    if (supportedId == null || novelId == null) return;
    Navigator.of(context).pop(
      SupportRelationship(
        sourceCharacterId: widget.sourceCharacterId,
        supportedId: supportedId,
        storyNovelWorkspaceId: novelId,
        type: _type,
        duration: _duration,
        status: _status,
        purpose: _purposeController.text.trim().isEmpty
            ? null
            : _purposeController.text.trim(),
        separationReason: _separationController.text.trim().isEmpty
            ? null
            : _separationController.text.trim(),
      ),
    );
  }
}
