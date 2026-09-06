import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../design_system/radius/void_radius.dart';
import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/theme/void_theme_context.dart';
import '../../../design_system/widgets/void_card.dart';
import '../domain/content_capability.dart';
import '../domain/content_capability_catalog.dart';

class ContentCapabilityMatrixScreen extends StatefulWidget {
  const ContentCapabilityMatrixScreen({super.key});

  @override
  State<ContentCapabilityMatrixScreen> createState() =>
      _ContentCapabilityMatrixScreenState();
}

class _ContentCapabilityMatrixScreenState
    extends State<ContentCapabilityMatrixScreen> {
  final _searchController = TextEditingController();
  ContentModuleMaturity? _selectedMaturity;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ContentModuleCapability> get _visibleModules {
    final searched = ContentCapabilityCatalog.search(_searchController.text);
    return searched
        .where(
          (module) =>
              _selectedMaturity == null || module.maturity == _selectedMaturity,
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final modules = _visibleModules;
    return Scaffold(
      appBar: AppBar(title: const Text('Content Capability Matrix')),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            if (modules.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyResult(onReset: _resetFilters),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  VoidSpacing.md,
                  0,
                  VoidSpacing.md,
                  VoidSpacing.xxl,
                ),
                sliver: SliverList.separated(
                  itemCount: modules.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: VoidSpacing.sm),
                  itemBuilder: (_, index) => Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: _CapabilityModuleRow(module: modules[index]),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final counts = ContentCapabilityCatalog.byMaturity;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            VoidSpacing.md,
            VoidSpacing.xl,
            VoidSpacing.md,
            VoidSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Peta kesiapan modul konten',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: context.palette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: VoidSpacing.xs),
              Text(
                'Status menilai integrasi produk yang dapat dipakai, bukan hanya '
                'keberadaan file atau tampilan. Baseline ini harus diperbarui '
                'setelah bukti implementasi dan pengujian berubah.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.palette.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: VoidSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  final search = TextField(
                    key: const ValueKey('content-capability-search'),
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Cari modul atau kapabilitas',
                      hintText: 'Contoh: dialogue atau import export',
                      prefixIcon: Icon(LucideIcons.search),
                    ),
                  );
                  final filters = _MaturityFilters(
                    selected: _selectedMaturity,
                    counts: counts,
                    onSelected: (value) =>
                        setState(() => _selectedMaturity = value),
                  );
                  if (constraints.maxWidth < 760) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        search,
                        const SizedBox(height: VoidSpacing.md),
                        filters,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: search),
                      const SizedBox(width: VoidSpacing.lg),
                      Expanded(flex: 6, child: filters),
                    ],
                  );
                },
              ),
              const SizedBox(height: VoidSpacing.md),
              Text(
                '${_visibleModules.length} dari '
                '${ContentCapabilityCatalog.modules.length} modul ditampilkan',
                key: const ValueKey('content-capability-result-count'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.palette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() => _selectedMaturity = null);
  }
}

class _MaturityFilters extends StatelessWidget {
  const _MaturityFilters({
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final ContentModuleMaturity? selected;
  final Map<ContentModuleMaturity, List<ContentModuleCapability>> counts;
  final ValueChanged<ContentModuleMaturity?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: VoidSpacing.xs,
      runSpacing: VoidSpacing.xs,
      children: [
        FilterChip(
          key: const ValueKey('maturity-all'),
          label: const Text('Semua'),
          selected: selected == null,
          onSelected: (_) => onSelected(null),
        ),
        for (final maturity in ContentModuleMaturity.values)
          FilterChip(
            key: ValueKey('maturity-${maturity.name}'),
            label: Text('${maturity.label} ${counts[maturity]!.length}'),
            selected: selected == maturity,
            onSelected: (_) => onSelected(maturity),
          ),
      ],
    );
  }
}

class _CapabilityModuleRow extends StatelessWidget {
  const _CapabilityModuleRow({required this.module});

  final ContentModuleCapability module;

