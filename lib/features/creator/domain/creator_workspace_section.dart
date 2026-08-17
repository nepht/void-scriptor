import 'package:flutter/material.dart';

/// Sprint 43 — Step 43.7 Creator Workspace.
///
/// The nine canonical workspace sections for a creator. The workspace reuses
/// the existing Asset Core rather than a second asset database.
enum CreatorWorkspaceSection {
  myProjects('My Projects', Icons.folder_copy_outlined, defaultSection: true),
  myCharacters('My Characters', Icons.person_outline),
  myWorlds('My Worlds', Icons.public_outlined),
  myAssets('My Assets', Icons.photo_library_outlined),
  myStories('My Stories', Icons.menu_book_outlined),
  myAiAgents('My AI Agents', Icons.smart_toy_outlined),
  myWorkflows('My Workflows', Icons.account_tree_outlined),
  portfolio('Portfolio', Icons.work_outline),
  archive('Archive', Icons.archive_outlined);

  const CreatorWorkspaceSection(
    this.label,
    this.icon, {
    this.defaultSection = false,
  });

  final String label;
  final IconData icon;
  final bool defaultSection;

  static CreatorWorkspaceSection fromLabel(String label) {
    for (final value in values) {
      if (value.label.toLowerCase() == label.trim().toLowerCase()) {
        return value;
      }
    }
    return CreatorWorkspaceSection.myProjects;
  }
}
