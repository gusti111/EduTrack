# EduTrack — Smart Student Planner

Implementasi Flutter untuk EduTrack sesuai `EduTrack_Arsitektur_Revisi.md`,
dengan arsitektur **UI → Provider → Repository → Service → Firebase**.

## Status Fitur

Semua 15 halaman di peta desain Figma sudah punya implementasi:

| Halaman | Status |
|---|---|
| Splash (AuthGate) | ✅ |
| Login / Register / Forgot Password | ✅ Firebase Auth |
| Home Dashboard | ✅ ringkasan total/selesai/terlambat + tugas mendatang |
| Task List / Detail / Add-Edit | ✅ CRUD penuh, realtime via Firestore stream |
| Calendar | ✅ grid bulanan interaktif (`table_calendar`), tap tanggal untuk lihat tugas |
| Statistics | ✅ breakdown status & prioritas (progress bar) |
| Notification Center | ✅ in-app (Firestore) + push notification (FCM) |
| Profile / Edit Profile | ✅ |
| Settings | ✅ dark mode (persist via `SharedPreferences`); toggle notifikasi masih state lokal |
| About | ✅ |

## Arsitektur

```
UI (Screens)
   → Provider           # state: loading / data / Failure — tidak tahu Firestore
      → Repository      # translate Model ↔ Map, exception ↔ Failure
         → Service       # panggilan mentah ke Firebase
            → Firebase / Firestore
```

Struktur folder:

```
lib/
├── main.dart / bootstrap.dart / firebase_options.dart
├── app/                  # theme, routes, konstanta (nama koleksi Firestore, dsb)
├── core/
│   ├── errors/           # Failure (sealed class) + mapper exception → Failure
│   ├── services/         # AuthService, FirestoreService, NotificationService,
│   │                      # PushNotificationService (FCM), StorageService
│   ├── extensions/, utils/, widgets/
├── models/               # UserModel, TaskModel (+ enum TaskPriority/TaskStatus), NotificationModel
├── repositories/         # AuthRepository, TaskRepository, NotificationRepository
├── providers/            # AuthProvider, TaskProvider, NotificationProvider,
│                          # ThemeProvider, ConnectivityProvider
└── screens/              # 15 halaman, dikelompokkan per fitur
```

## Menjalankan Proyek

1. `flutter pub get`
2. Salin `assets/env.example` → `assets/env.txt` (config sensitif non-Firebase;
   `firebase_options.dart` sendiri aman untuk di-commit, isinya bukan rahasia).
3. Aktifkan **Email/Password sign-in** di Firebase Console → Authentication →
   Sign-in method — tanpa ini, login/register gagal dengan error dari Firebase.
4. `flutter run`

> Catatan verifikasi: perbaikan di source ini dikerjakan lewat code review
> manual (tidak ada akses Flutter/Dart SDK atau `pub.dev` di environment
> yang dipakai untuk mengedit). Jalankan `flutter analyze` dan `flutter test`
> di mesin lokal sebagai langkah verifikasi akhir sebelum build/release.

## Kenapa arsitektur ini "aman" untuk skala portofolio/UAS

- Enum `TaskPriority`/`TaskStatus` bikin compiler menegur kalau ada state yang
  lupa di-handle di UI (mis. lupa kasih warna untuk `overdue`).
- `TaskModel.effectiveStatus` jadi satu sumber kebenaran untuk deteksi
  "terlambat" — dipakai konsisten di Home, TaskCard, dan Statistics, supaya
  angkanya tidak pernah berbeda antar layar.
- `Failure` terpusat → semua layar bisa pakai `ErrorState` yang sama, tidak
  ada lagi `try/catch` yang isinya cuma `print(e)`.
- Kalau nanti mau migrasi ke Riverpod atau ganti backend, cukup
  `Provider`/`RepositoryImpl` yang disentuh — model, UI, dan Service
  tidak perlu diubah.

## Pengembangan Selanjutnya

Lihat `EduTrack_Arsitektur_Revisi.md` untuk roadmap v2.0–v4.0 (sinkronisasi
Google Calendar, lampiran file tugas, gamifikasi, kolaborasi tugas kelompok,
rekomendasi prioritas berbasis AI).

Item yang belum diimplementasi dan masih terbuka:
- Toggle "Notifikasi" di Settings masih di state lokal, belum dipersist
  (pola yang sama seperti `ThemeProvider` bisa dipakai ulang).
- Belum ada unit test untuk `models/` (test untuk `repositories/` sudah ada
  di `test/repositories/`).

Lihat `BUGFIX_NOTES.md` untuk riwayat lengkap bug yang ditemukan & diperbaiki.
