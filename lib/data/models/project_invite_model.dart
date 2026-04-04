import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectInvite {
  final String id;
  final String token;

  /// 'editor'|'viewer'
  final String role;

  final String projectId;
  final String createdBy;
  final DateTime expiresAt;
  final int useCount;
  final DateTime createdAt;

  const ProjectInvite({
    required this.id,
    required this.token,
    required this.role,
    required this.projectId,
    required this.createdBy,
    required this.expiresAt,
    required this.useCount,
    required this.createdAt,
  });

  factory ProjectInvite.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProjectInvite(
      id: doc.id,
      token: data['token'] as String,
      role: data['role'] as String,
      projectId: data['projectId'] as String,
      createdBy: data['createdBy'] as String,
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      useCount: data['useCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'token': token,
      'role': role,
      'projectId': projectId,
      'createdBy': createdBy,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'useCount': useCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
