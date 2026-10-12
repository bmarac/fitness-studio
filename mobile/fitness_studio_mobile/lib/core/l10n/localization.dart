import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

extension LocalizationBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String formatDate(DateTime value) =>
      DateFormat.yMd(l10n.localeName).format(value.toLocal());

  String formatShortDate(DateTime value) =>
      DateFormat.MMMd(l10n.localeName).format(value.toLocal());

  String formatTime(DateTime value) =>
      DateFormat.Hm(l10n.localeName).format(value.toLocal());

  String formatWeekday(DateTime value, {bool short = false}) => DateFormat(
    short ? 'EEE' : 'EEEE',
    l10n.localeName,
  ).format(value.toLocal());

  String formatNumber(num value, {int? decimalDigits}) =>
      NumberFormat.decimalPatternDigits(
        locale: l10n.localeName,
        decimalDigits: decimalDigits,
      ).format(value);

  String formatCurrency(num value, String currency) =>
      NumberFormat.simpleCurrency(
        locale: l10n.localeName,
        name: currency,
      ).format(value);
}

Locale resolveAppLocale(Locale? deviceLocale, Iterable<Locale> supported) {
  const fallback = Locale('hr');
  if (deviceLocale == null) return fallback;

  for (final locale in supported) {
    if (locale.languageCode == deviceLocale.languageCode) return locale;
  }

  return fallback;
}
