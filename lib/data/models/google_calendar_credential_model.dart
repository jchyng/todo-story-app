import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore: users/{uid}/private/googleCalendar
///
/// Google Calendar OAuth 토큰을 서브컬렉션에 분리하는 이유:
/// Firestore는 필드 수준 보안 규칙을 지원하지 않는다.
/// users/{uid} document를 읽으면 모든 필드가 클라이언트에 노출되므로
/// refresh token처럼 민감한 정보는 별도 서브컬렉션에 저장하고
/// 해당 서브컬렉션에만 별도 Security Rule을 적용한다.
///
/// Security Rule: users/{uid}/private/{doc} — uid 본인만 read/write
/// (Cloud Functions도 Admin SDK로 직접 접근)
class GoogleCalendarCredential {
  /// Google OAuth access token (단기, 만료 있음)
  final String accessToken;

  /// Google OAuth refresh token (장기, 재발급용)
  final String refreshToken;

  final DateTime accessTokenExpiresAt;

  /// 연동된 Google 계정 이메일
  final String googleEmail;

  /// 마지막 동기화 성공 시각
  final DateTime? lastSyncedAt;

  /// 캘린더 동기화 에러 상태.
  /// null = 정상, "reauth_required" = 재인증 필요, "sync_failed" = 동기화 실패
  final String? errorStatus;

  const GoogleCalendarCredential({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
    required this.googleEmail,
    this.lastSyncedAt,
    this.errorStatus,
  });

  bool get isAccessTokenExpired =>
      DateTime.now().isAfter(accessTokenExpiresAt);

  factory GoogleCalendarCredential.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GoogleCalendarCredential(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      accessTokenExpiresAt:
          (data['accessTokenExpiresAt'] as Timestamp).toDate(),
      googleEmail: data['googleEmail'] as String,
      lastSyncedAt: (data['lastSyncedAt'] as Timestamp?)?.toDate(),
      errorStatus: data['errorStatus'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'accessTokenExpiresAt': Timestamp.fromDate(accessTokenExpiresAt),
      'googleEmail': googleEmail,
      'lastSyncedAt':
          lastSyncedAt != null ? Timestamp.fromDate(lastSyncedAt!) : null,
      'errorStatus': errorStatus,
    };
  }

  GoogleCalendarCredential copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? accessTokenExpiresAt,
    String? googleEmail,
    DateTime? lastSyncedAt,
    String? errorStatus,
    bool clearErrorStatus = false,
    bool clearLastSyncedAt = false,
  }) {
    return GoogleCalendarCredential(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      accessTokenExpiresAt: accessTokenExpiresAt ?? this.accessTokenExpiresAt,
      googleEmail: googleEmail ?? this.googleEmail,
      lastSyncedAt:
          clearLastSyncedAt ? null : (lastSyncedAt ?? this.lastSyncedAt),
      errorStatus:
          clearErrorStatus ? null : (errorStatus ?? this.errorStatus),
    );
  }
}
