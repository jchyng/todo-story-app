import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/google_calendar_credential_model.dart';
import '../models/user_model.dart';
import '../models/user_settings_model.dart';

/// users/{uid} 문서 및 users/{uid}/private 서브컬렉션을 관리한다.
///
/// Google Calendar OAuth 토큰은 users/{uid}/private/googleCalendar 에 저장한다.
/// (Firestore 필드 수준 보안 규칙 미지원 → 서브컬렉션으로 분리)
class UserRepository {
  final FirebaseFirestore _db;
  final String uid;

  UserRepository({required this.uid, FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> get _googleCalendarDoc =>
      _userDoc.collection('private').doc('googleCalendar');

  // ---------------------------------------------------------------------------
  // 사용자 문서
  // ---------------------------------------------------------------------------

  /// users/{uid} 문서 실시간 스트림
  Stream<AppUser?> watchUser() {
    return _userDoc.snapshots().map((snap) {
      if (!snap.exists) return null;
      return AppUser.fromFirestore(snap);
    });
  }

  /// 로그인 시 사용자 문서가 없으면 초기 생성한다 (idempotent).
  Future<void> initializeUser(User firebaseUser) async {
    final snap = await _userDoc.get();
    if (snap.exists) return;

    await _userDoc.set({
      'email': firebaseUser.email ?? '',
      'displayName': firebaseUser.displayName,
      'avatarUrl': firebaseUser.photoURL,
      'fcmToken': null,
      'settings': UserSettings.defaults().toMap(),
      'onboarding': const UserOnboarding().toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 사용자 정보 부분 업데이트 (displayName, avatarUrl, fcmToken 등)
  Future<void> updateUser(Map<String, dynamic> fields) async {
    await _userDoc.update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 설정 업데이트
  Future<void> updateSettings(UserSettings settings) async {
    await _userDoc.update({
      'settings': settings.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // Google Calendar 자격증명 (private 서브컬렉션)
  // ---------------------------------------------------------------------------

  /// Google Calendar OAuth 토큰 읽기
  Future<GoogleCalendarCredential?> getCalendarCredential() async {
    final snap = await _googleCalendarDoc.get();
    if (!snap.exists) return null;
    return GoogleCalendarCredential.fromFirestore(snap);
  }

  /// Google Calendar OAuth 토큰 저장
  Future<void> saveCalendarCredential(GoogleCalendarCredential cred) async {
    await _googleCalendarDoc.set(cred.toFirestore());
  }

  /// Google Calendar 연동 해제
  Future<void> deleteCalendarCredential() async {
    await _googleCalendarDoc.delete();
  }
}
