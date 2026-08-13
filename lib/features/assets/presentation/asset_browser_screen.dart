import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/selection/selection_controller.dart';
import '../../../core/selection/selection_model.dart';
import '../domain/asset_search_query.dart';
import '../domain/asset_type.dart';

class AssetBrowserScreen extends ConsumerStatefulWidget {
  const AssetBrowserScreen({super.key, this.assets = const []});
  final List<SearchableAsset> assets;

  @override
  ConsumerState<AssetBrowserScreen> createState() => _AssetBrowserScreenState();
}

class _AssetBrowserScreenState extends ConsumerState<AssetBrowserScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  AssetViewMode _viewMode = AssetViewMode.grid;
  AssetType? _type;
  bool _favoriteOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<SearchableAsset> get _filtered {
    final parsed = const SearchQueryParser().parse(_searchController.text);
    final needle = parsed.text.trim().toLowerCase();
    return widget.assets
        .where((asset) {
          if (_type != null && asset.type != _type) return false;
          if (parsed.types.isNotEmpty && !parsed.types.contains(asset.type)) {
            return false;
          }
          if ((_favoriteOnly || parsed.favoriteOnly) && !asset.favorite) {
            return false;
          }
          if (parsed.tags.isNotEmpty &&
              !parsed.tags.every(asset.tags.contains)) {
            return false;
          }
          if (needle.isEmpty) return true;
          return asset.name.toLowerCase().contains(needle) ||
              asset.description.toLowerCase().contains(needle) ||
              asset.tags.any((tag) => tag.contains(needle));
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _FocusSearchIntent(),
        SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            _FocusSearchIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _FocusSearchIntent: CallbackAction<_FocusSearchIntent>(
            onInvoke: (_) {
              _searchFocusNode.requestFocus();
              return null;
            },
          ),
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Assets'),
            actions: [
              IconButton(
                icon: const Icon(Icons.grid_view),
                onPressed: () => setState(() => _viewMode = AssetViewMode.grid),
              ),
              IconButton(
                icon: const Icon(Icons.view_list),
                onPressed: () => setState(() => _viewMode = AssetViewMode.list),
              ),
              IconButton(
                icon: const Icon(Icons.view_compact),
                onPressed: () =>
                    setState(() => _viewMode = AssetViewMode.compact),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 620;
                    final controls = [
                      FilterChip(
                        label: const Text('Favorites'),
                        selected: _favoriteOnly,
                        onSelected: (value) =>
                            setState(() => _favoriteOnly = value),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<AssetType?>(
                        value: _type,
                        hint: const Text('All types'),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All types'),
                          ),
                          ...AssetType.values.map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.name),
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() => _type = value),
                      ),
                    ];
                    final search = TextField(
                      focusNode: _searchFocusNode,
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search everything...',
                        border: OutlineInputBorder(),
                      ),
                    );
                    return narrow
                        ? Column(
                            children: [
                              search,
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: controls,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: search),
                              const SizedBox(width: 8),
                              ...controls,
                            ],
                          );
                  },
                ),
              ),
              Expanded(
                child: _filtered.isEmpty
                    ? const Center(child: Text('No assets found'))
                    : _buildResults(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    if (_viewMode == AssetViewMode.list || _viewMode == AssetViewMode.compact) {
      return ListView.builder(
        itemCount: _filtered.length,
        itemBuilder: (_, index) => AssetListTile(
          asset: _filtered[index],
          compact: _viewMode == AssetViewMode.compact,
          onPressed: () => _select(_filtered[index]),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 230,
        mainAxisExtent: 210,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filtered.length,
      itemBuilder: (_, index) => AssetCard(
        asset: _filtered[index],
        selected: ref.watch(selectionProvider)?.assetId == _filtered[index].id,
        onPressed: () => _select(_filtered[index]),
      ),
    );
  }

  void _select(SearchableAsset asset) => ref
      .read(selectionProvider.notifier)
      .select(
        SelectionModel(
          assetId: asset.id,
          assetType: asset.type,
          projectId: asset.projectId,
        ),
      );
}

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

class AssetCard extends StatelessWidget {
  const AssetCard({
    super.key,
    required this.asset,
    required this.selected,
    required this.onPressed,
  });
  final SearchableAsset asset;
  final bool selected;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(8),
    child: Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Expanded(child: AssetThumbnail(asset: asset)),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    asset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (asset.favorite) const Icon(Icons.star, size: 16),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class AssetListTile extends StatelessWidget {
  const AssetListTile({
    super.key,
    required this.asset,
    required this.onPressed,
    required this.compact,
  });
  final SearchableAsset asset;
  final VoidCallback onPressed;
  final bool compact;
  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onPressed,
    dense: compact,
    leading: AssetThumbnail(asset: asset, size: compact ? 32 : 48),
    title: Text(asset.name),
    subtitle: compact
        ? null
        : Text('${asset.type.name} · ${asset.tags.join(', ')}'),
    trailing: asset.favorite ? const Icon(Icons.star) : null,
  );
}

class AssetThumbnail extends StatelessWidget {
  const AssetThumbnail({
    super.key,
    required this.asset,
    this.size = double.infinity,
  });
  final SearchableAsset asset;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size == double.infinity ? null : size,
    child: asset.thumbnailPath?.startsWith('http') == true
        ? Image.network(asset.thumbnailPath!, fit: BoxFit.cover)
        : asset.tags.isNotEmpty
        ? Center(
            child: Icon(
              _iconFor(asset.type),
              size: size == double.infinity ? 48 : size * .55,
            ),
          )
        : Center(
            child: Icon(
              _iconFor(asset.type),
              size: size == double.infinity ? 48 : size * .55,
            ),
          ),
  );
  IconData _iconFor(AssetType type) => switch (type) {
    AssetType.character => Icons.person,
    AssetType.wardrobe => Icons.checkroom,
    AssetType.weapon => Icons.shield,
    AssetType.environment => Icons.landscape,
    AssetType.story => Icons.menu_book,
    AssetType.scene => Icons.movie,
    AssetType.aiGeneration => Icons.auto_awesome,
    _ => Icons.category,
  };
}
