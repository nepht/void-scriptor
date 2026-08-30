// Sprint 110.21 - Map Time Slider & Historical Layers (widget).
//
// Read-only presentation of MapTimeSliderController. Composes the
// acceptance surfaces required by sprint_110.json step 110.21:
//   * time_slider: a Slider bound to controller.currentTick.
//   * historical_layers: togglable chips for each enabled key tick.
//   * change_highlight: badge list for the active layer.
//   * legend: full MapLegend.standard() rendering.
//   * keyboard_control: IconButton actions wired to MapTimeKey values.
//
// Listens to controller notifications via ListenableBuilder so dragging
// the Slider or tapping a key button rebuilds the dependent widgets.

import "package:flutter/material.dart";

import "../domain/historical_layer_resolver.dart";

class MapTimeSliderView extends StatefulWidget {
  const MapTimeSliderView({super.key, required this.controller, this.legend});

  final MapTimeSliderController controller;
  final MapLegend? legend;

  @override
  State<MapTimeSliderView> createState() => _MapTimeSliderViewState();
}

class _MapTimeSliderViewState extends State<MapTimeSliderView> {
  late MapLegend _legend;

  @override
  void initState() {
    super.initState();
    _legend = widget.legend ?? MapLegend.standard();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TimeSliderSection(controller: widget.controller),
              const SizedBox(height: 16),
              _KeyboardControlSection(controller: widget.controller),
              const SizedBox(height: 16),
              _HistoricalLayersSection(controller: widget.controller),
              const SizedBox(height: 16),
              _ChangeHighlightSection(controller: widget.controller),
              const SizedBox(height: 16),
              _LegendSection(legend: _legend),
            ],
          ),
        );
      },
    );
  }
}

class _TimeSliderSection extends StatelessWidget {
  const _TimeSliderSection({required this.controller});

  final MapTimeSliderController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(Icons.history_rounded),
            Text(
              "Tick ${controller.currentTick}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("min ${controller.minTick} / max ${controller.maxTick}"),
          ],
        ),
        Slider(
          key: const Key("map-time-slider"),
          value: controller.currentTick.toDouble(),
          min: controller.minTick.toDouble(),
          max: controller.maxTick.toDouble(),
          divisions: controller.tickRange > 1 ? controller.tickRange - 1 : null,
          label: "Tick ${controller.currentTick}",
          onChanged: controller.currentTick == controller.maxTick
              ? null
              : (v) => controller.seekTo(v.round()),
          onChangeEnd: (v) => controller.seekTo(v.round()),
        ),
      ],
    );
  }
}

class _KeyboardControlSection extends StatelessWidget {
  const _KeyboardControlSection({required this.controller});

  final MapTimeSliderController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _KeyButton(
          keyId: "map-time-key-advanceSmall",
          icon: Icons.keyboard_arrow_right_rounded,
          tooltip: "Advance 1 tick",
          onPressed: () => controller.applyKey(MapTimeKey.advanceSmall),
        ),
        _KeyButton(
          keyId: "map-time-key-retreatSmall",
          icon: Icons.keyboard_arrow_left_rounded,
          tooltip: "Retreat 1 tick",
          onPressed: () => controller.applyKey(MapTimeKey.retreatSmall),
        ),
        _KeyButton(
          keyId: "map-time-key-advanceBig",
          icon: Icons.fast_forward_rounded,
          tooltip: "Advance 10 ticks",
          onPressed: () => controller.applyKey(MapTimeKey.advanceBig),
        ),
        _KeyButton(
          keyId: "map-time-key-retreatBig",
          icon: Icons.fast_rewind_rounded,
          tooltip: "Retreat 10 ticks",
          onPressed: () => controller.applyKey(MapTimeKey.retreatBig),
        ),
        _KeyButton(
          keyId: "map-time-key-jumpStart",
          icon: Icons.skip_previous_rounded,
          tooltip: "Jump to start",
          onPressed: () => controller.applyKey(MapTimeKey.jumpStart),
        ),
        _KeyButton(
          keyId: "map-time-key-jumpEnd",
          icon: Icons.skip_next_rounded,
          tooltip: "Jump to end",
          onPressed: () => controller.applyKey(MapTimeKey.jumpEnd),
        ),
        _KeyButton(
          keyId: "map-time-key-nextKeyTick",
          icon: Icons.last_page_rounded,
          tooltip: "Next key tick",
          onPressed: () => controller.applyKey(MapTimeKey.nextKeyTick),
        ),
        _KeyButton(
          keyId: "map-time-key-prevKeyTick",
          icon: Icons.first_page_rounded,
          tooltip: "Previous key tick",
          onPressed: () => controller.applyKey(MapTimeKey.prevKeyTick),
        ),
      ],
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.keyId,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final String keyId;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: Key(keyId),
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}

class _HistoricalLayersSection extends StatelessWidget {
  const _HistoricalLayersSection({required this.controller});

  final MapTimeSliderController controller;

  @override
  Widget build(BuildContext context) {
    final layers = controller.activeLayers;
    if (layers.isEmpty) {
      return Container(
        key: const Key("map-time-layers-empty"),
        padding: const EdgeInsets.all(12),
        child: const Text("No historical layers enabled."),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final layer in layers)
          InputChip(
            key: Key("map-time-layer-chip-${layer.tick}"),
            label: Text("Tick ${layer.tick}"),
            onDeleted: () => controller.disableLayerAt(layer.tick),
            onPressed: () => controller.disableLayerAt(layer.tick),
          ),
      ],
    );
  }
}

class _ChangeHighlightSection extends StatelessWidget {
  const _ChangeHighlightSection({required this.controller});

  final MapTimeSliderController controller;

  @override
  Widget build(BuildContext context) {
    final layer = controller.activeLayerForTick(controller.currentTick);
    if (layer == null) {
      return Container(
        key: const Key("map-time-highlights-empty"),
        padding: const EdgeInsets.all(12),
        child: const Text(
          "Enable a layer at the current tick to see highlights.",
        ),
      );
    }
    if (layer.highlights.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text("No changes at tick ${layer.tick}."),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final highlight in layer.highlights)
          Container(
            key: Key(
              "map-time-highlight-${highlight.kind.name}-${highlight.locationId}",
            ),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black26),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(highlight.reason),
          ),
      ],
    );
  }
}

class _LegendSection extends StatelessWidget {
  const _LegendSection({required this.legend});

  final MapLegend legend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("Legend", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (final entry in legend.entries)
          Container(
            key: Key("map-time-legend-${entry.token}"),
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _colorFor(entry.token),
                    border: Border.all(color: Colors.black26),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(entry.label)),
              ],
            ),
          ),
      ],
    );
  }

  Color _colorFor(String token) {
    switch (token) {
      case "active":
        return Colors.green.shade300;
      case "ruined":
        return Colors.brown.shade300;
      case "abandoned":
        return Colors.grey.shade400;
      case "hidden":
        return Colors.blueGrey.shade300;
      case "contested":
        return Colors.orange.shade300;
    }
    return Colors.black12;
  }
}
