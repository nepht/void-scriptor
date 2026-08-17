import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Wizard portability: pilih assets dari universe sumber untuk di-port
/// ke universe target (Sprint 45 — Asset Portability).
class PortabilityWizardScreen extends StatefulWidget {
  const PortabilityWizardScreen({super.key});

  @override
  State<PortabilityWizardScreen> createState() =>
      _PortabilityWizardScreenState();
}

class _PortabilityWizardScreenState extends State<PortabilityWizardScreen> {
  static const List<String> _sourceUniverses = [
    'Canon Prime',
    'What If: Echoes',
    'Parallel Nexus',
  ];

  static const List<String> _targetUniverses = [
    'What If: Echoes',
    'Parallel Nexus',
    'Spin-Off: Embers',
  ];

  static const List<_PortAsset> _assets = [
    _PortAsset(
      name: 'Character: Arin Vale',
      kind: 'Character',
      universe: 'Canon Prime',
    ),
    _PortAsset(
      name: 'Environment: Obsidian Keep',
      kind: 'Environment',
      universe: 'Canon Prime',
    ),
    _PortAsset(
      name: 'Prop: Aether Blade',
      kind: 'Prop',
      universe: 'Canon Prime',
    ),
    _PortAsset(
      name: 'Timeline: Fall of Embers',
      kind: 'Timeline',
      universe: 'What If: Echoes',
    ),
  ];

