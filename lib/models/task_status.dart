import 'package:flutter/material.dart';

enum TaskStatus { pending, inProgress, completed, overdue }

extension TaskStatusX on TaskStatus {
  String get label => switch (this) {
        TaskStatus.pending => 'Pending',
        TaskStatus.inProgress => 'Sedang Dikerjakan',
        TaskStatus.completed => 'Selesai',
        TaskStatus.overdue => 'Terlambat',
      };

  Color get color => switch (this) {
        TaskStatus.pending => Colors.blueGrey,
        TaskStatus.inProgress => Colors.blue,
        TaskStatus.completed => Colors.green,
        TaskStatus.overdue => Colors.red,
      };
}
