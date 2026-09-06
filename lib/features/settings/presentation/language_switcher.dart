import 'package:flutter/material.dart';

import 'package:void_scriptor/design_system/widgets/branding/brand_assets.dart';

/// Model bahasa yang didukung.
class AppLanguage {
  final String code;
  final String name;
  final String flagAsset;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.flagAsset,
  });
}

/// Daftar bahasa yang didukung Void Scriptor.
class AppLanguages {
  AppLanguages._();

  static const List<AppLanguage> supported = [
    AppLanguage(
      code: 'id',
      name: 'Indonesia',
      flagAsset: BrandAssets.flagIndonesia,
    ),
    AppLanguage(
      code: 'en',
      name: 'English',
      flagAsset: BrandAssets.flagEnglish,
    ),
    AppLanguage(
      code: 'en-GB',
      name: 'British',
      flagAsset: BrandAssets.flagBritain,
    ),
    AppLanguage(code: 'ja', name: '日本語', flagAsset: BrandAssets.flagJapan),
    AppLanguage(code: 'ko', name: '한국어', flagAsset: BrandAssets.flagKorea),
    AppLanguage(code: 'zh', name: '中文', flagAsset: BrandAssets.flagChina),
  ];

  static AppLanguage byCode(String code) => supported.firstWhere(
    (l) => l.code == code,
    orElse: () => supported.first,
  );
}

/// Language switcher dengan bendera.
class LanguageSwitcher extends StatelessWidget {
  final String currentCode;
  final ValueChanged<String> onChanged;
  final bool compact;

  const LanguageSwitcher({
    super.key,
    required this.currentCode,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final current = AppLanguages.byCode(currentCode);

    if (compact) {
      return PopupMenuButton<String>(
        tooltip: 'Language',
        onSelected: onChanged,
        itemBuilder: (context) => [
          for (final lang in AppLanguages.supported)
            PopupMenuItem(
              value: lang.code,
              child: Row(
                children: [
                  BrandLogo(assetPath: lang.flagAsset, width: 20),
                  const SizedBox(width: 10),
                  Text(lang.name),
                ],
              ),
            ),
        ],
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: BrandLogo(assetPath: current.flagAsset, width: 24),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      children: [
        for (final lang in AppLanguages.supported)
          ChoiceChip(
            avatar: BrandLogo(assetPath: lang.flagAsset, width: 18),
            label: Text(lang.name),
            selected: lang.code == currentCode,
            onSelected: (_) => onChanged(lang.code),
          ),
      ],
    );
  }
}
