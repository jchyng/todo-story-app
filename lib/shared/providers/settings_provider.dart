import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/user_settings_model.dart';

// ---------------------------------------------------------------------------
// SharedPreferences 인젝션 (main.dart에서 override)
// ---------------------------------------------------------------------------

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main');
});

// ---------------------------------------------------------------------------
// Settings Notifier
// ---------------------------------------------------------------------------

class SettingsNotifier extends Notifier<UserSettings> {
  static const _kThemeMode = 'themeMode';
  static const _kStartOfWeek = 'startOfWeek';
  static const _kTimeFormat = 'timeFormat';
  static const _kSoundEnabled = 'soundEnabled';
  static const _kPushEnabled = 'pushEnabled';
  static const _kDailySummaryEnabled = 'dailySummaryEnabled';
  static const _kDailySummaryTime = 'dailySummaryTime';

  @override
  UserSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return UserSettings(
      themeMode: prefs.getString(_kThemeMode) ?? 'system',
      language: 'ko',
      startOfWeek: prefs.getString(_kStartOfWeek) ?? 'mon',
      timeFormat: prefs.getString(_kTimeFormat) ?? '24h',
      soundEnabled: prefs.getBool(_kSoundEnabled) ?? true,
      pushEnabled: prefs.getBool(_kPushEnabled) ?? true,
      dailySummaryEnabled: prefs.getBool(_kDailySummaryEnabled) ?? true,
      dailySummaryTime: prefs.getString(_kDailySummaryTime) ?? '08:00',
    );
  }

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_kThemeMode, mode);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setStartOfWeek(String value) async {
    await _prefs.setString(_kStartOfWeek, value);
    state = state.copyWith(startOfWeek: value);
  }

  Future<void> setTimeFormat(String value) async {
    await _prefs.setString(_kTimeFormat, value);
    state = state.copyWith(timeFormat: value);
  }

  Future<void> setSoundEnabled(bool value) async {
    await _prefs.setBool(_kSoundEnabled, value);
    state = state.copyWith(soundEnabled: value);
  }

  Future<void> setPushEnabled(bool value) async {
    await _prefs.setBool(_kPushEnabled, value);
    state = state.copyWith(pushEnabled: value);
  }

  Future<void> setDailySummaryEnabled(bool value) async {
    await _prefs.setBool(_kDailySummaryEnabled, value);
    state = state.copyWith(dailySummaryEnabled: value);
  }

  Future<void> setDailySummaryTime(String time) async {
    await _prefs.setString(_kDailySummaryTime, time);
    state = state.copyWith(dailySummaryTime: time);
  }

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);
}

final settingsProvider = NotifierProvider<SettingsNotifier, UserSettings>(
  SettingsNotifier.new,
);

// ---------------------------------------------------------------------------
// 유틸
// ---------------------------------------------------------------------------

ThemeMode themeModeFromString(String mode) {
  switch (mode) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}
