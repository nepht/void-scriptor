import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release train publishes a signed Windows installer EXE', () {
    final workflow = File('.github/workflows/release-train.yml').readAsStringSync();
    final installer = File('packaging/windows/VoidScriptor.iss').readAsStringSync();

    expect(workflow, contains('Build and sign Windows installer'));
    expect(workflow, contains('R2_EXE_PATH=\$installerPath'));
    expect(workflow, contains('build/release-metadata/*.exe'));
    expect(workflow, contains('windows-x64-signed.exe'));
    expect(workflow, isNot(contains('R2_ZIP_PATH')));
    expect(workflow, isNot(contains('windows-x64-signed.zip')));
    expect(installer, contains('Source: "{#SourceDir}\\*"'));
    expect(installer, contains('OutputBaseFilename=VoidScriptor-{#ReleaseLabel}-windows-x64-signed'));
    expect(installer, contains('void_scriptor.exe'));
  });
}
