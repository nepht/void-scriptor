import 'package:flutter/material.dart';

import '../../../design_system/colors/void_colors.dart';

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
      backgroundColor: VoidColors.background,
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
    const title = Row(
      children: [
        Icon(Icons.menu_book_outlined, color: VoidColors.primaryBright),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'PROJECT BIBLE',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: VoidColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ),
      ],
    );
    const subtitle = Text(
      'Canon database and worldbuilding system',
      style: TextStyle(color: VoidColors.textMuted),
    );
    return narrow
        ? const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, SizedBox(height: 4), subtitle],
          )
        : const Row(
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
        Icon(icon, color: VoidColors.primaryBright),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: VoidColors.textMuted)),
        const SizedBox(height: 4),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: VoidColors.textPrimary,
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
  Widget build(BuildContext context) => const _BibleCard(
    title: 'CANON HEALTH',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '100%',
          style: TextStyle(
            color: VoidColors.success,
            fontSize: 32,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'No unresolved conflicts',
          style: TextStyle(color: VoidColors.textSecondary),
        ),
        SizedBox(height: 16),
        LinearProgressIndicator(
          value: 1,
          color: VoidColors.success,
          backgroundColor: VoidColors.border,
        ),
      ],
    ),
  );
}

class _ConflictCard extends StatelessWidget {
  const _ConflictCard();
  @override
  Widget build(BuildContext context) => const _BibleCard(
    title: 'CANON CONFLICTS',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.check_circle_outline, color: VoidColors.success),
          title: Text('Conflict detector ready'),
          subtitle: Text('Run a scan to validate project canon.'),
        ),
        Chip(label: Text('0 unresolved')),
      ],
    ),
  );
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard();
  @override
  Widget build(BuildContext context) => const _BibleCard(
    title: 'TIMELINE / ERAS',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.timeline, color: VoidColors.primaryBright),
          title: Text('No eras yet'),
          subtitle: Text(
            'Create eras and historical events to build chronology.',
          ),
        ),
        Chip(label: Text('Timeline ready')),
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
    color: VoidColors.panelSecondary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                color: VoidColors.textMuted,
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
