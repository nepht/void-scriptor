import 'package:flutter/material.dart';

import '../domain/reference_models.dart';

class ReferenceComparisonScreen extends StatefulWidget {
  const ReferenceComparisonScreen({
    super.key,
    required this.referencePath,
    required this.generatedPath,
    this.title = 'Compare References',
  });

  final String referencePath;
  final String generatedPath;
  final String title;

  @override
  State<ReferenceComparisonScreen> createState() =>
      _ReferenceComparisonScreenState();
}

class _ReferenceComparisonScreenState extends State<ReferenceComparisonScreen> {
  ImageComparisonMode _mode = ImageComparisonMode.sideBySide;
  double _opacity = 0.5;
  ComparisonViewport _viewport = const ComparisonViewport();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 700;
          final images = _mode == ImageComparisonMode.sideBySide
              ? Row(
                  children: [
                    Expanded(
                      child: _ImagePane(
                        label: 'REFERENCE',
                        path: widget.referencePath,
                        viewport: _viewport,
                      ),
                    ),
                    Expanded(
                      child: _ImagePane(
                        label: 'GENERATED',
                        path: widget.generatedPath,
                        viewport: _viewport,
                      ),
                    ),
                  ],
                )
              : _ComparisonPane(
                  mode: _mode,
                  opacity: _opacity,
                  referencePath: widget.referencePath,
                  generatedPath: widget.generatedPath,
                  viewport: _viewport,
                );
          return Column(
            children: [
              Expanded(
                child: InteractiveViewer(
                  onInteractionUpdate: (details) => setState(
                    () => _viewport = ComparisonViewport(
                      scale: details.scale,
                      offsetX: details.focalPoint.dx,
                      offsetY: details.focalPoint.dy,
                    ),
                  ),
                  child: images,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SegmentedButton<ImageComparisonMode>(
                      segments: const [
                        ButtonSegment(
                          value: ImageComparisonMode.sideBySide,
                          label: Text('Side by Side'),
                        ),
                        ButtonSegment(
                          value: ImageComparisonMode.overlay,
                          label: Text('Overlay'),
                        ),
                        ButtonSegment(
                          value: ImageComparisonMode.swipe,
                          label: Text('Swipe'),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (value) =>
                          setState(() => _mode = value.first),
                    ),
                    if (_mode == ImageComparisonMode.overlay)
                      SizedBox(
                        width: narrow ? constraints.maxWidth - 24 : 260,
                        child: Slider(
                          value: _opacity,
                          onChanged: (value) =>
                              setState(() => _opacity = value),
                          label: '${(_opacity * 100).round()}% generated',
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ImagePane extends StatelessWidget {
  const _ImagePane({
    required this.label,
    required this.path,
    required this.viewport,
  });
  final String label;
  final String path;
  final ComparisonViewport viewport;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ColoredBox(
        color: Colors.black12,
        child: path.startsWith('http')
            ? Image.network(path, fit: BoxFit.contain)
            : Image.asset(
                path,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image_outlined, size: 64),
              ),
      ),
      Positioned(top: 12, left: 12, child: Chip(label: Text(label))),
    ],
  );
}

class _ComparisonPane extends StatelessWidget {
  const _ComparisonPane({
    required this.mode,
    required this.opacity,
    required this.referencePath,
    required this.generatedPath,
    required this.viewport,
  });
  final ImageComparisonMode mode;
  final double opacity;
  final String referencePath;
  final String generatedPath;
  final ComparisonViewport viewport;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      _ImagePane(label: 'REFERENCE', path: referencePath, viewport: viewport),
      if (mode == ImageComparisonMode.overlay)
        Opacity(
          opacity: opacity,
          child: _ImagePane(
            label: 'GENERATED',
            path: generatedPath,
            viewport: viewport,
          ),
        )
      else
        ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: 0.5,
            child: _ImagePane(
              label: 'GENERATED',
              path: generatedPath,
              viewport: viewport,
            ),
          ),
        ),
    ],
  );
}
