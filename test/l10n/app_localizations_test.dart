import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/l10n/app_localizations.dart';

void main() {
  test('loads the English welcome pilot strings', () {
    const l10n = AppLocalizations(Locale('en'));

    expect(l10n.welcomeTitle, 'Welcome to Void Scriptor Studio');
    expect(l10n.createProject, 'Create Project');
    expect(l10n.openProject, 'Open Project');
    expect(l10n.exploreDemo, 'Explore Demo');
  });

  test(
    'loads Indonesian strings and falls back to English for unknown locale',
    () {
      const id = AppLocalizations(Locale('id'));
      const fallback = AppLocalizations(Locale('ja'));

      expect(id.welcomeTitle, 'Selamat datang di Void Scriptor Studio');
      expect(id.createProject, 'Buat Proyek');
      expect(fallback.welcomeTitle, 'Welcome to Void Scriptor Studio');
    },
  );

  test('exposes a Material localizations delegate for en and id', () async {
    expect(AppLocalizations.delegate.isSupported(const Locale('en')), isTrue);
    expect(AppLocalizations.delegate.isSupported(const Locale('id')), isTrue);
    expect(AppLocalizations.delegate.isSupported(const Locale('ja')), isFalse);

    final loaded = await AppLocalizations.delegate.load(const Locale('id'));
    expect(loaded.openProject, 'Buka Proyek');
  });
}
