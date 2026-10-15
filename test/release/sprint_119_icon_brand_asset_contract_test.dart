import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/application/sprint_119_icon_brand_asset_contract.dart';

void main() {
  final digest = List<String>.filled(64, 'a').join();

  IconAsset asset({
    String iconRef = 'iconref:alpha:logo',
    IconSource source = IconSource.bundled,
    IconPermission permission = IconPermission.allowed,
    String version = '1.2.0',
    IconVariant? light = const IconVariant(reference: 'assets/alpha/logo.svg'),
    IconVariant? dark = const IconVariant(
      reference: 'assets/alpha/logo-dark.svg',
    ),
    IconFallback fallback = IconFallback.hostDefault,
    String? fallbackRef,
    String accessibleName = 'Alpha provider logo',
  }) => IconAsset(
    iconRef: iconRef,
    source: source,
    permission: permission,
    version: version,
    light: light,
    dark: dark,
    fallback: fallback,
    fallbackRef: fallbackRef,
    accessibleName: accessibleName,
  );

  group('119.20 Icon & Brand Asset Contract', () {
    test('the canonical field vocabulary is complete', () {
      expect(IconAssetContract.requiredFields, <String>[
        'icon_ref',
        'source',
        'permission',
        'version',
        'light',
        'dark',
        'fallback',
        'accessible_name',
      ]);
      expect(
        asset().toJson().keys.toSet(),
        containsAll(IconAssetContract.requiredFields),
      );
    });

    test('a fully specified asset is accepted', () {
      expect(IconAssetContract.validateAsset(asset()), isEmpty);
      expect(
        IconAssetContract.validateAsset(
          asset(
            source: IconSource.remoteUrl,
            light: IconVariant(
              reference: 'https://cdn.alpha.example/logo.svg',
              digest: digest,
            ),
            dark: IconVariant(
              reference: 'https://cdn.alpha.example/logo-dark.svg',
              digest: digest,
            ),
          ),
        ),
        isEmpty,
      );
    });

    test('permission is deny-by-default', () {
      for (final permission in <IconPermission>[
        IconPermission.denied,
        IconPermission.restricted,
        IconPermission.unknown,
      ]) {
        expect(
          IconAssetContract.validateAsset(asset(permission: permission)),
          contains('permission_not_allowed'),
        );
      }
      expect(IconAssetContract.isUsable(asset()), isTrue);
      expect(
        IconAssetContract.isUsable(asset(permission: IconPermission.denied)),
        isFalse,
      );
    });

    test('the source vocabulary is closed and refuses inline data', () {
      expect(
        IconAssetContract.validateAsset(asset(source: IconSource.unknown)),
        contains('source_unknown'),
      );
      expect(
        IconAssetContract.validateAsset(asset(source: IconSource.dataUri)),
        contains('source_refused'),
      );
      expect(
        IconAssetContract.validateAsset(
          asset(
            source: IconSource.remoteUrl,
            light: IconVariant(
              reference: 'http://cdn.alpha.example/logo.svg',
              digest: digest,
            ),
            dark: IconVariant(
              reference: 'https://cdn.alpha.example/logo-dark.svg',
              digest: digest,
            ),
          ),
        ),
        contains('transport_not_tls'),
      );
    });

    test('a remote asset must carry an integrity digest', () {
      expect(
        IconAssetContract.validateAsset(
          asset(
            source: IconSource.remoteUrl,
            light: const IconVariant(
              reference: 'https://cdn.alpha.example/logo.svg',
            ),
            dark: const IconVariant(
              reference: 'https://cdn.alpha.example/logo-dark.svg',
            ),
          ),
        ),
        contains('digest_missing'),
      );
      expect(
        IconAssetContract.validateAsset(
          asset(
            source: IconSource.remoteUrl,
            light: IconVariant(
              reference: 'https://cdn.alpha.example/logo.svg',
              digest: 'ABC123',
            ),
            dark: IconVariant(
              reference: 'https://cdn.alpha.example/logo-dark.svg',
              digest: digest,
            ),
          ),
        ),
        contains('digest_invalid'),
      );
    });

    test(
      'bundled references must be safe relative paths with a known extension',
      () {
        expect(
          IconAssetContract.validateAsset(
            asset(light: const IconVariant(reference: '../secrets/logo.svg')),
          ),
          contains('variant_reference_unsafe'),
        );
        expect(
          IconAssetContract.validateAsset(
            asset(light: const IconVariant(reference: '/etc/logo.svg')),
          ),
          contains('variant_reference_unsafe'),
        );
        expect(
          IconAssetContract.validateAsset(
            asset(light: const IconVariant(reference: 'assets\\logo.svg')),
          ),
          contains('variant_reference_unsafe'),
        );
        expect(
          IconAssetContract.validateAsset(
            asset(light: const IconVariant(reference: 'assets/logo.exe')),
          ),
          contains('variant_extension_unsupported'),
        );
        expect(
          IconAssetContract.validateAsset(
            asset(light: const IconVariant(reference: 'assets/logo.svg')),
          ),
          isEmpty,
        );
      },
    );

    test('version must be a semantic version core', () {
      for (final version in <String>[
        '',
        'latest',
        'v1.2.0',
        '1.2',
        '1.2.0.4',
      ]) {
        expect(
          IconAssetContract.validateAsset(asset(version: version)),
          contains('version_invalid'),
          reason: 'version "$version" must be refused',
        );
      }
      expect(
        IconAssetContract.validateAsset(asset(version: '10.0.3')),
        isEmpty,
      );
    });

    test('both themes are required', () {
      expect(
        IconAssetContract.validateAsset(asset(light: null)),
        contains('theme_missing:light'),
      );
      expect(
        IconAssetContract.validateAsset(asset(dark: null)),
        contains('theme_missing:dark'),
      );
      expect(
        IconAssetContract.validateAsset(asset(light: null, dark: null)),
        containsAll(<String>['theme_missing:light', 'theme_missing:dark']),
      );
    });

    test('a fallback is mandatory and must be well formed', () {
      expect(
        IconAssetContract.validateAsset(asset(fallback: IconFallback.none)),
        contains('fallback_missing'),
      );
      expect(
        IconAssetContract.validateAsset(
          asset(fallback: IconFallback.declaredRef, fallbackRef: 'logo'),
        ),
        contains('fallback_ref_invalid'),
      );
      expect(
        IconAssetContract.validateAsset(
          asset(
            fallback: IconFallback.declaredRef,
            fallbackRef: 'iconref:alpha:fallback',
          ),
        ),
        isEmpty,
      );
      expect(
        IconAssetContract.validateAsset(
          asset(fallback: IconFallback.declaredRef),
        ),
        contains('fallback_ref_invalid'),
      );
    });

    test('the accessible name must be human readable, never a reference', () {
      expect(
        IconAssetContract.validateAsset(asset(accessibleName: '')),
        contains('accessible_name_empty'),
      );
      expect(
        IconAssetContract.validateAsset(
          asset(accessibleName: List<String>.filled(81, 'a').join()),
        ),
        contains('accessible_name_too_long'),
      );
      expect(
        IconAssetContract.validateAsset(asset(accessibleName: '<b>Alpha</b>')),
        contains('accessible_name_not_plain'),
      );
      expect(
        IconAssetContract.validateAsset(
          asset(accessibleName: 'iconref:alpha:logo'),
        ),
        contains('accessible_name_is_ref'),
      );
      expect(
        IconAssetContract.validateAsset(
          asset(accessibleName: 'Logo penyedia Alpha'),
        ),
        isEmpty,
      );
    });

    test('the registry is append-only, deduplicated, and theme aware', () {
      final registry = ProviderIconRegistry();
      expect(registry.register(asset()), isEmpty);
      expect(registry.count, 1);
      expect(registry.contains('iconref:alpha:logo'), isTrue);

      expect(registry.register(asset()), contains('icon_ref_duplicate'));
      expect(registry.count, 1);

      expect(
        registry.resolve(iconRef: 'iconref:alpha:logo', theme: IconTheme.light),
        'assets/alpha/logo.svg',
      );
      expect(
        registry.resolve(iconRef: 'iconref:alpha:logo', theme: IconTheme.dark),
        'assets/alpha/logo-dark.svg',
      );
      expect(
        registry.resolve(
          iconRef: 'iconref:alpha:missing',
          theme: IconTheme.light,
        ),
        IconAssetContract.hostDefaultFallback,
      );
      expect(
        registry.resolve(
          iconRef: 'iconref:alpha:logo',
          theme: IconTheme.unknown,
        ),
        IconAssetContract.hostDefaultFallback,
      );
      expect(registry.assets, hasLength(1));
    });

    test('the registry never registers or resolves a denied asset', () {
      final registry = ProviderIconRegistry();
      expect(
        registry.register(asset(permission: IconPermission.denied)),
        contains('permission_not_allowed'),
      );
      expect(registry.count, 0);
      expect(
        registry.resolve(iconRef: 'iconref:alpha:logo', theme: IconTheme.light),
        IconAssetContract.hostDefaultFallback,
      );
      expect(() => registry.assets.add(asset()), throwsUnsupportedError);
    });

    test('diagnostics redact icon references', () {
      expect(
        IconAssetContract.redact('iconref:alpha:logo provref:alpha:connector'),
        '[REDACTED] [REDACTED]',
      );
    });

    test('validates the canonical manifest field vocabulary', () {
      expect(IconAssetContract.validateCanonicalManifest(), isEmpty);

      expect(
        IconAssetContract.validateManifest(<String, dynamic>{
          'canonical_step': '119.20',
          'unknown_field_policy': 'REJECT',
          'required_fields': <String, dynamic>{
            'icon_ref': <String, dynamic>{},
            'light': <String, dynamic>{},
          },
        }),
        containsAll(<String>[
          'field_missing:permission',
          'field_missing:accessible_name',
        ]),
      );
      expect(
        IconAssetContract.validateManifest(<String, dynamic>{
          'canonical_step': '119.19',
          'unknown_field_policy': 'ALLOW',
        }),
        containsAll(<String>[
          'canonical_step_invalid',
          'unknown_field_policy_invalid',
          'field_missing:icon_ref',
        ]),
      );
    });
  });
}
