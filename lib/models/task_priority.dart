import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';

enum TaskPriority { low, medium, high }

extension TaskPriorityX on TaskPriority {
  String get label => switch (this) {
        TaskPriority.low => 'Rendah',
        TaskPriority.medium => 'Sedang',
        TaskPriority.high => 'Tinggi',
      };

  Color get color => switch (this) {
        TaskPriority.low => AppColors.success,
        TaskPriority.medium => AppColors.warning,
        TaskPriority.high => AppColors.danger,
      };
}
