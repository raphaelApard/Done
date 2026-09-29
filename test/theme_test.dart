import 'package:done/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final brightness in Brightness.values) {
    test('${brightness.name} theme carries the project tints', () {
      final theme = buildTheme(brightness, webFonts: false);
      expect(theme.brightness, brightness);
      final tints = theme.extension<ProjectTints>()!;
      expect(tints.tints, hasLength(4));
    });
  }

  test('tints cycle every four projects', () {
    final tints = buildTheme(Brightness.light, webFonts: false).extension<ProjectTints>()!;
    expect(tints.forIndex(0), tints.forIndex(4));
    expect(tints.forIndex(1), isNot(tints.forIndex(2)));
  });

  test('tints interpolate between light and dark', () {
    final light = buildTheme(Brightness.light, webFonts: false).extension<ProjectTints>()!;
    final dark = buildTheme(Brightness.dark, webFonts: false).extension<ProjectTints>()!;
    expect(light.lerp(dark, 0).ink, light.ink);
    expect(light.lerp(dark, 1).ink, dark.ink);
  });
}
