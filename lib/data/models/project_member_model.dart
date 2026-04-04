import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectMember {
  final String userId;

  /// 'owner'|'editor'|'viewer'
  final String role;

  final String? displayName;
  final String? avatarUrl;
  final DateTime joinedAt;

  const ProjectMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.displayName,
    this.avatarUrl,
  });

  factory ProjectMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProjectMember(
      userId: doc.id,
      role: data['role'] as String,
      displayName: data['displayName'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'role': role,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }
}
