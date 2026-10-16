import 'package:fitness_studio_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app bar appearance stays unchanged when content scrolls under it', () {
    final appBarTheme = AppTheme.light.appBarTheme;

    expect(appBarTheme.backgroundColor, const Color(0xFFF8FAFC));
    expect(appBarTheme.elevation, 0);
    expect(appBarTheme.scrolledUnderElevation, 0);
    expect(appBarTheme.surfaceTintColor, Colors.transparent);
  });
}
