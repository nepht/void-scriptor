import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../core/selection/selection_controller.dart';
import '../../../core/selection/selection_model.dart';
import '../../../database/project/project_database.dart' as db;
import '../../../features/projects/presentation/project_persistence_providers.dart';
import '../../character_mode/presentation/character_mode_controller.dart';
import '../application/asset_pagination.dart';
import '../application/asset_repository.dart';
import '../application/asset_thumbnail_importer.dart';
import '../application/asset_view_preference_store.dart';
import '../domain/asset_search_query.dart';
import 'widgets/isolated_asset_reference_card.dart';
import '../domain/asset_type.dart';

class AssetBrowserScreen extends ConsumerStatefulWidget {
  const AssetBrowserScreen({
    super.key,
    this.assets = const [],
    this.repository,
    this.viewPreferenceStore,
    this.onCreateAsset,
    this.onImportThumbnail,
  });
  final List<SearchableAsset> assets;
  final AssetRepository? repository;
  final AssetViewPreferenceStore? viewPreferenceStore;

  /// Persists a stand-alone asset (wardrobe/weapon/armor/accessory/prop/
  /// creature/vehicle).
  /// Returns the new asset id, or null when the session is unavailable.
  final Future<String?> Function({
    required String name,
    required String description,
    required String type,
  })?
  onCreateAsset;

  /// 145.44: imports one local image as the asset's isolated visual
  /// reference (thumbnail). Returns the stored package path, or null when
  /// the user cancels / the session is unavailable. Production default
  /// opens a file dialog and copies through [AssetThumbnailImporter].
  final Future<String?> Function(String assetId)? onImportThumbnail;

  @override
  ConsumerState<AssetBrowserScreen> createState() => _AssetBrowserScreenState();
}

