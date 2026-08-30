// Sprint 110.40 - Civilization Tech Tree Workspace (widget).
//
// Read-only presentation of TechTreeController. Composes the
// acceptance surfaces required by sprint_110.json step 110.40:
//   * graph_view: per-node tiles with key tech-tree-node-{id}.
//   * culture_filter: filter chips per culture.
//   * time_filter: atTick slider with apply/clear.
//   * branch_filter: filter chips per branch.
//   * keyboard_navigation: direction + tier advance/retreat.

import "package:flutter/material.dart";

import "../domain/tech_tree_workspace.dart";

class TechTreeWorkspaceView extends StatefulWidget {
  const TechTreeWorkspaceView({super.key, required this.controller});
  final TechTreeController controller;
  @override
  State<TechTreeWorkspaceView> createState() => _TechTreeWorkspaceViewState();
}

class _TechTreeWorkspaceViewState extends State<TechTreeWorkspaceView> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FiltersSection(controller: widget.controller),
                const SizedBox(height: 16),
                _GraphSection(controller: widget.controller),
                const SizedBox(height: 16),
                _KeyboardSection(controller: widget.controller),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FiltersSection extends StatelessWidget {
  const _FiltersSection({required this.controller});
  final TechTreeController controller;

  @override
  Widget build(BuildContext context) {
    // Lists draw from the full registry so users can switch filters even
    // when the current filter hides them.
    final cultures = controller.allCultures;
    final branches = controller.allBranches;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            const Text("Branch:"),
            ChoiceChip(
              key: const Key("tech-tree-filter-branch-all"),
              label: const Text("all"),
              selected: controller.branchFilter == null,
              onSelected: (_) => controller.clearBranch(),
            ),
            for (final b in branches)
              ChoiceChip(
                key: Key("tech-tree-filter-branch-$b"),
                label: Text(b),
                selected: controller.branchFilter == b,
                onSelected: (_) => controller.setBranch(b),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            const Text("Culture:"),
            ChoiceChip(
              key: const Key("tech-tree-filter-culture-all"),
              label: const Text("all"),
              selected: controller.cultureFilter == null,
              onSelected: (_) => controller.clearCulture(),
            ),
            for (final c in cultures)
              ChoiceChip(
                key: Key("tech-tree-filter-culture-$c"),
                label: Text(c),
                selected: controller.cultureFilter == c,
                onSelected: (_) => controller.setCulture(c),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text("Tick:"),
            const SizedBox(width: 8),
            Expanded(
              child: Slider(
                key: const Key("tech-tree-filter-tick-slider"),
                value: (controller.atTickFilter ?? 0).toDouble(),
                min: 0,
                max: 100,
                onChanged: (v) => controller.setAtTick(v.round()),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              key: const Key("tech-tree-filter-tick-apply"),
              onPressed: controller.atTickFilter == null
                  ? null
                  : () => controller.clearAtTick(),
              child: const Text("clear"),
            ),
          ],
        ),
      ],
    );
  }
}

class _GraphSection extends StatelessWidget {
  const _GraphSection({required this.controller});
  final TechTreeController controller;

  @override
  Widget build(BuildContext context) {
    final layout = controller.layout;
    final sorted = [...layout.nodes]
      ..sort((a, b) {
        if (a.generation != b.generation) {
          return a.generation.compareTo(b.generation);
        }
        return a.positionInGeneration.compareTo(b.positionInGeneration);
      });
    final focusedId = controller.focusedNodeId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final node in sorted)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: InkWell(
              key: Key("tech-tree-node-${node.nodeId}"),
              onTap: () => controller.focusNode(node.nodeId),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: focusedId == node.nodeId
                      ? Colors.amber.shade100
                      : Colors.grey.shade100,
                  border: Border.all(
                    color: focusedId == node.nodeId
                        ? Colors.amber
                        : Colors.grey,
                  ),
                ),
                child: Row(
                  children: [
                    Text("tier ${node.tier}"),
                    const SizedBox(width: 8),
                    Expanded(child: Text(node.name)),
                    if (node.culture != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(node.culture!),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _KeyboardSection extends StatelessWidget {
  const _KeyboardSection({required this.controller});
  final TechTreeController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        IconButton(
          key: const Key("tech-tree-key-advanceTier"),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          tooltip: "Advance tier",
          onPressed: () => controller.applyKey(TechTreeKey.advanceTier),
        ),
        IconButton(
          key: const Key("tech-tree-key-retreatTier"),
          icon: const Icon(Icons.keyboard_arrow_up_rounded),
          tooltip: "Retreat tier",
          onPressed: () => controller.applyKey(TechTreeKey.retreatTier),
        ),
        IconButton(
          key: const Key("tech-tree-key-jumpStart"),
          icon: const Icon(Icons.skip_previous_rounded),
          tooltip: "Jump to first discovery",
          onPressed: () => controller.applyKey(TechTreeKey.jumpStart),
        ),
        IconButton(
          key: const Key("tech-tree-key-jumpEnd"),
          icon: const Icon(Icons.skip_next_rounded),
          tooltip: "Jump to last discovery",
          onPressed: () => controller.applyKey(TechTreeKey.jumpEnd),
        ),
        IconButton(
          key: const Key("tech-tree-nav-left"),
          icon: const Icon(Icons.keyboard_arrow_left_rounded),
          tooltip: "Navigate left",
          onPressed: () =>
              controller.navigateDirection(TechTreeNavDirection.left),
        ),
        IconButton(
          key: const Key("tech-tree-nav-right"),
          icon: const Icon(Icons.keyboard_arrow_right_rounded),
          tooltip: "Navigate right",
          onPressed: () =>
              controller.navigateDirection(TechTreeNavDirection.right),
        ),
      ],
    );
  }
}
