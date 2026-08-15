import 'package:flutter/material.dart';
import '../../../shared/widgets/scale_comparison_widget.dart';
import '../application/production_asset_detail.dart';

enum ProductionAssetKind { creature, vehicle, prop }

class ProductionAssetWorkspaceScreen extends StatelessWidget {
  const ProductionAssetWorkspaceScreen({
    super.key,
    required this.kind,
    this.assetId,
    this.detail,
  });
  final ProductionAssetKind kind;
  final String? assetId;

  /// Resolved entity data. When supplied it is the source of truth for the
  /// preview title/subtitle and the inspector rows; the static placeholders
  /// are only a demo fallback when no data has been resolved yet.
  final ProductionAssetDetail? detail;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 720;
      final title = switch (kind) {
        ProductionAssetKind.creature => 'CREATURES',
        ProductionAssetKind.vehicle => 'VEHICLES',
        ProductionAssetKind.prop => 'PROPS',
      };
      final name = detail?.title ?? assetId ?? _placeholderName(kind);
      final sections = switch (kind) {
        ProductionAssetKind.creature => const [
          'Identity',
          'Species',
          'Physical',
          'Abilities',
          'Modes',
          'References',
          'Canon',
        ],
        ProductionAssetKind.vehicle => const [
          'Overview',
          'Specifications',
          'Components',
          'Weapons',
          'Interior',
          'Variants',
          'References',
          'Scenes',
          'Canon',
        ],
        ProductionAssetKind.prop => const [
          'Overview',
          'Category',
          'States',
          'Materials',
          'References',
          'Used In',
          'Continuity',
        ],
      };
      final navigator = _AssetNavigator(title: title, name: name);
      final preview = _Preview(name: name, kind: kind, detail: detail);
      final inspector = _Inspector(sections: sections, detail: detail);
      return ColoredBox(
        color: const Color(0xFF0B0B14),
        child: SafeArea(
          child: compact
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      navigator,
                      const SizedBox(height: 12),
                      preview,
                      const SizedBox(height: 12),
                      inspector,
                    ],
                  ),
                )
              : Row(
                  children: [
                    SizedBox(width: 220, child: navigator),
                    Expanded(child: preview),
                    SizedBox(width: 260, child: inspector),
                  ],
                ),
        ),
      );
    },
  );
}

String _placeholderName(ProductionAssetKind kind) => switch (kind) {
  ProductionAssetKind.creature => 'Byte',
  ProductionAssetKind.vehicle => 'Neo Interceptor',
  ProductionAssetKind.prop => 'Coffee Cup',
};

class _AssetNavigator extends StatelessWidget {
  const _AssetNavigator({required this.title, required this.name});
  final String title, name;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            selected: true,
            leading: const Icon(Icons.category_outlined),
            title: Text(name),
          ),
        ],
      ),
    ),
  );
}

class _Preview extends StatelessWidget {
  const _Preview({required this.name, required this.kind, this.detail});
  final String name;
  final ProductionAssetKind kind;
  final ProductionAssetDetail? detail;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Container(
          height: 280,
          decoration: BoxDecoration(
            color: const Color(0xFF171728),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.view_in_ar, size: 72),
                const SizedBox(height: 12),
                Text(name, style: Theme.of(context).textTheme.headlineSmall),
                Text(detail?.subtitle ?? kind.name.toUpperCase()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const ScaleComparisonWidget(),
      ],
    ),
  );
}

class _Inspector extends StatelessWidget {
  const _Inspector({required this.sections, this.detail});
  final List<String> sections;
  final ProductionAssetDetail? detail;
  @override
  Widget build(BuildContext context) {
    final resolved = detail?.sections ?? const <String, DetailSection>{};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'INSPECTOR',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const Divider(),
            for (final section in sections)
              _InspectorSection(name: section, resolved: resolved[section]),
          ],
        ),
      ),
    );
  }
}

class _InspectorSection extends StatelessWidget {
  const _InspectorSection({required this.name, this.resolved});
  final String name;
  final DetailSection? resolved;
  @override
  Widget build(BuildContext context) {
    final section = resolved;
    if (section != null && section.rows.isNotEmpty) {
      return ExpansionTile(
        dense: true,
        title: Text(name),
        children: [
          for (final row in section.rows)
            ListTile(
              dense: true,
              title: Text(row.label),
              trailing: Text(
                row.value,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      );
    }
    return ListTile(
      dense: true,
      title: Text(name),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
