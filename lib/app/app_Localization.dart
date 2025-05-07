import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../Helper/String.dart'; // for baseUrl, getTranslationsApi, etc.

class AppLocalization {
  AppLocalization(this.locale);
  final Locale locale;

  // ✅ Store translations for all loaded languages
  static final Map<String, Map<String, String>> _localizedValuesByLang = {};

  static AppLocalization? of(BuildContext context) {
    return Localizations.of<AppLocalization>(context, AppLocalization);
  }

  // ✅ Load for the current locale
  Future<void> load() async {
    bool success = await _loadFromApi();
    if (!success) {
      await _loadFromAsset(); // fallback to local JSON
    }
  }

  Future<bool> _loadFromApi() async {
    try {
      final response = await http.post(
        getTranslationsApi,
        body: {'language_code': locale.languageCode},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['error'] == false && jsonResponse['data'] != null) {
          final Map<String, dynamic> translations = jsonResponse['data'];
          _localizedValuesByLang[locale.languageCode] =
              translations.map((k, v) => MapEntry(k, v.toString()));
          print('[Translation API] ${locale.languageCode} loaded.');
          return true;
        }
      }
    } catch (e) {
      print('[Translation API Error] $e');
    }
    return false;
  }

  Future<void> _loadFromAsset() async {
    try {
      final String jsonString = await rootBundle
          .loadString('lib/Language/${locale.languageCode}.json');
      final Map<String, dynamic> mappedJson = json.decode(jsonString);
      _localizedValuesByLang[locale.languageCode] =
          mappedJson.map((k, v) => MapEntry(k, v.toString()));
      print('[Translation Local Fallback] ${locale.languageCode} loaded.');
    } catch (e) {
      print('[Local Fallback Error] $e');
    }
  }

  // ✅ Translation fetch based on locale
  String? translate(String key) {
    return _localizedValuesByLang[locale.languageCode]?[key] ?? key;
  }

  static const LocalizationsDelegate<AppLocalization> delegate =
      _AppLocalizationDelegate();
}

class _AppLocalizationDelegate extends LocalizationsDelegate<AppLocalization> {
  const _AppLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalization> load(Locale locale) async {
    final AppLocalization localization = AppLocalization(locale);
    await localization.load();
    return localization;
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalization> old) => false;
}
