import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/providers/repository_providers.dart';

/// 프로젝트 생성 다이얼로그.
///
/// 호출: CreateProjectDialog.show(context)
class CreateProjectDialog extends ConsumerStatefulWidget {
  const CreateProjectDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const CreateProjectDialog(),
    );
  }

  @override
  ConsumerState<CreateProjectDialog> createState() =>
      _CreateProjectDialogState();
}

class _CreateProjectDialogState extends ConsumerState<CreateProjectDialog> {
  final _ctrl = TextEditingController();
  Color _selectedColor = AppColors.projectBlue;
  bool _isLoading = false;

  static const _colorPresets = [
    AppColors.projectBlue,
    AppColors.projectPurple,
    AppColors.projectRed,
    AppColors.projectGreen,
    AppColors.projectOrange,
    AppColors.projectTeal,
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final r = (_selectedColor.r * 255).round();
      final g = (_selectedColor.g * 255).round();
      final b = (_selectedColor.b * 255).round();
      final hex =
          '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
      await ref.read(projectRepositoryProvider).createProject(
            name: name,
            color: hex.toUpperCase(),
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text('새 프로젝트', style: AppTextStyles.headline()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이름 입력
          TextField(
            controller: _ctrl,
            autofocus: true,
            style: AppTextStyles.body(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: '프로젝트 이름',
              hintStyle: AppTextStyles.body(color: AppColors.textMuted),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _create(),
          ),
          const SizedBox(height: 20),
          // 컬러 선택
          Text('색상', style: AppTextStyles.label(color: AppColors.textMuted)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: _colorPresets.map((color) {
              final selected = _selectedColor == color;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: AppColors.textPrimary, width: 2.5)
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 16)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('취소', style: AppTextStyles.body(color: AppColors.textMuted)),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _create,
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text('만들기', style: AppTextStyles.body(color: Colors.white)),
        ),
      ],
    );
  }
}
