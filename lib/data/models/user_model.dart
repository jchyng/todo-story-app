import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_settings_model.dart';

/// Firestore: users/{uid}
///
/// 주의: googleCalendarToken은 이 문서에 저장하지 않는다.
/// Firestore는 필드 수준 보안 규칙이 없으므로, user document를 읽으면
/// 모든 필드가 클라이언트에 노출된다.
/// Google Calendar OAuth 토큰은 users/{uid}/private/googleCalendar 서브컬렉션에 저장한다.
class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? avatarUrl;

  /// FCM 푸시 알림 토큰
  final String? fcmToken;

  final UserSettings settings;
  final UserOnboarding onboarding;

  final DateTime createdAt;
  final DateTime updatedAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.settings,
    required this.onboarding,
    required this.createdAt,
    required this.updatedAt,
    this.displayName,
    this.avatarUrl,
    this.fcmToken,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] as String,
      displayName: data['displayName'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      fcmToken: data['fcmToken'] as String?,
      settings: data['settings'] != null
          ? UserSettings.fromMap(data['settings'] as Map<String, dynamic>)
          : UserSettings.defaults(),
      onboarding: data['onboarding'] != null
          ? UserOnboarding.fromMap(data['onboarding'] as Map<String, dynamic>)
          : const UserOnboarding(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'fcmToken': fcmToken,
      'settings': settings.toMap(),
      'onboarding': onboarding.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  AppUser copyWith({
    String? displayName,
    String? avatarUrl,
    String? fcmToken,
    UserSettings? settings,
    UserOnboarding? onboarding,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      settings: settings ?? this.settings,
      onboarding: onboarding ?? this.onboarding,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class UserOnboarding {
  final bool nameEntered;
  final bool googleTasksImportSeen;
  final bool calendarSyncSeen;

  const UserOnboarding({
    this.nameEntered = false,
    this.googleTasksImportSeen = false,
    this.calendarSyncSeen = false,
  });

  factory UserOnboarding.fromMap(Map<String, dynamic> map) {
    return UserOnboarding(
      nameEntered: map['nameEntered'] as bool? ?? false,
      googleTasksImportSeen: map['googleTasksImportSeen'] as bool? ?? false,
      calendarSyncSeen: map['calendarSyncSeen'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nameEntered': nameEntered,
      'googleTasksImportSeen': googleTasksImportSeen,
      'calendarSyncSeen': calendarSyncSeen,
    };
  }

  UserOnboarding copyWith({
    bool? nameEntered,
    bool? googleTasksImportSeen,
    bool? calendarSyncSeen,
  }) {
    return UserOnboarding(
      nameEntered: nameEntered ?? this.nameEntered,
      googleTasksImportSeen: googleTasksImportSeen ?? this.googleTasksImportSeen,
      calendarSyncSeen: calendarSyncSeen ?? this.calendarSyncSeen,
    );
  }
}
