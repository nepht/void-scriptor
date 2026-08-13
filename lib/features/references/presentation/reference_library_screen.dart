import 'dart:io';

import 'package:flutter/material.dart';

import '../domain/reference_models.dart';

class ReferenceLibraryScreen extends StatefulWidget {
  const ReferenceLibraryScreen({super.key, this.references = const []});

  final List<ReferenceModel> references;

  @override
  State<ReferenceLibraryScreen> createState() => _ReferenceLibraryScreenState();
}

class _ReferenceLibraryScreenState extends State<ReferenceLibraryScreen> {
  final _search = TextEditingController();
  ReferenceType? _type;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<ReferenceModel> get _filtered {
    final query = _search.text.trim().toLowerCase();
    return widget.references
        .where((reference) {
          if (_type != null && reference.type != _type) return false;
          if (query.isEmpty) return true;
          return reference.name.toLowerCase().contains(query) ||
              reference.description.toLowerCase().contains(query) ||
              reference.type.name.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final references = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reference Library'),
        actions: [
          IconButton(
            tooltip: 'Import reference',
            onPressed: () {},
            icon: const Icon(Icons.add_photo_alternate_outlined),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 700;
          final content = Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: narrow ? constraints.maxWidth - 32 : 420,
                      child: TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Search References...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    DropdownButton<ReferenceType?>(
                      value: _type,
                      hint: const Text('All types'),
                      items: [
                        const DropdownMenuItem<ReferenceType?>(
                          value: null,
                          child: Text('All types'),
                        ),
                        ...ReferenceType.values.map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.name),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() => _type = value),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: references.isEmpty
                    ? const Center(child: Text('No references found'))
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: narrow ? 190 : 240,
                          mainAxisExtent: 250,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: references.length,
                        itemBuilder: (_, index) =>
                            ReferenceCard(reference: references[index]),
                      ),
              ),
            ],
          );
          if (narrow) return content;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                width: 190,
                child: Card(
                  margin: EdgeInsets.fromLTRB(16, 16, 0, 16),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'FILTER\n\nCharacter\nFace\nHair\nBody\nWardrobe\nWeapon\nEnvironment\nPose\nStyle',
                    ),
                  ),
                ),
              ),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }
}

class ReferenceCard extends StatelessWidget {
  const ReferenceCard({super.key, required this.reference});

  final ReferenceModel reference;

  @override
  Widget build(BuildContext context) {
    final exists = File(reference.filePath).existsSync();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: reference.filePath.startsWith('http')
                ? Image.network(reference.filePath, fit: BoxFit.cover)
                : exists
                ? Image.file(File(reference.filePath), fit: BoxFit.cover)
                : const ColoredBox(
                    color: Color(0x221F2937),
                    child: Center(
                      child: Icon(Icons.broken_image_outlined, size: 42),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (reference.primary)
                  const Text(
                    '★ PRIMARY',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                Text(
                  reference.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text('${reference.type.name} • Priority ${reference.priority}'),
                if (!exists && !reference.filePath.startsWith('http'))
                  const Text(
                    'Reference file missing',
                    style: TextStyle(color: Colors.orange),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
