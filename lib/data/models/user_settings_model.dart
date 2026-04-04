class UserSettings {
  /// 'system'|'light'|'dark'
  final String themeMode;

  /// 'en'|'ko'
  final String language;

  /// 'sun'|'mon'
  final String startOfWeek;

  /// '12h'|'24h'
  final String timeFormat;

  final bool soundEnabled;
  final bool pushEnabled;
  final bool dailySummaryEnabled;

  /// "HH:mm" (예: "08:00")
  final String dailySummaryTime;

  const UserSettings({
    required this.themeMode,
    required this.language,
    required this.startOfWeek,
    required this.timeFormat,
    required this.soundEnabled,
    required this.pushEnabled,
    required this.dailySummaryEnabled,
    required this.dailySummaryTime,
  });

  factory UserSettings.defaults() => const UserSettings(
        themeMode: 'system',
        language: 'ko',
        startOfWeek: 'mon',
        timeFormat: '24h',
        soundEnabled: true,
        pushEnabled: true,
        dailySummaryEnabled: true,
        dailySummaryTime: '08:00',
      );

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      themeMode: map['themeMode'] as String? ?? 'system',
      language: map['language'] as String? ?? 'ko',
      startOfWeek: map['startOfWeek'] as String? ?? 'mon',
      timeFormat: map['timeFormat'] as String? ?? '24h',
      soundEnabled: map['soundEnabled'] as bool? ?? true,
      pushEnabled: map['pushEnabled'] as bool? ?? true,
      dailySummaryEnabled: map['dailySummaryEnabled'] as bool? ?? true,
      dailySummaryTime: map['dailySummaryTime'] as String? ?? '08:00',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode,
      'language': language,
      'startOfWeek': startOfWeek,
      'timeFormat': timeFormat,
      'soundEnabled': soundEnabled,
      'pushEnabled': pushEnabled,
      'dailySummaryEnabled': dailySummaryEnabled,
      'dailySummaryTime': dailySummaryTime,
    };
  }

  UserSettings copyWith({
    String? themeMode,
    String? language,
    String? startOfWeek,
    String? timeFormat,
    bool? soundEnabled,
    bool? pushEnabled,
    bool? dailySummaryEnabled,
    String? dailySummaryTime,
  }) {
    return UserSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      startOfWeek: startOfWeek ?? this.startOfWeek,
      timeFormat: timeFormat ?? this.timeFormat,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      dailySummaryEnabled: dailySummaryEnabled ?? this.dailySummaryEnabled,
      dailySummaryTime: dailySummaryTime ?? this.dailySummaryTime,
    );
  }
}
