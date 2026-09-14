import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:void_scriptor/design_system/theme/void_theme_context.dart';
import '../../../database/project/project_database.dart';
import '../../project_resilience/application/project_session_manager.dart';
import '../../projects/presentation/project_persistence_providers.dart';
import '../application/bible_timeline_repository.dart';
import '../application/create_faction_service.dart';
import '../application/faction_repository.dart';
import '../domain/timeline_era.dart';
import '../domain/faction.dart';
import '../../relations/application/character_relation_map_service.dart';

const _projectBibleSections = <String>[
  'Universe Overview',
  'Canon Rules',
  'Worldbuilding',
  'Factions',
  'Timeline / Eras',
  'Canon Conflicts',
];

class ProjectBibleWorkspaceScreen extends ConsumerStatefulWidget {
  const ProjectBibleWorkspaceScreen({super.key});

  @override
  ConsumerState<ProjectBibleWorkspaceScreen> createState() =>
      _ProjectBibleWorkspaceScreenState();
}

class _ProjectBibleWorkspaceScreenState
    extends ConsumerState<ProjectBibleWorkspaceScreen> {
  int _selectedSection = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 760;
            return SingleChildScrollView(
              padding: EdgeInsets.all(narrow ? 16 : 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(narrow: narrow),
                      const SizedBox(height: 20),
                      if (narrow)
                        _SectionDropdown(
                          value: _projectBibleSections[_selectedSection],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedSection = _projectBibleSections.indexOf(
                                value,
                              );
                            });
                          },
                        )
                      else
                        _SectionTabs(
                          selectedIndex: _selectedSection,
                          onSelected: (index) =>
                              setState(() => _selectedSection = index),
                        ),
                      const SizedBox(height: 20),
                      _OverviewGrid(narrow: narrow),
                      const SizedBox(height: 16),
                      const _FactionsSection(),
                      const SizedBox(height: 16),
                      const _RelationMapSection(),
                      const SizedBox(height: 16),
                      if (narrow)
                        const Column(
                          children: [
                            _CanonHealthCard(),
                            SizedBox(height: 16),
                            _ConflictCard(),
                            SizedBox(height: 16),
                            _TimelineCard(),
                          ],
                        )
                      else
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _CanonHealthCard()),
                            SizedBox(width: 16),
                            Expanded(child: _ConflictCard()),
                            SizedBox(width: 16),
                            Expanded(child: _TimelineCard()),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.narrow});
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    final navigator = Navigator.of(context);
    final canPop = router?.canPop() ?? navigator.canPop();
    final pop = router?.pop ?? navigator.maybePop;
    final title = Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: canPop ? pop : null,
          icon: const Icon(Icons.arrow_back),
        ),
        Icon(Icons.menu_book_outlined, color: context.palette.primaryBright),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'PROJECT BIBLE',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.palette.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ),
      ],
    );
    final subtitle = Text(
      'Canon database and worldbuilding system',
      style: TextStyle(color: context.palette.textMuted),
    );
    return narrow
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 4), subtitle],
          )
        : Row(
            children: [
              Expanded(child: title),
              subtitle,
            ],
          );
  }
}

class _SectionTabs extends StatelessWidget {
  const _SectionTabs({required this.selectedIndex, required this.onSelected});
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: List.generate(
      _projectBibleSections.length,
      (index) => ChoiceChip(
        label: Text(_projectBibleSections[index]),
        selected: selectedIndex == index,
        onSelected: (_) => onSelected(index),
      ),
    ),
  );
}

class _SectionDropdown extends StatelessWidget {
  const _SectionDropdown({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    decoration: const InputDecoration(labelText: 'Bible Section'),
    items: _projectBibleSections
        .map((item) => DropdownMenuItem(value: item, child: Text(item)))
        .toList(growable: false),
    onChanged: onChanged,
  );
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.narrow});
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    const cards = [
      _MetricCard(
        label: 'Universe',
        value: 'Void Universe',
        icon: Icons.public,
      ),
      _MetricCard(
        label: 'Canon Entries',
        value: '0',
        icon: Icons.library_books_outlined,
      ),
      _MetricCard(
        label: 'Worldbuilding',
        value: '0 entities',
        icon: Icons.account_tree_outlined,
      ),
      _MetricCard(label: 'Historical Events', value: '0', icon: Icons.history),
    ];
    return GridView.count(
      crossAxisCount: narrow ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: narrow ? 0.65 : 1.0,
      children: cards,
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => _BibleCard(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: context.palette.primaryBright),
        const SizedBox(height: 12),
        Text(label, style: TextStyle(color: context.palette.textMuted)),
        const SizedBox(height: 4),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.palette.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _CanonHealthCard extends StatelessWidget {
  const _CanonHealthCard();
  @override
  Widget build(BuildContext context) => _BibleCard(
    title: 'CANON HEALTH',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '100%',
          style: TextStyle(
            color: context.palette.success,
            fontSize: 32,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'No unresolved conflicts',
          style: TextStyle(color: context.palette.textSecondary),
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: 1,
          color: context.palette.success,
          backgroundColor: context.palette.border,
        ),
      ],
    ),
  );
}