  @override
  Widget build(BuildContext context) {
    return VoidCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        key: ValueKey('content-module-${module.id}'),
        leading: Icon(
          _iconFor(module.id),
          color: context.palette.textSecondary,
        ),
        title: Text(
          module.label,
          style: TextStyle(
            color: context.palette.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: VoidSpacing.xs),
          child: Text(
            module.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.palette.textSecondary),
          ),
        ),
        trailing: _MaturityBadge(maturity: module.maturity),
        childrenPadding: const EdgeInsets.fromLTRB(
          VoidSpacing.md,
          0,
          VoidSpacing.md,
          VoidSpacing.md,
        ),
        children: [
          Divider(color: context.palette.divider),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${module.availableCount} tersedia, '
              '${module.partialCount} sebagian, dari '
              '${ContentWorkflowCapability.values.length} alur',
              style: TextStyle(color: context.palette.textSecondary),
            ),
          ),
          const SizedBox(height: VoidSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 760
                  ? 3
                  : constraints.maxWidth >= 480
                  ? 2
                  : 1;
              final width =
                  (constraints.maxWidth - VoidSpacing.sm * (columns - 1)) /
                  columns;
              return Wrap(
                spacing: VoidSpacing.sm,
                runSpacing: VoidSpacing.sm,
                children: [
                  for (final entry in module.workflowStates.entries)
                    SizedBox(
                      width: width,
                      child: _CapabilityCell(
                        capability: entry.key,
                        state: entry.value,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: VoidSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(VoidSpacing.md),
            decoration: BoxDecoration(
              color: context.palette.panelSecondary,
              borderRadius: BorderRadius.circular(VoidRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Langkah berikutnya',
                  style: TextStyle(
                    color: context.palette.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: VoidSpacing.xs),
                Text(
                  module.nextAction,
                  style: TextStyle(color: context.palette.textSecondary),
                ),
                const SizedBox(height: VoidSpacing.sm),
                Text(
                  'Bukti: ${module.evidence.join(' • ')}',
                  style: TextStyle(
                    color: context.palette.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MaturityBadge extends StatelessWidget {
  const _MaturityBadge({required this.maturity});

  final ContentModuleMaturity maturity;

  @override
  Widget build(BuildContext context) {
    final color = switch (maturity) {
      ContentModuleMaturity.full => context.palette.success,
      ContentModuleMaturity.partial => context.palette.info,
      ContentModuleMaturity.domainOnly => context.palette.warning,
      ContentModuleMaturity.uiOnly => context.palette.secondary,
      ContentModuleMaturity.planned => context.palette.textMuted,
    };
    return Semantics(
      label: 'Status ${maturity.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VoidSpacing.sm,
          vertical: VoidSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.55)),
          borderRadius: BorderRadius.circular(VoidRadius.sm),
        ),
        child: Text(
          maturity.label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CapabilityCell extends StatelessWidget {
  const _CapabilityCell({required this.capability, required this.state});

  final ContentWorkflowCapability capability;
  final ContentCapabilityState state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      ContentCapabilityState.available => context.palette.success,
      ContentCapabilityState.partial => context.palette.warning,
      ContentCapabilityState.missing => context.palette.textMuted,
    };
    final icon = switch (state) {
      ContentCapabilityState.available => LucideIcons.circleCheck,
      ContentCapabilityState.partial => LucideIcons.circleDot,
      ContentCapabilityState.missing => LucideIcons.circleMinus,
    };
    return Container(
      padding: const EdgeInsets.all(VoidSpacing.sm),
      decoration: BoxDecoration(
        color: context.palette.panel,
        border: Border.all(color: context.palette.borderSoft),
        borderRadius: BorderRadius.circular(VoidRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: VoidSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capability.label,
                  style: TextStyle(
                    color: context.palette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(state.label, style: TextStyle(color: color, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VoidSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.listFilter, color: context.palette.textMuted),
            const SizedBox(height: VoidSpacing.sm),
            Text(
              'Tidak ada modul yang cocok dengan filter ini.',
              style: TextStyle(color: context.palette.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VoidSpacing.sm),
            TextButton(onPressed: onReset, child: const Text('Reset filter')),
          ],
        ),
      ),
    );
  }
}

IconData _iconFor(String id) => switch (id) {
  'story' => LucideIcons.bookOpenText,
  'character' => LucideIcons.userRound,
  'world' => LucideIcons.map,
  'bible' => LucideIcons.library,
  'timeline' => LucideIcons.clock3,
  'assets' => LucideIcons.folderOpen,
  'cinema' => LucideIcons.clapperboard,
  'audio' => LucideIcons.audioLines,
  'ai-output' => LucideIcons.cpu,
  'dialogue' => LucideIcons.messagesSquare,
  'plot-subplot' => LucideIcons.workflow,
  'pacing-pov' => LucideIcons.gauge,
  'herbology-alchemy' => LucideIcons.flaskConical,
  'economy-travel' => LucideIcons.route,
  'culture-language' => LucideIcons.languages,
  'production-cards' => LucideIcons.box,
  'reader-annotations' => LucideIcons.messageSquareText,
  _ => LucideIcons.fileText,
};
