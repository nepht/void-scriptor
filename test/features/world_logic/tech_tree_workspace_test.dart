// Sprint 110.40 - Civilization Tech Tree Workspace (domain + widget).
//
// Covers the canonical acceptance surfaces:
//   * graph_view - layout assigns tier-based positions and renders nodes.
//   * culture_filter - restrict to a culture; null = all.
//   * time_filter - atTick restricts to nodes discovered at or before tick.
//   * branch_filter - restrict to a branch; null = prime only.
//   * keyboard_navigation - direction keys + advance/retreat focus.

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "package:void_scriptor/features/world_logic/domain/tech_tree_workspace.dart";
import "package:void_scriptor/features/world_logic/domain/technology_node_prerequisite_model.dart";
import "package:void_scriptor/features/world_logic/presentation/tech_tree_workspace_view.dart";

TechnologySource _src([String label = "rev"]) =>
    TechnologySource.validated(revision: label, reason: label);

TechnologyNode _node({
  required String id,
  required String name,
  String? culture,
  TechnologyScope scope = TechnologyScope.civil,
  String branch = "prime",
  int tier = 1,
  List<String> prerequisites = const [],
}) {
  return TechnologyNode.validated(
    id: id,
    name: name,
    culture: culture,
    scope: scope,
    branch: branch,
    tier: tier,
    prerequisites: prerequisites,
    source: _src(),
  );
}

TechnologyRegistry _sampleRegistry() {
  return TechnologyRegistry.validated(
    nodes: [
      _node(id: "t-wheel", name: "Wheel", tier: 1),
      _node(id: "t-horse", name: "Horse Domestication", tier: 1),
      _node(
        id: "t-bronze",
        name: "Bronze Casting",
        tier: 2,
        prerequisites: ["t-wheel"],
      ),
      _node(
        id: "t-iron",
        name: "Iron Smelting",
        tier: 3,
        prerequisites: ["t-bronze"],
      ),
      _node(
        id: "t-gunpowder",
        name: "Black Powder",
        culture: "han",
        tier: 4,
        prerequisites: ["t-iron"],
      ),
      _node(
        id: "t-pirate",
        name: "Skyship Plank",
        culture: "sky",
        branch: "alt",
        tier: 2,
      ),
    ],
  );
}

TechnologyDiscoveryTimeline _sampleTimeline() {
  return TechnologyDiscoveryTimeline.validated(
    events: [
      TechnologyDiscoveryEvent.validated(
        id: "d-wheel",
        technologyId: "t-wheel",
        tick: 5,
        summary: "wheel",
        source: _src(),
      ),
      TechnologyDiscoveryEvent.validated(
        id: "d-horse",
        technologyId: "t-horse",
        tick: 8,
        summary: "horse",
        source: _src(),
      ),
      TechnologyDiscoveryEvent.validated(
        id: "d-bronze",
        technologyId: "t-bronze",
        tick: 20,
        summary: "bronze",
        source: _src(),
      ),
      TechnologyDiscoveryEvent.validated(
        id: "d-iron",
        technologyId: "t-iron",
        tick: 40,
        summary: "iron",
        source: _src(),
      ),
      TechnologyDiscoveryEvent.validated(
        id: "d-pirate",
        technologyId: "t-pirate",
        tick: 15,
        summary: "plank",
        source: _src(),
      ),
    ],
  );
}

