import 'package:cloud_firestore/cloud_firestore.dart';

import 'task_priority.dart';
import 'task_status.dart';

class TaskModel {
  final String id;
  final String uid;
  final String title;
  final String? description;
  final DateTime dueDate;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime createdAt;

  const TaskModel({
    required this.id,
    required this.uid,
    required this.title,
    this.description,
    required this.dueDate,
    required this.priority,
    required this.status,
    required this.createdAt,
  });

  /// Status "nyata" yang seharusnya dipakai untuk ditampilkan di UI/statistik.
  ///
  /// [status] yang tersimpan di Firestore hanya pernah diisi manual sebagai
  /// pending/inProgress/completed — tidak ada tempat di aplikasi yang pernah
  /// menyimpan [TaskStatus.overdue] secara eksplisit. Getter ini menghitung
  /// overdue secara dinamis berdasarkan [dueDate], supaya semua layar
  /// (HomeScreen, TaskCard, StatisticsScreen) menampilkan angka "Terlambat"
  /// yang sama dan benar, tanpa perlu job/cron terpisah untuk mengubah
  /// status tersimpan.
  TaskStatus get effectiveStatus {
    if (status == TaskStatus.completed) return TaskStatus.completed;
    if (dueDate.isBefore(DateTime.now())) return TaskStatus.overdue;
    return status;
  }

  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    return TaskModel(
      id: id,
      uid: map['uid'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      dueDate: (map['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TaskStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'priority': priority.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  TaskModel copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskStatus? status,
  }) {
    return TaskModel(
      id: id,
      uid: uid,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
