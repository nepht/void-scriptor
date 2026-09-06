import 'dart:io';

import 'package:flutter/material.dart';

class IsolatedAssetReferenceCard extends StatelessWidget {
  const IsolatedAssetReferenceCard({
    super.key,
    required this.name,
    required this.assetType,
    this.description = '',
    this.imagePath,
    this.onAddReference,
  });

  final String name;
  final String assetType;
  final String description;
  final String? imagePath;
  final VoidCallback? onAddReference;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    final hasImage = path != null && path.isNotEmpty && File(path).existsSync();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            key: const Key('isolated-reference-image-area'),
            height: 240,
            color: const Color(0xFF24242A),
            child: CustomPaint(
              painter: const _TransparencyCheckerboardPainter(),
              child: hasImage
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Image.file(File(path), fit: BoxFit.contain),
                    )
                  : Center(
                      child: OutlinedButton.icon(
                        onPressed: onAddReference,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Add isolated reference'),
                      ),
                    ),
            ),
          ),
          Padding(
            key: const Key('isolated-reference-description'),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(assetType, style: Theme.of(context).textTheme.labelMedium),
                if (description.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(description),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransparencyCheckerboardPainter extends CustomPainter {
  const _TransparencyCheckerboardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 16.0;
    final light = Paint()..color = const Color(0x18FFFFFF);
    for (var y = 0.0; y < size.height; y += cell) {
      for (var x = 0.0; x < size.width; x += cell) {
        if (((x / cell).floor() + (y / cell).floor()).isEven) {
          canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), light);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
