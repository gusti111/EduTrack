import 'bootstrap.dart';

/// Semua inisialisasi berat (Flutter binding, dotenv, Firebase) sudah
/// ditangani di dalam `bootstrap()` — jangan panggil `Firebase.initializeApp()`
/// lagi di sini, karena app default Firebase hanya boleh diinisialisasi
/// SEKALI. Memanggilnya dua kali (di main.dart lalu diulang lagi di
/// bootstrap.dart) melempar FirebaseException '[core/duplicate-app]'
/// dan membuat aplikasi crash setiap kali dijalankan.
void main() async {
  await bootstrap();
}