class _ConflictCard extends StatelessWidget {
  const _ConflictCard();
  @override
  Widget build(BuildContext context) => _BibleCard(
    title: 'CANON CONFLICTS',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.check_circle_outline,
            color: context.palette.success,
          ),
          title: const Text('Conflict detector ready'),
          subtitle: const Text('Run a scan to validate project canon.'),
        ),
        const Chip(label: Text('0 unresolved')),
      ],
    ),
  );
}

class _TimelineCard extends ConsumerWidget {
  const _TimelineCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(projectSessionProvider).valueOrNull;
    if (session == null) {
      return const _BibleCard(
        title: 'TIMELINE / ERAS',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.timeline),
              title: Text('No project session'),
              subtitle: Text('Open a project to manage its timeline.'),
            ),
          ],
        ),
      );
    }
    return FutureBuilder<List<TimelineEraModel>>(
      future: BibleTimelineRepository(
        session.database,
      ).listEras(session.manifest.id),
      builder: (context, snapshot) {
        final eras = snapshot.data ?? const [];
        return _BibleCard(
          title: 'TIMELINE / ERAS',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eras.isEmpty)
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.timeline),
                  title: Text('No eras yet'),
                  subtitle: Text(
                    'Create eras in the Worldbuilding workspace to build chronology.',
                  ),
                )
              else
                for (final eraItem in eras.take(5))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.timeline),
                    title: Text(eraItem.name),
                    subtitle: Text(
                      [
                        eraItem.startLabel,
                        eraItem.endLabel,
                      ].where((s) => s != null && s.isNotEmpty).join(' - '),
                    ),
                  ),
              // run243: chip jujur - jumlah era nyata, bukan klaim statis
              // "Timeline ready" yang dulu tampil bahkan saat tabel kosong.
              Chip(label: Text('${eras.length} era(s)')),
            ],
          ),
        );
      },
    );
  }
}

class _FactionsSection extends ConsumerStatefulWidget {
  const _FactionsSection();

  @override
  ConsumerState<_FactionsSection> createState() => _FactionsSectionState();
}

