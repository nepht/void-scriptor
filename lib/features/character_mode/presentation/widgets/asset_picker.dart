import 'package:flutter/material.dart';

import '../../../../database/project/project_database.dart' as db;

class AssetPicker extends StatefulWidget {
  const AssetPicker({
    super.key,
    required this.assets,
    required this.assetType,
    required this.onSelected,
    this.initialAssetId,
  });

  final List<db.Asset> assets;
  final String assetType;
  final String? initialAssetId;
  final ValueChanged<db.Asset> onSelected;

  @override
  State<AssetPicker> createState() => _AssetPickerState();
}

class _AssetPickerState extends State<AssetPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.assets.where((asset) {
      final matchesType = asset.type == widget.assetType;
      final matchesQuery =
          _query.trim().isEmpty ||
          asset.name.toLowerCase().contains(_query.trim().toLowerCase());
      return matchesType && matchesQuery;
    }).toList();
    return SizedBox(
      width: 420,
      height: 420,
      child: Column(
        children: [
          TextField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Search assets',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No matching assets'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final asset = filtered[index];
                      return ListTile(
                        selected: asset.id == widget.initialAssetId,
                        title: Text(asset.name),
                        subtitle: Text(asset.type),
                        onTap: () => widget.onSelected(asset),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
