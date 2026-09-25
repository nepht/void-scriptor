import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_icon_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('115.8 Provider Icon Registry acceptance contract', () {
    test('acceptance canonical is pinned to sprint 115.8', () {
      final file = File(ProviderIconRegistry.canonicalSprintPath);
      expect(file.existsSync(), isTrue);
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final step = (json['steps'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((entry) => entry['id'] == '115.8');

      expect(step['title'], 'Provider Icon Registry');
      expect(step['acceptance'], ProviderIconRegistry.canonicalAcceptance);
      expect(
        ProviderIconRegistry.canonicalSprintSha256,
        'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba',
      );
    });

    test('required fields and official-asset rules come from product spec', () {
      expect(ProviderIconRegistry.requiredFields, <String>[
        'provider_id',
        'display_name',
        'category',
        'asset_light',
        'asset_dark',
        'monochrome_fallback',
        'trademark_notice',
        'asset_version',
      ]);
      expect(ProviderIconRegistry.policyRules, <String>[
        'Use official provider assets only when licensing and brand rules permit.',
        'Do not redraw, recolor, stretch, crop, or combine official marks unless provider rules explicitly allow it.',
        'Preserve aspect ratio and clear space.',
        'Use a generic category icon when an official asset is unavailable or cannot be bundled.',
        'Provider icon is never the only status indicator; include text and accessible status.',
        'Remote icon download must be optional, cached safely, and never block account access.',
      ]);
    });
  });

  group('ProviderIconRegistry lookup and fallback', () {
    test('looks up canonical providers by provider_id', () {
      expect(
        ProviderIconRegistry.standard.require('openai').displayName,
        'OpenAI',
      );
      expect(
        ProviderIconRegistry.standard.require('google_drive').displayName,
        'Google Drive',
      );
      expect(ProviderIconRegistry.standard.get('missing-provider'), isNull);
      expect(
        () => ProviderIconRegistry.standard.require('missing-provider'),
        throwsStateError,
      );
    });

    test('unknown providers fail closed to a generic category fallback', () {
      final icon = ProviderIconRegistry.standard.resolve('missing-provider');
      expect(icon.isOfficialAsset, isFalse);
      expect(icon.usesGenericFallback, isTrue);
      expect(icon.displayName, 'Provider');
      expect(icon.accessibleName, 'Provider icon unavailable');
      expect(icon.assetVersion, 'generic-v1');
    });

    test(
      'category fallback preserves category identity without claiming connector',
      () {
        final icon = ProviderIconRegistry.standard.resolveForCategory(
          ProviderIconCategory.cloudStorage,
        );
        expect(icon.providerId, 'generic-cloud_storage');
        expect(icon.category, ProviderIconCategory.cloudStorage);
        expect(icon.isOfficialAsset, isFalse);
        expect(icon.usesGenericFallback, isTrue);
        expect(icon.accessibleName, 'Cloud storage icon unavailable');
        expect(icon.providerId, isNotEmpty);
      },
    );

    test('duplicates and malformed entries are rejected', () {
      expect(
        () => ProviderIconRegistry([
          ProviderIconEntry.fixture('same'),
          ProviderIconEntry.fixture('same'),
        ]),
        throwsArgumentError,
      );
      expect(
        () => ProviderIconRegistry([
          ProviderIconEntry.fixture('valid', assetVersion: ' '),
        ]),
        throwsArgumentError,
      );
      expect(
        () => ProviderIconRegistry([
          ProviderIconEntry.fixture('valid', displayName: ' '),
        ]),
        throwsArgumentError,
      );
    });
  });

  group('ProviderIconEntry asset and accessibility contract', () {
    test('official assets pin light/dark variants, version, and notice', () {
      final entry = ProviderIconRegistry.standard.require('github');
      expect(entry.providerId, 'github');
      expect(entry.category, ProviderIconCategory.developer);
      expect(entry.assetLight, isNotNull);
      expect(entry.assetDark, entry.assetLight);
      expect(entry.monochromeFallback, ProviderIconFallback.developer);
      expect(entry.assetVersion, isNotNull);
      expect(entry.assetVersion, isNotEmpty);
      expect(entry.trademarkNotice, isNotEmpty);
      expect(entry.isOfficialAsset, isTrue);
      expect(entry.usesGenericFallback, isFalse);
      expect(entry.accessibleName, 'GitHub icon');
    });

    test('aspect ratio is constrained to contain without crop or stretch', () {
      final entry = ProviderIconRegistry.standard.require('openai');
      expect(entry.aspectRatioPolicy, ProviderIconAspectRatio.preserve);
      expect(entry.widthForHeight(48), 48);
      expect(entry.heightForWidth(100), greaterThan(0));
      expect(entry.fit, ProviderIconFit.contain);
    });

    test('official entry without a bundlable asset resolves generically', () {
      final registry = ProviderIconRegistry([
        ProviderIconEntry.fixture(
          'unlicensed',
          assetLight: null,
          assetDark: null,
        ),
      ]);
      final resolved = registry.resolve('unlicensed');
      expect(resolved.isOfficialAsset, isFalse);
      expect(resolved.usesGenericFallback, isTrue);
      expect(resolved.displayName, 'unlicensed');
      expect(resolved.accessibleName, 'unlicensed icon unavailable');
    });

    test('providerId and displayName normalize without changing identity', () {
      final entry = ProviderIconEntry.fixture(
        ' Mixed_Case ',
        displayName: '  Mixed Case  ',
      );
      expect(entry.providerId, 'mixed_case');
      expect(entry.displayName, 'Mixed Case');
      expect(entry.assetVersion, isNotEmpty);
    });
  });

  group('ProviderIconRegistry bundled assets', () {
    test('all bundled assets exist and are declared in pubspec', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final entry in ProviderIconRegistry.standard.all) {
        for (final path in [entry.assetLight, entry.assetDark]) {
          if (path == null) continue;
          expect(File(path).existsSync(), isTrue, reason: path);
          final assetDirectory = path.substring(0, path.lastIndexOf('/') + 1);
          expect(pubspec, contains(assetDirectory), reason: path);
        }
      }
    });

    test('target provider list is present without claiming availability', () {
      const targetIds = <String>{
        'email',
        'google',
        'microsoft',
        'apple',
        'github',
        'discord',
        'x',
        'facebook',
        'google_drive',
        'onedrive',
        'dropbox',
        'mega',
        'local_storage',
        'openai',
        'gemini',
        'anthropic',
        'flux',
        'openrouter',
        'local_ai',
        'gitlab',
        'bitbucket',
        'azure_devops',
        'figma',
        'adobe',
        'canva',
        'blender_cloud',
        'sketchfab',
        'paypal',
        'stripe',
        'midtrans',
        'saweria',
        'kofi',
      };
      expect(
        targetIds.every(
          (id) => ProviderIconRegistry.standard.resolve(id).isKnownProvider,
        ),
        isTrue,
      );
    });
  });
}