class _FactionsSectionState extends ConsumerState<_FactionsSection> {
  List<FactionModel>? _factions;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final session = ref.read(projectSessionProvider).valueOrNull;
    if (session == null) {
      if (mounted && _factions != null) setState(() => _factions = null);
      return;
    }
    final projectId = session.manifest.id;
    final factions = await FactionRepository(
      session.database,
    ).listForProject(projectId);
    if (!mounted) return;
    // Reject a late result from a project that is no longer active.
    if (ref.read(projectSessionProvider).valueOrNull?.manifest.id !=
        projectId) {
      return;
    }
    setState(() => _factions = factions);
  }

  Future<void> _createFaction() async {
    final session = ref.read(projectSessionProvider).valueOrNull;
    if (session == null) return;
    final created = await showDialog<FactionModel>(
      context: context,
      builder: (_) => _CreateFactionDialog(
        db: session.database,
        projectId: session.manifest.id,
      ),
    );
    if (created == null) return;
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Faksi "${created.name}" dibuat')));
  }

  @override
  Widget build(BuildContext context) {
    // The session provider resolves asynchronously; reload once it appears so
    // the first frame never permanently shows the loading state. Reload again
    // whenever the active project identity changes (BUI-BUG-03: a direct
    // A -> B switch must never leave project A's rows on screen).
    ref.listen<AsyncValue<ProjectSession?>>(projectSessionProvider, (
      previous,
      next,
    ) {
      final previousId = previous?.valueOrNull?.manifest.id;
      final nextId = next.valueOrNull?.manifest.id;
      if (previousId != nextId) {
        _reload();
      }
    });
    final narrow = MediaQuery.sizeOf(context).width < 760;
    final factions = _factions;
    return _BibleCard(
      title: 'FACTIONS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (factions == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Memuat faksi...'),
            )
          else if (factions.isEmpty)
            const Text('Belum ada faksi')
          else ...[
            for (final faction in factions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _FactionCard(faction: faction, narrow: narrow),
              ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: narrow ? Alignment.centerLeft : Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _createFaction,
              icon: const Icon(Icons.add),
              label: const Text('Faksi Baru'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FactionCard extends StatelessWidget {
  const _FactionCard({required this.faction, required this.narrow});

  final FactionModel faction;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final details = <String>[
      if (faction.ideology.isNotEmpty) faction.ideology,
      if (faction.status.isNotEmpty) 'Status: ${faction.status}',
      if (faction.headquarters.isNotEmpty) faction.headquarters,
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.borderSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.groups_outlined, color: palette.primaryBright),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  faction.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    details.join('  |  '),
                    overflow: narrow ? TextOverflow.ellipsis : null,
                    maxLines: narrow ? 1 : 3,
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 12,
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
}

class _CreateFactionDialog extends StatefulWidget {
  const _CreateFactionDialog({required this.db, required this.projectId});

  final ProjectDatabase db;
  final String projectId;

  @override
  State<_CreateFactionDialog> createState() => _CreateFactionDialogState();
}

class _CreateFactionDialogState extends State<_CreateFactionDialog> {
  final _nameController = TextEditingController();
  final _ideologyController = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ideologyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final created = await const CreateFactionService().create(
        widget.db,
        projectId: widget.projectId,
        name: _nameController.text,
        ideology: _ideologyController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } on ArgumentError {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Nama tidak boleh kosong.';
      });
    } on StateError catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Gagal membuat faksi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AlertDialog(
      backgroundColor: palette.panelSecondary,
      title: Text('Faksi Baru', style: TextStyle(color: palette.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const ValueKey('faction_name'),
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nama Faksi',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('faction_ideology'),
            controller: _ideologyController,
            decoration: const InputDecoration(labelText: 'Ideologi'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _RelationMapSection extends ConsumerStatefulWidget {
  const _RelationMapSection();

  @override
  ConsumerState<_RelationMapSection> createState() =>
      _RelationMapSectionState();
}

class _RelationMapSectionState extends ConsumerState<_RelationMapSection> {
  List<CharacterRelationMapEntry>? _entries;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final session = ref.read(projectSessionProvider).valueOrNull;
    if (session == null) {
      if (mounted && _entries != null) setState(() => _entries = null);
      return;
    }
    final projectId = session.manifest.id;
    final entries = await const CharacterRelationMapService().mapForProject(
      session.database,
      projectId: projectId,
    );
    if (!mounted) return;
    // Reject a late result from a project that is no longer active.
    if (ref.read(projectSessionProvider).valueOrNull?.manifest.id !=
        projectId) {
      return;
    }
    setState(() => _entries = entries);
  }

  @override
  Widget build(BuildContext context) {
    // The session provider resolves asynchronously; reload once it appears so
    // the first frame never permanently shows the loading state. Reload again
    // whenever the active project identity changes (BUI-BUG-03).
    ref.listen<AsyncValue<ProjectSession?>>(projectSessionProvider, (
      previous,
      next,
    ) {
      final previousId = previous?.valueOrNull?.manifest.id;
      final nextId = next.valueOrNull?.manifest.id;
      if (previousId != nextId) {
        _reload();
      }
    });
    final narrow = MediaQuery.sizeOf(context).width < 760;
    final entries = _entries;
    return _BibleCard(
      title: 'RELATIONSHIP MAP',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (entries == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Memuat relasi...'),
            )
          else if (entries.isEmpty)
            const Text('Belum ada relasi karakter')
          else ...[
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RelationMapCard(entry: entry, narrow: narrow),
              ),
          ],
        ],
      ),
    );
  }
}

class _RelationMapCard extends StatelessWidget {
  const _RelationMapCard({required this.entry, required this.narrow});

  final CharacterRelationMapEntry entry;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.borderSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.hub_outlined, color: palette.primaryBright),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.sourceName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.typeLabel,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.primaryBright,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.targetName,
                  overflow: narrow ? TextOverflow.ellipsis : null,
                  maxLines: narrow ? 1 : 3,
                  style: TextStyle(color: palette.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BibleCard extends StatelessWidget {
  const _BibleCard({required this.child, this.title});
  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    color: context.palette.panelSecondary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: TextStyle(
                color: context.palette.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    ),
  );
}
