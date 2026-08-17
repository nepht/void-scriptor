import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

const _projectBibleSections = <String>[
  'Universe Overview',
  'Canon Rules',
  'Worldbuilding',
  'Timeline / Eras',
  'Canon Conflicts',
];

class ProjectBibleWorkspaceScreen extends StatefulWidget {
  const ProjectBibleWorkspaceScreen({super.key});

  @override
  State<ProjectBibleWorkspaceScreen> createState() =>
      _ProjectBibleWorkspaceScreenState();
}

class _ProjectBibleWorkspaceScreenState
    extends State<ProjectBibleWorkspaceScreen> {
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

class _TimelineCard extends StatelessWidget {
  const _TimelineCard();
  @override
  Widget build(BuildContext context) => _BibleCard(
    title: 'TIMELINE / ERAS',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.timeline, color: context.palette.primaryBright),
          title: const Text('No eras yet'),
          subtitle: const Text(
            'Create eras and historical events to build chronology.',
          ),
        ),
        const Chip(label: Text('Timeline ready')),
      ],
    ),
  );
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
