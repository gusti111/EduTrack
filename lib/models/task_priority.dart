import 'package:flutter/material.dart';

enum TaskPriority { low, medium, high }

extension TaskPriorityX on TaskPriority {
  String get label => switch (this) {
        TaskPriority.low => 'Rendah',
        TaskPriority.medium => 'Sedang',
        TaskPriority.high => 'Tinggi',
      };

  Color get color => switch (this) {
        TaskPriority.low => Colors.green,
        TaskPriority.medium => Colors.orange,
        TaskPriority.high => Colors.red,
      };
}
