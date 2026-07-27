import 'task_priority.dart';
import 'task_status.dart';

class TaskModel {
  final String id;
  final String uid;
  final String title;
  final String subject;
  final String? description;
  final DateTime dueDate;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime createdAt;

  const TaskModel({
    required this.id,
    required this.uid,
    required this.title,
    required this.subject,
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
  /// (HomeScreen, TaskCard, StatisticsScreen) menampilkan angka "Tertunda"
  /// yang sama dan benar, tanpa perlu job/cron terpisah untuk mengubah
  /// status tersimpan.
  TaskStatus get effectiveStatus {
    if (status == TaskStatus.completed) return TaskStatus.completed;
    if (dueDate.isBefore(DateTime.now())) return TaskStatus.overdue;
    return status;
  }

  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    // dueDate adalah kewajiban mutlak (required) bagi integritas logika
    // aplikasi ini (effectiveStatus, sorting, statistik semuanya
    // bergantung padanya). Field yang kosong/tidak valid membuat parsing
    // gagal (FormatException) — pemanggil (TaskRepository.watchTasks)
    // menangkapnya per-dokumen dan melewati dokumen yang cacat, alih-alih
    // memanipulasi state dengan data salah.
    // CATATAN MIGRASI REST: FirestoreRestClient mengembalikan timestampValue
    // maupun stringValue sama-sama sebagai String biasa (bukan Timestamp
    // dari cloud_firestore lagi), jadi field tanggal di-parse lewat
    // DateTime.parse — konsisten dengan UserModel yang memang sudah
    // begini dari awal.
    final rawDueDate = map['dueDate'];
    final parsedDueDate =
        rawDueDate is String ? DateTime.tryParse(rawDueDate) : null;
    if (parsedDueDate == null) {
      throw FormatException(
        'TaskModel.fromMap: dueDate tidak valid/kosong pada dokumen $id',
      );
    }

    return TaskModel(
      id: id,
      uid: map['uid'] as String? ?? '',
      title: map['title'] as String? ?? '',
      // Default string kosong untuk dokumen lama (sebelum field `subject`
      // ditambahkan ke UI) — bukan FormatException, karena mata kuliah
      // bukan data yang mempengaruhi logika (beda dengan dueDate).
      subject: map['subject'] as String? ?? '',
      description: map['description'] as String?,
      dueDate: parsedDueDate,
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TaskStatus.pending,
      ),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'title': title,
      'subject': subject,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  TaskModel copyWith({
    String? title,
    String? subject,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskStatus? status,
  }) {
    return TaskModel(
      id: id,
      uid: uid,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
