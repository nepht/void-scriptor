import 'package:flutter/material.dart';
import '../../../shared/widgets/scale_comparison_widget.dart';

enum ProductionAssetKind { creature, vehicle, prop }

class ProductionAssetWorkspaceScreen extends StatelessWidget {
  const ProductionAssetWorkspaceScreen({
    super.key,
    required this.kind,
    this.assetId,
  });
  final ProductionAssetKind kind;
  final String? assetId;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 720;
      final title = switch (kind) {
        ProductionAssetKind.creature => 'CREATURES',
        ProductionAssetKind.vehicle => 'VEHICLES',
        ProductionAssetKind.prop => 'PROPS',
      };
      final name =
          assetId ??
          switch (kind) {
            ProductionAssetKind.creature => 'Byte',
            ProductionAssetKind.vehicle => 'Neo Interceptor',
            ProductionAssetKind.prop => 'Coffee Cup',
          };
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
      final preview = _Preview(name: name, kind: kind);
      final inspector = _Inspector(sections: sections);
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
  const _Preview({required this.name, required this.kind});
  final String name;
  final ProductionAssetKind kind;
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
                Text(kind.name.toUpperCase()),
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
  const _Inspector({required this.sections});
  final List<String> sections;
  @override
  Widget build(BuildContext context) => Card(
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
            ListTile(
              dense: true,
              title: Text(section),
              trailing: const Icon(Icons.chevron_right),
            ),
        ],
      ),
    ),
  );
}
