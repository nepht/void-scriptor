// Dock Layout — v1.0.0
// Toggle Explorer/Inspector/TopBar + save/restore dock_layout.json.

import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;

enum DockPosition { left, right, top, bottom, floating }

class DockPanel {
  final String id;
  final String title;
  final DockPosition position;
  final bool visible;
  final double width;
  final double height;

  DockPanel({
    required this.id,
    required this.title,
    this.position = DockPosition.left,
    this.visible = true,
    this.width = 300,
    this.height = 400,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'position': position.name,
        'visible': visible,
        'width': width,
        'height': height,
      };

  factory DockPanel.fromJson(Map<String, dynamic> json) => DockPanel(
        id: json['id'] as String,
        title: json['title'] as String,
        position: DockPosition.values.firstWhere(
          (p) => p.name == json['position'],
          orElse: () => DockPosition.left,
        ),
        visible: json['visible'] as bool? ?? true,
        width: (json['width'] as num?)?.toDouble() ?? 300,
        height: (json['height'] as num?)?.toDouble() ?? 400,
      );
}

class DockLayout {
  final List<DockPanel> panels;

  DockLayout({this.panels = const []});

  Future<void> save(Directory appDir) async {
    final file = File(p.join(appDir.path, 'dock_layout.json'));
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode(panels.map((p) => p.toJson()).toList()),
    );
  }

  static Future<DockLayout> load(Directory appDir) async {
    final file = File(p.join(appDir.path, 'dock_layout.json'));
    if (!await file.exists()) return DockLayout();
    final raw = jsonDecode(await file.readAsString()) as List;
    return DockLayout(
      panels: raw.map((e) => DockPanel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
