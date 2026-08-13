import 'dart:io';

import 'package:flutter/material.dart';

class GenerationGalleryItem {
  const GenerationGalleryItem({
    required this.id,
    required this.path,
    required this.outputType,
  });
  final String id;
  final String path;
  final String outputType;
}

class AiGenerationGalleryScreen extends StatelessWidget {
  const AiGenerationGalleryScreen({
    super.key,
    this.outputs = const [],
    this.onUseAsReference,
    this.onCompareWithPrimary,
  });

  final List<GenerationGalleryItem> outputs;
  final Future<void> Function(GenerationGalleryItem output)? onUseAsReference;
  final Future<void> Function(GenerationGalleryItem output)?
  onCompareWithPrimary;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AI GENERATION GALLERY')),
    body: outputs.isEmpty
        ? const Center(child: Text('No generation outputs yet.'))
        : LayoutBuilder(
            builder: (context, constraints) => GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: constraints.maxWidth < 500 ? 360 : 300,
                mainAxisExtent: 330,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: outputs.length,
              itemBuilder: (_, index) {
                final output = outputs[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: File(output.path).existsSync()
                            ? Image.file(File(output.path), fit: BoxFit.cover)
                            : const ColoredBox(
                                color: Color(0x221F2937),
                                child: Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 48,
                                  ),
                                ),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              output.id,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(output.outputType),
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton(
                                  onPressed: onUseAsReference == null
                                      ? null
                                      : () => onUseAsReference!(output),
                                  child: const Text('Use as Reference'),
                                ),
                                TextButton(
                                  onPressed: onCompareWithPrimary == null
                                      ? null
                                      : () => onCompareWithPrimary!(output),
                                  child: const Text('Compare with Primary'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
  );
}
