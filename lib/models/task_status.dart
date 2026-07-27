import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';

enum TaskStatus { pending, inProgress, completed, overdue }

extension TaskStatusX on TaskStatus {
  String get label => switch (this) {
        TaskStatus.pending => 'Belum Selesai',
        TaskStatus.inProgress => 'Sedang Dikerjakan',
        TaskStatus.completed => 'Selesai',
        TaskStatus.overdue => 'Tertunda',
      };

  Color get color => switch (this) {
        TaskStatus.pending => AppColors.primary,
        TaskStatus.inProgress => AppColors.info,
        TaskStatus.completed => AppColors.success,
        TaskStatus.overdue => AppColors.warning,
      };
}