  String _sourceUniverse = 'Canon Prime';
  String _targetUniverse = 'What If: Echoes';
  PortMode _mode = PortMode.reference;
  final Set<String> _selectedAssets = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        title: Text(
          'Portability Wizard',
          style: VoidTypography.headingMedium.copyWith(
            color: context.palette.textPrimary,
          ),
        ),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VoidSpacing.lg),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final selectPanel = _AssetSelectPanel(
                sourceUniverse: _sourceUniverse,
                targetUniverse: _targetUniverse,
                mode: _mode,
                assets: _assets,
                selectedAssets: _selectedAssets,
                onSourceChanged: (value) =>
                    setState(() => _sourceUniverse = value),
                onTargetChanged: (value) =>
                    setState(() => _targetUniverse = value),
                onModeChanged: (value) => setState(() => _mode = value),
                onAssetToggled: (assetId) {
                  setState(() {
                    if (!_selectedAssets.add(assetId)) {
                      _selectedAssets.remove(assetId);
                    }
                  });
                },
              );
              final summary = _PortSummaryPanel(
                selectedCount: _selectedAssets.length,
                sourceUniverse: _sourceUniverse,
                targetUniverse: _targetUniverse,
              );
              return wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: selectPanel),
                        const SizedBox(width: VoidSpacing.xl),
                        Expanded(flex: 2, child: summary),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        selectPanel,
                        const SizedBox(height: VoidSpacing.xl),
                        summary,
                      ],
                    );
            },
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(VoidSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.icon(
                onPressed: _selectedAssets.isEmpty ? null : () {},
                style: FilledButton.styleFrom(
                  backgroundColor: context.palette.primary,
                  foregroundColor: context.palette.textPrimary,
                  disabledBackgroundColor: context.palette.surfaceElevated,
                  disabledForegroundColor: context.palette.textDisabled,
                ),
                icon: Icon(
                  Icons.swap_horiz,
                  size: 18,
                  color: _selectedAssets.isEmpty
                      ? context.palette.textDisabled
                      : context.palette.textPrimary,
                ),
                label: Text(
                  'Start Port',
                  style: VoidTypography.label.copyWith(
                    color: _selectedAssets.isEmpty
                        ? context.palette.textDisabled
                        : context.palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum PortMode { reference, clone, variant, lockedIdentity }

class _PortAsset {
  const _PortAsset({
    required this.name,
    required this.kind,
    required this.universe,
  });

  final String name;
  final String kind;
  final String universe;
}

class _AssetSelectPanel extends StatelessWidget {
  const _AssetSelectPanel({
    required this.sourceUniverse,
    required this.targetUniverse,
    required this.mode,
    required this.assets,
    required this.selectedAssets,
    required this.onSourceChanged,
    required this.onTargetChanged,
    required this.onModeChanged,
    required this.onAssetToggled,
  });

  final String sourceUniverse;
  final String targetUniverse;
  final PortMode mode;
  final List<_PortAsset> assets;
  final Set<String> selectedAssets;
  final ValueChanged<String> onSourceChanged;
  final ValueChanged<String> onTargetChanged;
  final ValueChanged<PortMode> onModeChanged;
  final ValueChanged<String> onAssetToggled;

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
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 18,
                color: context.palette.primary,
              ),
              const SizedBox(width: VoidSpacing.sm),
              Expanded(
                child: Text(
                  'Select Assets',
                  style: VoidTypography.headingLarge.copyWith(
                    color: context.palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: VoidSpacing.xs),
          Text(
            'Pilih asset yang akan dibawa ke universe target. '
            'Dependensi asset ikut ter-port secara otomatis.',
            style: VoidTypography.caption.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
          const SizedBox(height: VoidSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _UniverseDropdown(
                  label: 'Sumber',
                  value: sourceUniverse,
                  options: _PortabilityWizardScreenState._sourceUniverses,
                  onChanged: onSourceChanged,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: VoidSpacing.xs),
                child: Icon(Icons.arrow_forward, size: 16),
              ),
              Expanded(
                child: _UniverseDropdown(
                  label: 'Target',
                  value: targetUniverse,
                  options: _PortabilityWizardScreenState._targetUniverses,
                  onChanged: onTargetChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: VoidSpacing.lg),
          Wrap(
            spacing: VoidSpacing.sm,
            runSpacing: VoidSpacing.sm,
            children: [
              for (final m in PortMode.values)
                ChoiceChip(
                  label: Text(
                    _modeLabel(m),
                    style: VoidTypography.label.copyWith(
                      color: m == mode
                          ? context.palette.textPrimary
                          : context.palette.textSecondary,
                    ),
                  ),
                  selected: m == mode,
                  selectedColor: context.palette.primary.withValues(
                    alpha: 0.18,
                  ),
                  backgroundColor: context.palette.surfaceElevated,
                  side: BorderSide(
                    color: m == mode
                        ? context.palette.primary
                        : context.palette.border,
                  ),
                  onSelected: (_) => onModeChanged(m),
                ),
            ],
          ),
          const SizedBox(height: VoidSpacing.lg),
          for (final asset in assets)
            _AssetTile(
              asset: asset,
              selected: selectedAssets.contains(asset.name),
              onToggle: () => onAssetToggled(asset.name),
            ),
        ],
      ),
    );
  }

  static String _modeLabel(PortMode mode) {
    switch (mode) {
      case PortMode.reference:
        return 'Reference';
      case PortMode.clone:
        return 'Clone';
      case PortMode.variant:
        return 'Variant';
      case PortMode.lockedIdentity:
        return 'Locked Identity';
    }
  }
}

class _UniverseDropdown extends StatelessWidget {
  const _UniverseDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: VoidTypography.caption.copyWith(
            color: context.palette.textSecondary,
          ),
        ),
        const SizedBox(height: VoidSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: VoidSpacing.sm),
          decoration: BoxDecoration(
            color: context.palette.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.palette.border),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            isDense: true,
            underline: const SizedBox.shrink(),
            dropdownColor: context.palette.surfaceElevated,
            icon: Icon(Icons.arrow_drop_down, color: context.palette.primary),
            style: VoidTypography.label.copyWith(
              color: context.palette.textPrimary,
            ),
            items: [
              for (final option in options)
                DropdownMenuItem(
                  value: option,
                  child: Text(
                    option,
                    style: VoidTypography.label.copyWith(
                      color: context.palette.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (next) {
              if (next != null) onChanged(next);
            },
          ),
        ),
      ],
    );
  }
}

class _AssetTile extends StatelessWidget {
  const _AssetTile({
    required this.asset,
    required this.selected,
    required this.onToggle,
  });

  final _PortAsset asset;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: VoidSpacing.sm),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
              color: selected
                  ? context.palette.primary
                  : context.palette.textMuted,
            ),
            const SizedBox(width: VoidSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.name,
                    style: VoidTypography.body.copyWith(
                      color: context.palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${asset.kind} · ${asset.universe}',
                    style: VoidTypography.caption.copyWith(
                      color: context.palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortSummaryPanel extends StatelessWidget {
  const _PortSummaryPanel({
    required this.selectedCount,
    required this.sourceUniverse,
    required this.targetUniverse,
  });

  final int selectedCount;
  final String sourceUniverse;
  final String targetUniverse;

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
            'Ringkasan Port',
            style: VoidTypography.headingMedium.copyWith(
              color: context.palette.textPrimary,
            ),
          ),
          const SizedBox(height: VoidSpacing.md),
          _SummaryRow(
            icon: Icons.inventory_2_outlined,
            label: 'Asset Dipilih',
            value: '$selectedCount',
          ),
          const SizedBox(height: VoidSpacing.sm),
          _SummaryRow(
            icon: Icons.public,
            label: 'Sumber',
            value: sourceUniverse,
          ),
          const SizedBox(height: VoidSpacing.sm),
          _SummaryRow(
            icon: Icons.arrow_forward,
            label: 'Target',
            value: targetUniverse,
          ),
          const SizedBox(height: VoidSpacing.sm),
          const _SummaryRow(
            icon: Icons.link,
            label: 'Mode',
            value: 'Reference',
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
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
