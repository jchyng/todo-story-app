import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 완료/삭제/이동 후 3초 Undo 스낵바.
///
/// 사용법:
/// ```dart
/// UndoSnackbar.show(
///   context,
///   message: '할 일을 완료했습니다',
///   onUndo: () => repository.toggleComplete(task.id),
/// );
/// ```
abstract class UndoSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppTextStyles.body(color: Colors.white),
          ),
          duration: duration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.textPrimary,
          action: SnackBarAction(
            label: '실행 취소',
            textColor: AppColors.accent,
            onPressed: onUndo,
          ),
        ),
      );
  }
}
