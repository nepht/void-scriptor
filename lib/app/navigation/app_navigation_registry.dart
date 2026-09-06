import 'package:flutter/material.dart';

import '../routing/app_routes.dart';

enum AppNavigationId {
  dashboard,
  novels,
  write,
  characters,
  world,
  search,
  backupExport,
  settings,
  aiStudio,
  assets,
  projectBible,
  moduleCoverage,
  diagnostics,
  accountCloud,
  support,
}

@immutable
class AppNavigationDestination {
  const AppNavigationDestination({
    required this.id,
    required this.key,
    required this.label,
    required this.icon,
    required this.route,
    this.requiresProject = false,
  });

  final AppNavigationId id;
  final String key;
  final String label;
  final IconData icon;
  final String route;
  final bool requiresProject;
}

const coreNavigationDestinations = <AppNavigationDestination>[
  AppNavigationDestination(
    id: AppNavigationId.dashboard,
    key: 'dashboard',
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    route: AppRoutes.dashboard,
  ),
  AppNavigationDestination(
    id: AppNavigationId.novels,
    key: 'novels',
    label: 'Projects',
    icon: Icons.auto_stories_outlined,
    route: AppRoutes.projects,
  ),
  AppNavigationDestination(
    id: AppNavigationId.characters,
    key: 'characters',
    label: 'Characters',
    icon: Icons.people_outline,
    route: AppRoutes.workspace,
    requiresProject: true,
  ),
  AppNavigationDestination(
    id: AppNavigationId.world,
    key: 'world',
    label: 'World',
    icon: Icons.public_outlined,
    route: AppRoutes.workspace,
    requiresProject: true,
  ),
  AppNavigationDestination(
    id: AppNavigationId.search,
    key: 'search',
    label: 'Search',
    icon: Icons.search,
    route: AppRoutes.assets,
  ),
  AppNavigationDestination(
    id: AppNavigationId.backupExport,
    key: 'backup-export',
    label: 'Backup & Export',
    icon: Icons.cloud_upload_outlined,
    route: AppRoutes.projectBackups,
    requiresProject: true,
  ),
  AppNavigationDestination(
    id: AppNavigationId.settings,
    key: 'settings',
    label: 'Settings',
    icon: Icons.settings_outlined,
    route: AppRoutes.settings,
  ),
];

const mobilePrimaryDestinations = <AppNavigationDestination>[
  AppNavigationDestination(
    id: AppNavigationId.dashboard,
    key: 'dashboard',
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    route: AppRoutes.dashboard,
  ),
  AppNavigationDestination(
    id: AppNavigationId.novels,
    key: 'novels',
    label: 'Novels',
    icon: Icons.auto_stories_outlined,
    route: AppRoutes.projects,
  ),
  AppNavigationDestination(
    id: AppNavigationId.write,
    key: 'write',
    label: 'Write',
    icon: Icons.edit_outlined,
    route: AppRoutes.workspace,
    requiresProject: true,
  ),
  AppNavigationDestination(
    id: AppNavigationId.characters,
    key: 'characters',
    label: 'Characters',
    icon: Icons.people_outline,
    route: AppRoutes.workspace,
    requiresProject: true,
  ),
];

const optionalNavigationDestinations = <AppNavigationDestination>[
  AppNavigationDestination(
    id: AppNavigationId.aiStudio,
    key: 'ai',
    label: 'AI Studio',
    icon: Icons.auto_awesome_outlined,
    route: AppRoutes.aiStudio,
  ),
  AppNavigationDestination(
    id: AppNavigationId.assets,
    key: 'assets',
    label: 'Assets',
    icon: Icons.image_outlined,
    route: AppRoutes.assets,
  ),
  AppNavigationDestination(
    id: AppNavigationId.projectBible,
    key: 'bible',
    label: 'Project Bible',
    icon: Icons.menu_book_outlined,
    route: AppRoutes.bible,
    requiresProject: true,
  ),
  AppNavigationDestination(
    id: AppNavigationId.moduleCoverage,
    key: 'content-capabilities',
    label: 'Module Coverage',
    icon: Icons.view_list_outlined,
    route: AppRoutes.contentCapabilities,
  ),
  AppNavigationDestination(
    id: AppNavigationId.diagnostics,
    key: 'resilience',
    label: 'Diagnostics',
    icon: Icons.health_and_safety_outlined,
    route: AppRoutes.projectDiagnostics,
    requiresProject: true,
  ),
  AppNavigationDestination(
    id: AppNavigationId.accountCloud,
    key: 'account-cloud',
    label: 'Account & Cloud',
    icon: Icons.cloud_outlined,
    route: AppRoutes.accountCloud,
  ),
  AppNavigationDestination(
    id: AppNavigationId.support,
    key: 'donate',
    label: 'Support',
    icon: Icons.favorite_outline,
    route: AppRoutes.donation,
  ),
];

AppNavigationDestination navigationDestinationForKey(String key) => [
  ...coreNavigationDestinations,
  ...mobilePrimaryDestinations,
  ...optionalNavigationDestinations,
].firstWhere((item) => item.key == key);
