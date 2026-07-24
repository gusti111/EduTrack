import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Lapisan paling bawah untuk Firebase Storage — dipakai kalau nanti
/// butuh upload foto profil atau lampiran tugas. Belum ada pemanggil
/// aktif hari ini (edit_profile_screen belum punya picker foto), tapi
/// service ini sudah siap dipasang tanpa perlu ubah arsitektur.
class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Upload file lokal ke [path] (contoh: 'profile_photos/$uid.jpg')
  /// dan kembalikan download URL-nya.
  Future<String> uploadFile(String path, File file) async {
    final ref = _storage.ref(path);
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }

  Future<void> deleteFile(String path) {
    return _storage.ref(path).delete();
  }

  String profilePhotoPath(String uid) => 'profile_photos/$uid.jpg';
}
