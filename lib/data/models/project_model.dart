import 'package:cloud_firestore/cloud_firestore.dart';

class Project {
  final String id;
  final String name;

  /// hex 코드 (예: "#FF5733")
  final String? color;

  final String ownerId;

  /// array-contains 쿼리용 멤버 uid 목록
  final List<String> memberIds;

  /// 드로어 정렬 (fractional indexing)
  final double order;

  final DateTime createdAt;
  final DateTime updatedAt;

  // 조회 시 추가 정보 (클라이언트 전용, Firestore에 저장 안 함)
  final String? currentUserRole;
  final int memberCount;

  const Project({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.memberIds,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
    this.color,
    this.currentUserRole,
    this.memberCount = 1,
  });

  factory Project.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Project(
      id: doc.id,
      name: data['name'] as String,
      color: data['color'] as String?,
      ownerId: data['ownerId'] as String,
      memberIds: (data['memberIds'] as List<dynamic>?)?.cast<String>() ?? [],
      order: (data['order'] as num?)?.toDouble() ?? 1000.0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      memberCount: data['memberCount'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'color': color,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'order': order,
      'memberCount': memberCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Project copyWith({
    String? name,
    String? color,
    List<String>? memberIds,
    double? order,
    DateTime? updatedAt,
    String? currentUserRole,
    int? memberCount,
    bool clearColor = false,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      color: clearColor ? null : (color ?? this.color),
      ownerId: ownerId,
      memberIds: memberIds ?? this.memberIds,
      order: order ?? this.order,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentUserRole: currentUserRole ?? this.currentUserRole,
      memberCount: memberCount ?? this.memberCount,
    );
  }
}