void main() {
  group("graph_view", () {
    test("layout assigns generation equal to tier", () {
      final controller = TechTreeController.forRegistry(
        registry: _sampleRegistry(),
        timeline: _sampleTimeline(),
      );
      final layout = controller.layout;
      final wheel = layout.nodes.firstWhere((n) => n.nodeId == "t-wheel");
      final bronze = layout.nodes.firstWhere((n) => n.nodeId == "t-bronze");
      final iron = layout.nodes.firstWhere((n) => n.nodeId == "t-iron");
      expect(wheel.generation, 1);
      expect(bronze.generation, 2);
      expect(iron.generation, 3);
      expect(bronze.parentIds, ["t-wheel"]);
      expect(iron.parentIds, ["t-bronze"]);
    });

    test("layout includes all prime nodes by default", () {
      final controller = TechTreeController.forRegistry(
        registry: _sampleRegistry(),
        timeline: _sampleTimeline(),
      );
      expect(controller.layout.visibleNodeIds.toSet(), {
        "t-wheel",
        "t-horse",
        "t-bronze",
        "t-iron",
        "t-gunpowder",
      });
    });
  });

  group("culture_filter", () {
    test("setCulture restricts layout to that culture", () {
      final controller = TechTreeController.forRegistry(
        registry: _sampleRegistry(),
        timeline: _sampleTimeline(),
      );
      controller.setCulture("han");
      expect(controller.layout.visibleNodeIds.toSet(), {"t-gunpowder"});
    });

    test("clearCulture restores the full prime layout", () {
      final controller = TechTreeController.forRegistry(
        registry: _sampleRegistry(),
        timeline: _sampleTimeline(),
      );
      controller.setCulture("han");
      controller.clearCulture();
      expect(controller.layout.visibleNodeIds.length, 5);
    });

    test("setCulture rejects empty culture", () {
      final controller = TechTreeController.forRegistry(
        registry: _sampleRegistry(),
        timeline: _sampleTimeline(),
      );
      expect(() => controller.setCulture(""), throwsArgumentError);
    });
  });

  group("time_filter", () {
    test("setAtTick removes nodes discovered after tick", () {
      final controller = TechTreeController.forRegistry(
        registry: _sampleRegistry(),
        timeline: _sampleTimeline(),
      );
      controller.setAtTick(20);
      // Pirate is on the alt branch (hidden by default prime filter).
      expect(controller.layout.visibleNodeIds.toSet(), {
        "t-wheel",
        "t-horse",
        "t-bronze",
      });
    });

    test("clearAtTick removes the time filter", () {
      final controller = TechTreeController.forRegistry(
        registry: _sampleRegistry(),
        timeline: _sampleTimeline(),
      );
      controller.setAtTick(10);
      controller.clearAtTick();
      expect(controller.layout.visibleNodeIds.length, 5);
    });

    test("setAtTick rejects negative tick", () {
      final controller = TechTreeController.forRegistry(
        registry: _sampleRegistry(),
        timeline: _sampleTimeline(),
      );
      expect(() => controller.setAtTick(-1), throwsArgumentError);
    });
  });

  group("branch_filter", () {
    test("setBranch alt exposes only alt nodes", () {
      final controller = TechTreeController.forRegistry(
        registry: _sampleRegistry(),
        timeline: _sampleTimeline(),
      );
      controller.setBranch("alt");
      expect(controller.layout.visibleNodeIds.toSet(), {"t-pirate"});
    });

    test("default branch is prime and hides alt nodes", () {
      final controller = TechTreeController.forRegistry(
        registry: _sampleRegistry(),
        timeline: _sampleTimeline(),
      );
      expect(controller.layout.visibleNodeIds.contains("t-pirate"), isFalse);
    });

    test("clearBranch restores the full prime view", () {
      final controller = TechTreeController.forRegistry(
        registry: _sampleRegistry(),
        timeline: _sampleTimeline(),
      );
      controller.setBranch("alt");
      controller.clearBranch();
      expect(controller.layout.visibleNodeIds.length, 5);
    });
  });

  group("keyboard_navigation", () {
    test("applyKey retreatTier moves focus to a prerequisite", () {
      final controller = TechTreeController.forRegistry(
        registry: _sampleRegistry(),
        timeline: _sampleTimeline(),
      );
      controller.focusNode("t-iron");
      controller.applyKey(TechTreeKey.retreatTier);
      expect(controller.focusedNodeId, "t-bronze");
    });
    test("applyKey jumpStart and jumpEnd seek to first/last discovered", () {
      final controller = TechTreeController.forRegistry(
        registry: _sampleRegistry(),
        timeline: _sampleTimeline(),
      );
      controller.applyKey(TechTreeKey.jumpStart);
      expect(controller.focusedNodeId, "t-wheel");
      controller.applyKey(TechTreeKey.jumpEnd);
      expect(controller.focusedNodeId, "t-iron");
    });
    test("navigateDirection right moves along tier siblings", () {
      final controller = TechTreeController.forRegistry(
        registry: _sampleRegistry(),
        timeline: _sampleTimeline(),
      );
      controller.focusNode("t-horse");
      final next = controller.navigateDirection(TechTreeNavDirection.right);
      expect(next, "t-wheel");
    });
    test("navigateDirection returns null when no neighbour exists", () {
      final controller = TechTreeController.forRegistry(
        registry: _sampleRegistry(),
        timeline: _sampleTimeline(),
      );
      controller.focusNode("t-horse");
      expect(controller.navigateDirection(TechTreeNavDirection.left), isNull);
    });
    test("focusNode rejects unknown nodeId", () {
      final controller = TechTreeController.forRegistry(
        registry: _sampleRegistry(),
        timeline: _sampleTimeline(),
      );
      expect(() => controller.focusNode("ghost"), throwsArgumentError);
    });
  });

  group("widget - TechTreeWorkspaceView", () {
    testWidgets("renders a node per visible technology", (tester) async {
      final controller = TechTreeController.forRegistry(
        registry: _sampleRegistry(),
        timeline: _sampleTimeline(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TechTreeWorkspaceView(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("tech-tree-node-t-wheel")), findsOneWidget);
      expect(find.byKey(const Key("tech-tree-node-t-iron")), findsOneWidget);
      expect(find.text("Wheel"), findsOneWidget);
    });
    testWidgets("tapping a node focuses it", (tester) async {
      final controller = TechTreeController.forRegistry(
        registry: _sampleRegistry(),
        timeline: _sampleTimeline(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TechTreeWorkspaceView(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("tech-tree-node-t-bronze")));
      await tester.pumpAndSettle();
      expect(controller.focusedNodeId, "t-bronze");
    });
    testWidgets("culture filter chip restricts visibility", (tester) async {
      final controller = TechTreeController.forRegistry(
        registry: _sampleRegistry(),
        timeline: _sampleTimeline(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TechTreeWorkspaceView(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();
      // Default prime branch hides the alt (sky) pirate.
      expect(find.byKey(const Key("tech-tree-node-t-pirate")), findsNothing);
      expect(find.byKey(const Key("tech-tree-node-t-wheel")), findsOneWidget);
      await tester.tap(find.byKey(const Key("tech-tree-filter-culture-sky")));
      await tester.pumpAndSettle();
      // Culture filter overrides branch filter, surfacing pirate (sky, alt).
      expect(find.byKey(const Key("tech-tree-node-t-pirate")), findsOneWidget);
      expect(find.byKey(const Key("tech-tree-node-t-wheel")), findsNothing);
    });
    testWidgets("branch filter chip restricts to that branch", (tester) async {
      final controller = TechTreeController.forRegistry(
        registry: _sampleRegistry(),
        timeline: _sampleTimeline(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TechTreeWorkspaceView(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("tech-tree-filter-branch-alt")));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("tech-tree-node-t-pirate")), findsOneWidget);
      expect(find.byKey(const Key("tech-tree-node-t-wheel")), findsNothing);
    });
    testWidgets("time filter setAtTick hides later discoveries", (
      tester,
    ) async {
      final controller = TechTreeController.forRegistry(
        registry: _sampleRegistry(),
        timeline: _sampleTimeline(),
      );
      controller.setAtTick(5);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TechTreeWorkspaceView(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("tech-tree-node-t-wheel")), findsOneWidget);
      expect(find.byKey(const Key("tech-tree-node-t-iron")), findsNothing);
    });
    testWidgets("keyboard advance button moves focus", (tester) async {
      final controller = TechTreeController.forRegistry(
        registry: _sampleRegistry(),
        timeline: _sampleTimeline(),
      );
      controller.focusNode("t-horse");
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TechTreeWorkspaceView(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("tech-tree-key-advanceTier")));
      await tester.pumpAndSettle();
      expect(controller.focusedNodeId, "t-bronze");
    });
    testWidgets("navigate right button moves to tier sibling", (tester) async {
      final controller = TechTreeController.forRegistry(
        registry: _sampleRegistry(),
        timeline: _sampleTimeline(),
      );
      controller.focusNode("t-horse");
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TechTreeWorkspaceView(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("tech-tree-nav-right")));
      await tester.pumpAndSettle();
      expect(controller.focusedNodeId, "t-wheel");
    });
  });
}