class _AssetBrowserScreenState extends ConsumerState<AssetBrowserScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _scrollController = ScrollController();
  AssetViewMode _viewMode = AssetViewMode.grid;
  AssetType? _type;
  bool _favoriteOnly = false;
  final Set<String> _selectedAssetIds = {};
  ProviderSubscription<AsyncValue<List<db.Asset>>>? _liveAssetsSub;
  List<SearchableAsset>? _liveAssets;
  late final AssetViewPreferenceStore _viewPreferenceStore;
  late final AssetPaginationController _pagination;

  @override
  void initState() {
    super.initState();
    _viewPreferenceStore =
        widget.viewPreferenceStore ??
        SharedPreferencesAssetViewPreferenceStore();
    _pagination = AssetPaginationController(source: widget.assets);
    _scrollController.addListener(_onScroll);
    _pagination.addListener(_onPaginationChanged);
    _restoreViewMode();
    _syncPagination();
    if (widget.assets.isEmpty) {
      _listenLiveAssets();
    }
  }

  void _listenLiveAssets() {
    _liveAssetsSub = ref.listenManual(projectAssetsProvider, (previous, next) {
      next.whenData((rows) {
        final mapped = <SearchableAsset>[];
        for (final row in rows) {
          final asset = _searchableFromDb(row);
          if (asset != null) mapped.add(asset);
        }
        if (!mounted) return;
        setState(() => _liveAssets = mapped);
        _syncPagination();
      });
    }, fireImmediately: true);
  }

  SearchableAsset? _searchableFromDb(db.Asset row) {
    AssetType? type;
    for (final candidate in AssetType.values) {
      if (candidate.name == row.type) {
        type = candidate;
        break;
      }
    }
    if (type == null) return null;
    return SearchableAsset(
      id: row.id,
      projectId: row.projectId,
      name: row.name,
      type: type,
      description: row.description,
      favorite: row.favorite,
      lastOpenedAt: row.lastOpenedAt,
      thumbnailPath: row.thumbnailPath,
    );
  }

  void _onPaginationChanged() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      _pagination.loadMore();
    }
  }

  Future<void> _restoreViewMode() async {
    final mode = await _viewPreferenceStore.load();
    if (!mounted || mode == null) return;
    setState(() => _viewMode = mode);
  }

  Future<void> _setViewMode(AssetViewMode mode) async {
    setState(() => _viewMode = mode);
    await _viewPreferenceStore.save(mode);
  }

  @override
  void dispose() {
    _liveAssetsSub?.close();
    _scrollController.dispose();
    _pagination.removeListener(_onPaginationChanged);
    _pagination.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<SearchableAsset> get _filteredAll {
    final parsed = const SearchQueryParser().parse(_searchController.text);
    final needle = parsed.text.trim().toLowerCase();
    return _sourceAssets
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

  List<SearchableAsset> get _sourceAssets {
    if (widget.assets.isNotEmpty) return widget.assets;
    return _liveAssets ?? const [];
  }

  List<SearchableAsset> get _filtered => _pagination.items;

  void _syncPagination() {
    _pagination.replaceSource(_filteredAll);
  }

  @override
  void didUpdateWidget(AssetBrowserScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.assets, widget.assets)) {
      _syncPagination();
    }
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
            title: Text(
              _selectedAssetIds.isEmpty
                  ? 'Assets'
                  : '${_selectedAssetIds.length} selected',
            ),
            actions: _selectedAssetIds.isNotEmpty
                ? [
                    TextButton.icon(
                      onPressed: widget.repository == null ? null : _addBulkTag,
                      icon: const Icon(Icons.label_outline),
                      label: const Text('Add tag'),
                    ),
                    IconButton(
                      tooltip: 'Clear selection',
                      icon: const Icon(Icons.close),
                      onPressed: () =>
                          setState(() => _selectedAssetIds.clear()),
                    ),
                  ]
                : [
                    IconButton(
                      tooltip: 'Grid view',
                      icon: const Icon(Icons.grid_view),
                      onPressed: () => _setViewMode(AssetViewMode.grid),
                    ),
                    IconButton(
                      tooltip: 'List view',
                      icon: const Icon(Icons.view_list),
                      onPressed: () => _setViewMode(AssetViewMode.list),
                    ),
                    IconButton(
                      tooltip: 'Compact view',
                      icon: const Icon(Icons.view_compact),
                      onPressed: () => _setViewMode(AssetViewMode.compact),
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
                        onSelected: (value) {
                          setState(() => _favoriteOnly = value);
                          _syncPagination();
                        },
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
                        onChanged: (value) {
                          setState(() => _type = value);
                          _syncPagination();
                        },
                      ),
                    ];
                    final search = TextField(
                      focusNode: _searchFocusNode,
                      controller: _searchController,
                      onChanged: (_) {
                        setState(() {});
                        _syncPagination();
                      },
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
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('asset-browser-create-fab'),
            onPressed: _openCreateDialog,
            tooltip: 'Create stand-alone asset',
            icon: const Icon(Icons.add),
            label: const Text('Create asset'),
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateDialog() async {
    final created = await showDialog<_NewAssetDraft>(
      context: context,
      builder: (dialogContext) => const _CreateAssetDialog(),
    );
    final draft = created;
    if (draft == null || !mounted) return;
    final create = widget.onCreateAsset ?? _defaultCreateAsset;
    final id = await create(
      name: draft.name,
      description: draft.description,
      type: draft.type,
    );
    if (id == null || !mounted) return;
    ref.invalidate(projectAssetsProvider);
  }

  /// Production default: persists through the active project session.
  Future<String?> _defaultCreateAsset({
    required String name,
    required String description,
    required String type,
  }) async {
    final session = ref.read(projectSessionProvider).valueOrNull;
    if (session == null) return null;
    final id = const Uuid().v4();
    await session.database.assetDao.createStandaloneAsset(
      id: id,
      projectId: session.manifest.id,
      name: name,
      description: description,
      type: type,
      now: DateTime.now().toUtc(),
    );
    return id;
  }

  Widget _buildResults(BuildContext context) {
    if (_viewMode == AssetViewMode.list || _viewMode == AssetViewMode.compact) {
      return ListView.builder(
        controller: _scrollController,
        itemCount: _filtered.length,
        itemBuilder: (_, index) => AssetListTile(
          asset: _filtered[index],
          compact: _viewMode == AssetViewMode.compact,
          selected: _selectedAssetIds.contains(_filtered[index].id),
          onPressed: () => _handleAssetTap(_filtered[index]),
          onLongPress: () => _toggleSelection(_filtered[index].id),
        ),
      );
    }
    return GridView.builder(
      controller: _scrollController,
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
        selected:
            _selectedAssetIds.contains(_filtered[index].id) ||
            ref.watch(selectionProvider)?.assetId == _filtered[index].id,
        onPressed: () => _handleAssetTap(_filtered[index]),
        onLongPress: () => _toggleSelection(_filtered[index].id),
      ),
    );
  }

  void _handleAssetTap(SearchableAsset asset) {
    if (_selectedAssetIds.isNotEmpty) {
      _toggleSelection(asset.id);
      return;
    }
    _showAssetDetail(asset);
    _select(asset);
  }

  /// Isolated visual reference detail (ADR
  /// docs/architecture/character-owned-assets-and-isolated-visual-references.md):
  /// the primary reference renders on a transparency checkerboard with the
  /// description below, isolated from any character context.
  Future<void> _showAssetDetail(SearchableAsset asset) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('asset-detail-dialog'),
        title: const Text('Asset detail'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: IsolatedAssetReferenceCard(
              name: asset.name,
              assetType: asset.type.name,
              description: asset.description,
              imagePath: asset.thumbnailPath,
              onAddReference: () async {
                final stored =
                    await (widget.onImportThumbnail ?? _defaultImportThumbnail)(
                      asset.id,
                    );
                if (!dialogContext.mounted) return;
                if (stored != null) {
                  Navigator.of(dialogContext).pop();
                  if (mounted) {
                    setState(() {
                      _liveAssets = _liveAssets
                          ?.map(
                            (entry) => entry.id == asset.id
                                ? entry.copyWith(thumbnailPath: stored)
                                : entry,
                          )
                          .toList();
                    });
                  }
                }
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            key: const Key('asset-detail-close'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Production default: file dialog (image types) then a copy into the
  /// active package's asset namespace via [AssetThumbnailImporter].
  Future<String?> _defaultImportThumbnail(String assetId) async {
    final session = ref.read(projectSessionProvider).valueOrNull;
    if (session == null) return null;
    const typeGroup = XTypeGroup(
      label: 'Images',
      extensions: ['png', 'jpg', 'jpeg', 'webp', 'gif'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return null;
    final importer = AssetThumbnailImporter(
      database: session.database,
      assetsDirectory: session.package.assetsDirectory,
    );
    try {
      return await importer.importFromFile(
        assetId: assetId,
        sourcePath: file.path,
      );
    } on StateError {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  void _toggleSelection(String assetId) {
    setState(() {
      if (!_selectedAssetIds.add(assetId)) {
        _selectedAssetIds.remove(assetId);
      }
    });
  }

  Future<void> _addBulkTag() async {
    var value = '';
    final tag = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tag ${_selectedAssetIds.length} assets'),
        content: TextField(
          key: const Key('bulk-tag-field'),
          autofocus: true,
          onChanged: (text) => value = text,
          decoration: const InputDecoration(labelText: 'Tag'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, value),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (tag == null || tag.trim().isEmpty || !mounted) return;
    await widget.repository!.addTagToAssets(_selectedAssetIds, tag);
    if (!mounted) return;
    setState(() => _selectedAssetIds.clear());
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

class _NewAssetDraft {
  const _NewAssetDraft({
    required this.name,
    required this.description,
    required this.type,
  });
  final String name;
  final String description;
  final String type;
}

class _CreateAssetDialog extends StatefulWidget {
  const _CreateAssetDialog();

  @override
  State<_CreateAssetDialog> createState() => _CreateAssetDialogState();
}

class _CreateAssetDialogState extends State<_CreateAssetDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _type = 'armor';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = _nameController.text.trim();
    return AlertDialog(
      title: const Text('Create stand-alone asset'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('create-asset-name-field'),
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('create-asset-description-field'),
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'armor', child: Text('armor')),
                DropdownMenuItem(value: 'accessory', child: Text('accessory')),
                DropdownMenuItem(value: 'wardrobe', child: Text('wardrobe')),
                DropdownMenuItem(value: 'weapon', child: Text('weapon')),
                DropdownMenuItem(value: 'prop', child: Text('story item')),
                DropdownMenuItem(value: 'creature', child: Text('creature')),
                DropdownMenuItem(value: 'vehicle', child: Text('vehicle')),
              ],
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('create-asset-submit-button'),
          onPressed: name.isEmpty
              ? null
              : () => Navigator.of(context).pop(
                  _NewAssetDraft(
                    name: name,
                    description: _descriptionController.text.trim(),
                    type: _type,
                  ),
                ),
          child: const Text('Create'),
        ),
      ],
    );
  }
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
    required this.onLongPress,
  });
  final SearchableAsset asset;
  final bool selected;
  final VoidCallback onPressed;
  final VoidCallback onLongPress;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onPressed,
    onLongPress: onLongPress,
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
    required this.onLongPress,
    required this.compact,
    required this.selected,
  });
  final SearchableAsset asset;
  final VoidCallback onPressed;
  final VoidCallback onLongPress;
  final bool compact;
  final bool selected;
  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onPressed,
    onLongPress: onLongPress,
    selected: selected,
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
    AssetType.armor => Icons.shield_moon,
    AssetType.accessory => Icons.diamond,
    AssetType.environment => Icons.landscape,
    AssetType.story => Icons.menu_book,
    AssetType.scene => Icons.movie,
    AssetType.aiGeneration => Icons.auto_awesome,
    _ => Icons.category,
  };
}
