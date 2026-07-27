import 'notification_type.dart';

class NotificationModel {
  final String id;
  final String uid;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  /// Jenis notifikasi (untuk ikon/warna/filter). Selalu terisi: kalau
  /// dokumen Firestore punya field `type` yang valid dipakai langsung,
  /// kalau tidak diturunkan otomatis dari judul & isi lewat
  /// [inferNotificationType] — lihat dokumentasi di notification_type.dart.
  final NotificationType type;

  const NotificationModel({
    required this.id,
    required this.uid,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    required this.type,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    final title = map['title'] as String? ?? '';
    final body = map['body'] as String? ?? '';
    final parsedType = NotificationTypeParse.tryParse(map['type'] as String?);

    return NotificationModel(
      id: id,
      uid: map['uid'] as String? ?? '',
      title: title,
      body: body,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      type: parsedType ?? inferNotificationType(title, body),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'title': title,
      'body': body,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'type': type.storageKey,
    };
  }
}
