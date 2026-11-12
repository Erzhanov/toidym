import 'package:shared_preferences/shared_preferences.dart';
import 'package:toidym/shared/models/enums.dart';

/// Неконфиденциальные настройки интерфейса на базе SharedPreferences.
///
/// JWT токены здесь НЕ хранятся — для них используется [SecureTokenStorage].
class AppPreferences {
  AppPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const _keyLanguage = 'toidym_language';
  static const _keyOnboardingDone = 'toidym_onboarding_done';
  static const _keyDistrict = 'toidym_district';
  static const _keyActiveMode = 'toidym_active_mode';
  static const _keyFavoriteAlerts = 'toidym_favorite_alerts';
  static const _keyDietaryPreferences = 'toidym_dietary_preferences';

  AppLanguage getLanguage() {
    return AppLanguage.fromCode(_prefs.getString(_keyLanguage));
  }

  Future<void> setLanguage(AppLanguage language) async {
    await _prefs.setString(_keyLanguage, language.code);
  }

  bool get isOnboardingCompleted =>
      _prefs.getBool(_keyOnboardingDone) ?? false;

  Future<void> setOnboardingCompleted(bool value) async {
    await _prefs.setBool(_keyOnboardingDone, value);
  }

  AstanaDistrict getSelectedDistrict() {
    return AstanaDistrict.fromCode(_prefs.getString(_keyDistrict));
  }

  Future<void> setSelectedDistrict(AstanaDistrict district) async {
    await _prefs.setString(_keyDistrict, district.code);
  }

  AppMode getActiveMode() {
    return AppMode.fromCode(_prefs.getString(_keyActiveMode));
  }

  Future<void> setActiveMode(AppMode mode) async {
    await _prefs.setString(_keyActiveMode, mode.code);
  }

  bool get favoriteAlertsEnabled =>
      _prefs.getBool(_keyFavoriteAlerts) ?? true;

  Future<void> setFavoriteAlertsEnabled(bool value) async {
    await _prefs.setBool(_keyFavoriteAlerts, value);
  }

  Set<DietaryPreference> getDietaryPreferences() {
    final raw = _prefs.getStringList(_keyDietaryPreferences) ?? const [];
    return {
      for (final code in raw)
        DietaryPreference.values.firstWhere(
          (e) => e.apiValue == code,
          orElse: () => DietaryPreference.halalOnly,
        ),
    };
  }

  Future<void> setDietaryPreferences(Set<DietaryPreference> prefs) async {
    await _prefs.setStringList(
      _keyDietaryPreferences,
      prefs.map((e) => e.apiValue).toList(growable: false),
    );
  }
}
