/// Semua nama koleksi & field Firestore dipusatkan di sini.
/// Kalau ada typo nama koleksi, IDE langsung menandai saat compile —
/// bukan sunyi di runtime seperti kalau ditulis manual sebagai String.
class FirestorePaths {
  FirestorePaths._();

  static const String users = 'users';
  static const String tasks = 'tasks';
  static const String notifications = 'notifications';

  static String userDoc(String uid) => '$users/$uid';
  static String taskDoc(String taskId) => '$tasks/$taskId';

  // Nama field yang sering dipakai untuk query, biar konsisten juga.
  static const String fieldUid = 'uid';
  static const String fieldDueDate = 'dueDate';
  static const String fieldStatus = 'status';
}
