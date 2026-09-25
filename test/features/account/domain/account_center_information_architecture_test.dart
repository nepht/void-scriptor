/// Sprint 115.3 — Global Information Architecture contract.
///
/// Validates the canonical global route, nine tabs, deep links, back
/// navigation rules, breadcrumbs, search index, and profile shortcut against
/// the manifest `docs/planning/v1.2/sprint_115_global_information_architecture.json`.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_information_architecture.dart';

void main() {
  final manifestFile = File(
    'docs/planning/v1.2/sprint_115_global_information_architecture.json',
  );

  Map<String, dynamic> readManifest() {
    expect(
      manifestFile.existsSync(),
      isTrue,
      reason: '115.3 manifest must exist',
    );
    return jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  }

  group('115.3 Global Information Architecture', () {
    test('manifest records the canonical global route and legacy alias', () {
      final manifest = readManifest();
      expect(manifest['canonical_step'], '115.3');

      final route = manifest['global_route'] as Map<String, dynamic>;
      expect(route['canonical'], '/account/cloud-center');
      expect(
        route['canonical'],
        AccountCenterInformationArchitecture.canonicalRoute,
      );
      expect(route['legacy_alias'], '/account-cloud');
      expect(
        route['legacy_alias'],
        AccountCenterInformationArchitecture.legacyRoute,
      );
      expect(route['legacy_behavior'], 'redirect_preserving_query');
      expect(route['scope'], 'GLOBAL_USER');
    });

    test('nine canonical tabs keep product-spec order and labels', () {
      const expectedSlugs = [
        'overview',
        'connected_accounts',
        'cloud_storage',
        'ai_providers',
        'api_keys',
        'team_collaboration',
        'security',
        'backup_sync',
        'billing',
      ];
      const expectedLabels = [
        'Overview',
        'Connected Accounts',
        'Cloud Storage',
        'AI Providers',
        'API Keys',
        'Team & Collaboration',
        'Security',
        'Backup & Sync',
        'Billing',
      ];

      final manifest = readManifest();
      final manifestTabs = manifest['tabs'] as List<dynamic>;
      const tabs = AccountCenterInformationArchitecture.tabs;

      expect(tabs.length, 9);
      expect(manifestTabs.length, 9);
      for (var i = 0; i < expectedSlugs.length; i++) {
        final tab = tabs[i];
        expect(tab.slug, expectedSlugs[i], reason: 'slug at index $i');
        expect(tab.label, expectedLabels[i], reason: 'label at index $i');
        expect(tab.searchKeywords, isNotEmpty, reason: tab.slug);

        final entry = manifestTabs[i] as Map<String, dynamic>;
        expect(entry['slug'], tab.slug, reason: 'manifest slug at index $i');
        expect(entry['label'], tab.label, reason: 'manifest label at index $i');
      }
    });

    test('deep links resolve known tabs and fail closed on unknown slugs', () {
      final manifest = readManifest();
      final deepLinks = manifest['deep_links'] as Map<String, dynamic>;

      expect(deepLinks['parameter'], 'tab');
      expect(
        deepLinks['parameter'],
        AccountCenterInformationArchitecture.tabQueryParameter,
      );
      expect(deepLinks['unknown_tab'], 'fallback_overview');

      final apiKeys = AccountCenterInformationArchitecture.tabForSlug(
        'api_keys',
      );
      expect(apiKeys, isNotNull);
      expect(
        AccountCenterInformationArchitecture.deepLinkFor(apiKeys!),
        '/account/cloud-center?tab=api_keys',
      );
      expect(
        AccountCenterInformationArchitecture.tabForSlug('billing'),
        isNotNull,
      );
      expect(
        AccountCenterInformationArchitecture.tabForSlug('does-not-exist'),
        isNull,
      );
      expect(AccountCenterInformationArchitecture.tabForSlug(null), isNull);

      expect(
        AccountCenterInformationArchitecture.resolveTab('does-not-exist').slug,
        'overview',
      );
      expect(
        AccountCenterInformationArchitecture.resolveTab(null).slug,
        'overview',
      );
    });

    test('breadcrumb contract is two levels rooted at the account center', () {
      final manifest = readManifest();
      final crumbs = manifest['breadcrumbs'] as Map<String, dynamic>;

      expect(crumbs['root'], 'Account & Cloud Center');
      expect(
        crumbs['root'],
        AccountCenterInformationArchitecture.breadcrumbRoot,
      );
      expect(crumbs['separator'], ' / ');
      expect(crumbs['depth'], 2);

      final security = AccountCenterInformationArchitecture.resolveTab(
        'security',
      );
      expect(AccountCenterInformationArchitecture.breadcrumbsFor(security), [
        'Account & Cloud Center',
        'Security',
      ]);
      expect(
        AccountCenterInformationArchitecture.breadcrumbsFor(
          security,
        ).join(' / '),
        'Account & Cloud Center / Security',
      );
    });

    test('search index covers every tab with case-insensitive matching', () {
      final manifest = readManifest();
      final search = manifest['search_index'] as Map<String, dynamic>;

      expect(search['entry_count'], 9);
      expect(
        search['entry_count'],
        AccountCenterInformationArchitecture.tabs.length,
      );
      expect(search['blank_query'], 'all_tabs');
      expect(search['scope'], 'account_center_tabs');

      expect(AccountCenterInformationArchitecture.search('').length, 9);
      expect(AccountCenterInformationArchitecture.search('   ').length, 9);
      expect(
        AccountCenterInformationArchitecture.search(
          'BILLING',
        ).map((t) => t.slug),
        contains('billing'),
      );
      expect(
        AccountCenterInformationArchitecture.search(
          'google drive',
        ).map((t) => t.slug),
        contains('cloud_storage'),
      );
      expect(
        AccountCenterInformationArchitecture.search(
          'members',
        ).map((t) => t.slug),
        contains('team_collaboration'),
      );
      expect(
        AccountCenterInformationArchitecture.search('no-such-section'),
        isEmpty,
      );

      for (final tab in AccountCenterInformationArchitecture.tabs) {
        expect(
          AccountCenterInformationArchitecture.search(
            tab.label,
          ).map((t) => t.slug),
          contains(tab.slug),
          reason: 'tab must be reachable by its own label: ${tab.slug}',
        );
      }
    });

    test('profile shortcut and back navigation rules are recorded', () {
      final manifest = readManifest();

      final profile = manifest['profile_shortcut'] as Map<String, dynamic>;
      expect(profile['navigation_key'], 'account-cloud');
      expect(
        profile['navigation_key'],
        AccountCenterInformationArchitecture.profileShortcutKey,
      );
      expect(profile['route'], '/account/cloud-center');
      expect(
        profile['route'],
        AccountCenterInformationArchitecture.canonicalRoute,
      );
      expect(
        profile['entry_points'],
        containsAll([
          'desktop_top_bar_account_menu',
          'mobile_app_bar_account_menu',
        ]),
      );

      final backNav = manifest['back_navigation'] as Map<String, dynamic>;
      expect(backNav['tab_change'], 'push_history_entry');
      expect(backNav['entry_tab'], 'overview');
      expect(backNav['back_order'], ['previous_tab', 'entry_point']);
    });

    test('canonical route stays global and outside workspace scope', () {
      const canonical = AccountCenterInformationArchitecture.canonicalRoute;
      expect(canonical.startsWith('/account/'), isTrue);
      expect(canonical.startsWith('/'), isTrue);
      expect(canonical.contains('/workspace'), isFalse);
      expect(canonical.contains('/studio'), isFalse);
      expect(
        AccountCenterInformationArchitecture.legacyRoute.startsWith('/account'),
        isTrue,
      );
    });
  });
}
