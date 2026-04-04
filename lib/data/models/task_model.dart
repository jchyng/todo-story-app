import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final bool completed;
  final String? notes;

  /// "YYYY-MM-DD"
  final String? dueDate;

  /// "HH:mm" (24h)
  final String? startTime;

  /// null = Inbox
  final String? projectId;

  final List<Subtask> subtasks;

  /// true이면 Today 뷰에 표시
  final bool isFocused;

  /// 'daily'|'weekdays'|'weekends'|'weekly'|'monthly'|'yearly'|'custom'
  final String? repeat;

  final RepeatConfig? repeatConfig;

  /// Inbox/Project DnD 정렬 (fractional indexing)
  final double order;

  /// Today 뷰 전용 DnD 정렬 (fractional indexing).
  ///
  /// isFocused가 true로 바뀌는 시점에 현재 [order] 값으로 초기화된다.
  /// Today DnD는 이 필드만 수정하며, Inbox/Project DnD는 [order]만 수정한다.
  /// Fractional indexing 리밸런싱 로직은 두 필드 모두 커버해야 한다.
  final double? focusOrder;

  /// true = Google Tasks 임포트 진행 중인 태스크.
  ///
  /// Cloud Function `onTaskWrite`는 이 값이 true이면 캘린더 동기화를 건너뛴다.
  /// 임포트 완료 후 ImportService가 dueDate가 있는 태스크에 대해 일괄 캘린더 동기화를 트리거한다.
  final bool? importBatch;

  /// 반복 태스크 완료 시 생성되는 UUID (idempotency key).
  ///
  /// Cloud Function은 parentNonce == 이 값인 sibling 태스크가 이미 존재하면
  /// 다음 occurrence 생성을 건너뛴다. 오프라인 중복 완료 방지용.
  final String? completionNonce;

  /// Cloud Function이 관리하는 캘린더 동기화 상태.
  ///
  /// "ok" = 동기화 성공, "failed" = 3회 재시도 후 실패.
  /// calendarSyncStatusProvider가 이 필드를 감시하여 Settings 화면에 재시도 배너를 표시한다.
  final String? calendarSyncStatus;

  /// Google Calendar에 생성된 이벤트 ID (캘린더 연동 시 설정)
  final String? calendarEventId;

  final DateTime? completedAt;

  /// null = 활성, non-null = Trash
  final DateTime? deletedAt;

  /// 마감 N분 전 알림
  final int? reminderOffset;

  final DateTime? reminderSentAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  // 협업 전용 (프로젝트 태스크일 때만 사용)
  final String? createdBy;
  final String? lastEditorId;
  final String? lastEditorName;
  final String? lastEditorAvatarUrl;

  const Task({
    required this.id,
    required this.title,
    required this.completed,
    required this.isFocused,
    required this.order,
    required this.subtasks,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.dueDate,
    this.startTime,
    this.projectId,
    this.repeat,
    this.repeatConfig,
    this.focusOrder,
    this.importBatch,
    this.completionNonce,
    this.calendarSyncStatus,
    this.calendarEventId,
    this.completedAt,
    this.deletedAt,
    this.reminderOffset,
    this.reminderSentAt,
    this.createdBy,
    this.lastEditorId,
    this.lastEditorName,
    this.lastEditorAvatarUrl,
  });

  bool get isDeleted => deletedAt != null;

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] as String,
      completed: data['completed'] as bool? ?? false,
      notes: data['notes'] as String?,
      dueDate: data['dueDate'] as String?,
      startTime: data['startTime'] as String?,
      projectId: data['projectId'] as String?,
      subtasks: (data['subtasks'] as List<dynamic>?)
              ?.map((e) => Subtask.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      isFocused: data['isFocused'] as bool? ?? false,
      repeat: data['repeat'] as String?,
      repeatConfig: data['repeatConfig'] != null
          ? RepeatConfig.fromMap(data['repeatConfig'] as Map<String, dynamic>)
          : null,
      order: (data['order'] as num?)?.toDouble() ?? 1000.0,
      focusOrder: (data['focusOrder'] as num?)?.toDouble(),
      importBatch: data['importBatch'] as bool?,
      completionNonce: data['completionNonce'] as String?,
      calendarSyncStatus: data['calendarSyncStatus'] as String?,
      calendarEventId: data['calendarEventId'] as String?,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
      reminderOffset: data['reminderOffset'] as int?,
      reminderSentAt: (data['reminderSentAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] as String?,
      lastEditorId: data['lastEditorId'] as String?,
      lastEditorName: data['lastEditorName'] as String?,
      lastEditorAvatarUrl: data['lastEditorAvatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'completed': completed,
      'notes': notes,
      'dueDate': dueDate,
      'startTime': startTime,
      'projectId': projectId,
      'subtasks': subtasks.map((s) => s.toMap()).toList(),
      'isFocused': isFocused,
      'repeat': repeat,
      'repeatConfig': repeatConfig?.toMap(),
      'order': order,
      'focusOrder': focusOrder,
      'importBatch': importBatch,
      'completionNonce': completionNonce,
      'calendarSyncStatus': calendarSyncStatus,
      'calendarEventId': calendarEventId,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'reminderOffset': reminderOffset,
      'reminderSentAt': reminderSentAt != null ? Timestamp.fromDate(reminderSentAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'lastEditorId': lastEditorId,
      'lastEditorName': lastEditorName,
      'lastEditorAvatarUrl': lastEditorAvatarUrl,
    };
  }

  Task copyWith({
    String? title,
    bool? completed,
    String? notes,
    String? dueDate,
    String? startTime,
    String? projectId,
    List<Subtask>? subtasks,
    bool? isFocused,
    String? repeat,
    RepeatConfig? repeatConfig,
    double? order,
    double? focusOrder,
    bool? importBatch,
    String? completionNonce,
    String? calendarSyncStatus,
    String? calendarEventId,
    DateTime? completedAt,
    DateTime? deletedAt,
    int? reminderOffset,
    DateTime? reminderSentAt,
    DateTime? updatedAt,
    String? createdBy,
    String? lastEditorId,
    String? lastEditorName,
    String? lastEditorAvatarUrl,
    // null로 명시 초기화가 필요한 필드
    bool clearNotes = false,
    bool clearDueDate = false,
    bool clearStartTime = false,
    bool clearProjectId = false,
    bool clearRepeat = false,
    bool clearRepeatConfig = false,
    bool clearFocusOrder = false,
    bool clearImportBatch = false,
    bool clearCompletionNonce = false,
    bool clearCalendarSyncStatus = false,
    bool clearCalendarEventId = false,
    bool clearCompletedAt = false,
    bool clearDeletedAt = false,
    bool clearReminderOffset = false,
    bool clearReminderSentAt = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      notes: clearNotes ? null : (notes ?? this.notes),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      startTime: clearStartTime ? null : (startTime ?? this.startTime),
      projectId: clearProjectId ? null : (projectId ?? this.projectId),
      subtasks: subtasks ?? this.subtasks,
      isFocused: isFocused ?? this.isFocused,
      repeat: clearRepeat ? null : (repeat ?? this.repeat),
      repeatConfig: clearRepeatConfig ? null : (repeatConfig ?? this.repeatConfig),
      order: order ?? this.order,
      focusOrder: clearFocusOrder ? null : (focusOrder ?? this.focusOrder),
      importBatch: clearImportBatch ? null : (importBatch ?? this.importBatch),
      completionNonce: clearCompletionNonce ? null : (completionNonce ?? this.completionNonce),
      calendarSyncStatus: clearCalendarSyncStatus ? null : (calendarSyncStatus ?? this.calendarSyncStatus),
      calendarEventId: clearCalendarEventId ? null : (calendarEventId ?? this.calendarEventId),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      reminderOffset: clearReminderOffset ? null : (reminderOffset ?? this.reminderOffset),
      reminderSentAt: clearReminderSentAt ? null : (reminderSentAt ?? this.reminderSentAt),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      lastEditorId: lastEditorId ?? this.lastEditorId,
      lastEditorName: lastEditorName ?? this.lastEditorName,
      lastEditorAvatarUrl: lastEditorAvatarUrl ?? this.lastEditorAvatarUrl,
    );
  }
}

class Subtask {
  final String id;
  final String title;
  final bool completed;

  const Subtask({
    required this.id,
    required this.title,
    required this.completed,
  });

  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      id: map['id'] as String,
      title: map['title'] as String,
      completed: map['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
    };
  }
}

class RepeatConfig {
  /// 반복 주기 숫자 (예: 2 = 2주마다)
  final int frequency;

  /// 'day'|'week'|'month'|'year'
  final String unit;

  /// 0(일)~6(토), 주간 반복 시 선택된 요일
  final List<int>? weekDays;

  const RepeatConfig({
    required this.frequency,
    required this.unit,
    this.weekDays,
  });

  factory RepeatConfig.fromMap(Map<String, dynamic> map) {
    return RepeatConfig(
      frequency: map['frequency'] as int,
      unit: map['unit'] as String,
      weekDays: (map['weekDays'] as List<dynamic>?)?.cast<int>(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'frequency': frequency,
      'unit': unit,
      'weekDays': weekDays,
    };
  }
}
