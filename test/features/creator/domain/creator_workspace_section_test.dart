import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/domain/creator_workspace_section.dart';

void main() {
  group('CreatorWorkspaceSection', () {
    test('exposes the canonical workspace sections in order', () {
      expect(CreatorWorkspaceSection.values.map((e) => e.label), [
        'My Projects',
        'My Characters',
        'My Worlds',
        'My Assets',
        'My Stories',
        'My AI Agents',
        'My Workflows',
        'Portfolio',
        'Archive',
      ]);
    });

    test('maps to a stable icon and default', () {
      expect(CreatorWorkspaceSection.values.first.defaultSection, isTrue);
      expect(CreatorWorkspaceSection.archive.icon, Icons.archive_outlined);
    });

    test('parses from label', () {
      expect(
        CreatorWorkspaceSection.fromLabel('My AI Agents'),
        CreatorWorkspaceSection.myAiAgents,
      );
      expect(
        CreatorWorkspaceSection.fromLabel('unknown'),
        CreatorWorkspaceSection.myProjects,
      );
    });
  });
}
