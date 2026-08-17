import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Switcher universe: dropdown universe di top bar + daftar universe
/// dengan detail universe aktif (Sprint 45 — Universe Registry).
class UniverseSwitcherScreen extends StatefulWidget {
  const UniverseSwitcherScreen({super.key});

  @override
  State<UniverseSwitcherScreen> createState() => _UniverseSwitcherScreenState();
}

class _UniverseSwitcherScreenState extends State<UniverseSwitcherScreen> {
  static const List<String> _universes = [
    'Canon Prime',
    'What If: Echoes',
    'Parallel Nexus',
    'Spin-Off: Embers',
  ];

  String _activeUniverse = _universes.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        title: Text(
          'Universe',
          style: VoidTypography.headingMedium.copyWith(
            color: context.palette.textPrimary,
          ),
        ),
        backgroundColor: context.palette.surface,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: VoidSpacing.md),
            child: Center(
              child: DropdownButton<String>(
                value: _activeUniverse,
                isDense: true,
                dropdownColor: context.palette.surfaceElevated,
                underline: const SizedBox.shrink(),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: context.palette.primary,
                ),
                style: VoidTypography.label.copyWith(
                  color: context.palette.textPrimary,
                ),
                items: [
                  for (final name in _universes)
                    DropdownMenuItem(
                      value: name,
                      child: Text(
                        name,
                        style: VoidTypography.label.copyWith(
                          color: context.palette.textPrimary,
                        ),
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _activeUniverse = value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VoidSpacing.lg),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final list = _UniverseListCard(
                universes: _universes,
                activeUniverse: _activeUniverse,
                onSelect: (name) {
                  setState(() => _activeUniverse = name);
                },
              );
              final detail = _UniverseDetailCard(
                universeName: _activeUniverse,
                isPrimary: _activeUniverse == _universes.first,
              );
              return wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 280, child: list),
                        const SizedBox(width: VoidSpacing.xl),
                        Expanded(child: detail),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        list,
                        const SizedBox(height: VoidSpacing.xl),
                        detail,
                      ],
                    );
            },
          ),
        ),
      ),
    );
  }
}

class _UniverseListCard extends StatelessWidget {
  const _UniverseListCard({
    required this.universes,
    required this.activeUniverse,
    required this.onSelect,
  });

  final List<String> universes;
  final String activeUniverse;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VoidSpacing.md),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.public, size: 18, color: context.palette.primary),
              const SizedBox(width: VoidSpacing.xs),
              Text(
                'Multiverse',
                style: VoidTypography.label.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: VoidSpacing.sm),
          for (final name in universes)
            _UniverseTile(
              name: name,
              selected: name == activeUniverse,
              onTap: () => onSelect(name),
            ),
        ],
      ),
    );
  }
}

class _UniverseTile extends StatelessWidget {
  const _UniverseTile({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VoidSpacing.xs,
          vertical: VoidSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 16,
              color: selected
                  ? context.palette.primary
                  : context.palette.textMuted,
            ),
            const SizedBox(width: VoidSpacing.sm),
            Expanded(
              child: Text(
                name,
                style: VoidTypography.body.copyWith(
                  color: selected
                      ? context.palette.textPrimary
                      : context.palette.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UniverseDetailCard extends StatelessWidget {
  const _UniverseDetailCard({
    required this.universeName,
    required this.isPrimary,
  });

  final String universeName;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VoidSpacing.lg),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Universe',
            style: VoidTypography.headingLarge.copyWith(
              color: context.palette.textPrimary,
            ),
          ),
          const SizedBox(height: VoidSpacing.xs),
          Text(
            'Canon isolation aktif: karakter, timeline, dan bible '
            'diisolasi per universe.',
            style: VoidTypography.caption.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
          const SizedBox(height: VoidSpacing.lg),
          _DetailRow(icon: Icons.public, label: 'Nama', value: universeName),
          const SizedBox(height: VoidSpacing.sm),
          _DetailRow(
            icon: Icons.star_outline,
            label: 'Status',
            value: isPrimary ? 'Primary' : 'Alternate',
          ),
          const SizedBox(height: VoidSpacing.sm),
          const _DetailRow(
            icon: Icons.timeline,
            label: 'Timeline',
            value: '3 timeline terhubung',
          ),
          const SizedBox(height: VoidSpacing.sm),
          const _DetailRow(
            icon: Icons.groups_outlined,
            label: 'Karakter',
            value: '12 karakter aktif',
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.palette.primary),
        const SizedBox(width: VoidSpacing.sm),
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: VoidTypography.caption.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: VoidTypography.body.copyWith(
              color: context.palette.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
