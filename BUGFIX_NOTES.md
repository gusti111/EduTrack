# Catatan Perbaikan Bug — EduTrack

## 🆕 RONDE AUDIT ARSITEKTUR (stale data, corrupt data, offline-first)

### 14. Status "Terlambat" tidak reaktif terhadap waktu (`lib/providers/task_provider.dart`)
**Akar masalah:** `TaskModel.effectiveStatus` menghitung overdue secara
sinkron dari `DateTime.now()`. Firestore hanya mengirim snapshot baru kalau
ada perubahan DATA di server — bukan karena waktu berjalan melewati
`dueDate`. User yang membiarkan app terbuka (idle) melihat status/statistik
basi sampai ada trigger lain yang kebetulan memicu rebuild.
**Perbaikan:** `TaskProvider.listenToTasks()` sekarang juga menyalakan
`Timer.periodic(Duration(minutes: 1))` yang memanggil `notifyListeners()`
tanpa mengubah `_tasks`/`_isLoading`/`_failure` — cukup memaksa UI membaca
ulang `effectiveStatus` pada waktu saat itu. Timer dibatalkan di `dispose()`.

### 15. Satu dokumen cacat merusak seluruh stream tugas (`lib/repositories/task_repository.dart`, `lib/models/task_model.dart`)
**Akar masalah:** `watchTasks` mengonversi seluruh `snapshot.docs` lewat
satu `.map()`. Kalau satu dokumen punya field yang tidak valid (mis.
`dueDate` kosong/rusak akibat intervensi manual di Firebase Console),
`TaskModel.fromMap` melempar exception yang merusak seluruh stream —
layar user gagal total walau 99 dokumen lain valid.
**Perbaikan:** iterasi diubah jadi loop `for` dengan try-catch per
dokumen; dokumen yang gagal di-parse dicatat lewat `debugPrint` lalu
dilewati, sisanya tetap tampil. Sebagai bagian dari perbaikan ini,
`TaskModel.fromMap` juga tidak lagi diam-diam mengganti `dueDate` yang
kosong/tidak valid menjadi `DateTime.now()` (yang membuat tugas baru
tampak "mendesak" tanpa alasan yang terlihat) — sekarang melempar
`FormatException` supaya dokumen tersebut ditangkap dan dilewati oleh
perbaikan di atas, bukan diam-diam memakai data yang salah.

### 16. Timeout tulis diperlakukan sebagai kegagalan mutlak, padahal Firestore offline-first (`lib/core/errors/*.dart`, `lib/repositories/*.dart`, `lib/providers/task_provider.dart`)
**Akar masalah:** `mapExceptionToFailure` memetakan setiap
`TimeoutException` (baca maupun tulis) ke `NetworkFailure` dengan pesan
"Permintaan butuh waktu terlalu lama...". Untuk operasi TULIS
(add/update/delete task, buat/update dokumen profil), ini menyesatkan:
SDK Firestore offline-first sudah menulis data ke local cache duluan,
jadi timeout di sana tidak berarti data hilang — hanya belum tersinkron
ke server.
**Perbaikan:** `mapExceptionToFailure(error, {isWrite})` sekarang
menerima parameter `isWrite`; kalau `true` dan errornya
`TimeoutException`, dipetakan ke tipe baru `PendingSyncFailure` (pesan:
"Disimpan lokal, menunggu koneksi jaringan.") alih-alih `NetworkFailure`.
Semua pemanggilan tulis di `TaskRepositoryImpl` dan `AuthRepositoryImpl`
diberi `isWrite: true`. `TaskProvider._mutate` dan `EditProfileScreen`
memperlakukan `PendingSyncFailure` sebagai sukses-dengan-peringatan
(form tetap ditutup, tapi menampilkan snackbar info) alih-alih error
yang memblokir.

### 17. Kegagalan pembuatan dokumen profil membatalkan seluruh proses register (`lib/repositories/auth_repository.dart`)
**Akar masalah:** `register()` membungkus pembuatan akun Auth DAN
pembuatan dokumen profil Firestore dalam satu try-catch. Kalau
`createUserDoc` gagal (mis. timeout), exception dilempar ke UI sebagai
kegagalan register — padahal akun Firebase Auth-nya sendiri sudah
berhasil dibuat, membuat user bingung ("register gagal" tapi kalau
dicoba lagi malah "email sudah terdaftar").
**Perbaikan:** try-catch dipisah dua: kegagalan `register()` (akun Auth)
tetap melempar `Failure` ke UI; kegagalan `createUserDoc` (dokumen
profil) hanya dicatat lewat `debugPrint` dan tidak membatalkan alur —
user tetap bisa login, `ProfileScreen` sudah punya fallback nama default
untuk kasus ini. Ditambahkan juga `credential.user?.getIdToken(true)`
sebelum menulis dokumen profil untuk memaksa refresh token auth,
menghindari race condition di mana Security Rules yang bergantung pada
`request.auth.uid` sempat menolak penulisan karena token lama/belum ada.

---

### 7. Android memakai config Firebase milik iOS (`lib/firebase_options.dart`)
**Sebelum:**
```dart
switch (defaultTargetPlatform) {
  case TargetPlatform.android:
  case TargetPlatform.iOS:
    return ios;
  default:
    return android;
}
```
**Akibat:** ini bug PALING KRITIS di ronde ini. `TargetPlatform.android` ikut
jatuh ke `return ios`, jadi setiap kali aplikasi berjalan di HP Android —
target utama aplikasi ini — Firebase diinisialisasi memakai App ID/API key
milik iOS, yang tidak terdaftar untuk package Android manapun di Firebase
Console. Ini berpotensi membuat Auth/Firestore menolak permintaan karena
app tidak dikenali, atau perilaku tidak terduga lainnya. Sebagai bonus bug,
platform selain Android/iOS (macOS/Windows/Linux) malah diam-diam memakai
config Android alih-alih melempar error yang jelas.
**Perbaikan:** `android` dan `iOS` masing-masing mengembalikan config-nya
sendiri; platform lain sekarang melempar `UnsupportedError` yang jelas
(pola standar hasil `flutterfire configure`), bukan diam-diam salah pakai.

### 8. `setState()` dipanggil di tengah `build()` (`lib/screens/profile/profile_screen.dart`)
**Sebelum:** `_loadProfile(uid)` — yang isinya memanggil `setState()` — dipanggil
langsung di dalam `build()` setiap kali `_profileFuture == null || _loadedForUid != uid`.
**Akibat:** melempar assertion Flutter *"setState() or markNeedsBuild() called
during build"* setiap kali halaman Profil pertama kali dibuka.
**Perbaikan:** pemuatan awal dipindah ke `initState()` lewat method baru
`_loadProfileSilently()` yang mengisi field secara langsung TANPA `setState`
(aman di `initState`, karena widget belum selesai di-build). Kasus langka
uid berganti di tengah jalan dijadwalkan lewat `addPostFrameCallback`,
bukan `setState` langsung di `build()`.

### 9. Subscription task dibuat dua kali setiap HomeShell mount (`lib/screens/tasks/task_list_screen.dart`)
**Sebelum:** `TaskListScreen.initState()` memanggil `listenToTasks()` sendiri,
padahal `home_shell.dart` (komentarnya sendiri menyebut diri "satu-satunya
tempat" yang melakukan ini) sudah memanggilnya sekali untuk semua tab —
dan `TaskListScreen` adalah salah satu halaman di dalam `IndexedStack` milik
`HomeShell`, yang berarti `initState`-nya jalan bersamaan.
**Akibat:** subscription Firestore dibatalkan lalu dibuat ulang dua kali
setiap kali `HomeShell` mount — flicker loading yang tidak perlu, dan
kontradiksi langsung dengan komentar arsitektur di `home_shell.dart`.
**Perbaikan:** panggilan `listenToTasks()` di `initState` milik
`TaskListScreen` dihapus; `onRetry` tetap memanggilnya (itu legitimate,
dipicu oleh interaksi user).

### 10. Angka "Terlambat" tidak konsisten antar layar
**Sebelum:** `TaskStatus.overdue` tidak pernah benar-benar disimpan ke
Firestore — task hanya pernah diberi status `pending`/`inProgress`/`completed`
secara manual. `StatisticsScreen` menghitung breakdown lewat
`provider.tasksByStatus(status)` yang membandingkan `status` MENTAH, jadi
baris "Terlambat" SELALU menampilkan 0. Sementara itu, `HomeScreen` di
layar lain menghitung overdue secara terpisah dan dinamis
(`status != completed && dueDate sudah lewat`) — dua cara berbeda, dua
angka yang bisa berbeda pula.
**Perbaikan:** menambahkan `TaskModel.effectiveStatus` sebagai satu sumber
kebenaran (status tersimpan, kecuali sudah lewat tenggat dan belum selesai
→ dianggap `overdue`). `TaskProvider.tasksByStatus()`, `HomeScreen`, dan
`TaskCard` sekarang semuanya memakai `effectiveStatus` yang sama —
`StatisticsScreen` otomatis ikut benar karena memakai `tasksByStatus()`.

### 11. SDK constraint tidak realistis (`pubspec.yaml`)
**Sebelum:** `sdk: '>=3.3.0 <4.0.0'`, padahal seluruh kode memakai
`Color.withValues(alpha: ...)` — API pengganti `withOpacity` yang baru ada
di Flutter/Dart yang jauh lebih baru dari SDK 3.3.
**Akibat:** proyek ini secara teknis mengklaim kompatibel dengan SDK yang
sebenarnya tidak bisa meng-compile kodenya sendiri.
**Perbaikan:** dinaikkan ke `>=3.6.0 <4.0.0`.

### 12. Pembersihan file basi/duplikat
- `.env.example` di root dihapus — menyebut mekanisme `.env` di root yang
  sudah tidak dipakai sejak dipindah ke `assets/env.txt` (lihat
  `assets/env.example` untuk versi yang akurat).
- `assets/env` (file kosong 0-byte, nyasar dari eksperimen penamaan
  sebelumnya) dihapus — tidak direferensikan di manapun.
- `edu_track.iml` (duplikat `edutrack.iml`, sisa rename project) dihapus.
- CRLF → LF dinormalkan di `test/widget_test.dart`,
  `web/firebase-messaging-sw.js`, `web/index.html`, `edutrack.iml` — file-file
  ini terlewat saat normalisasi CRLF di ronde sebelumnya.
- `.gitignore` dilengkapi (`.idea/`, `*.iml`, kredensial native seperti
  `google-services.json`/`GoogleService-Info.plist`).
- `README.md` ditulis ulang — versi lama menyebut beberapa fitur (push
  notification, dark mode persist, kalender grid interaktif) sebagai
  "belum dikerjakan", padahal semuanya sudah ada di kode sejak beberapa
  ronde perbaikan sebelumnya.

### 13. Folder sampah brace-expansion ternyata belum benar-benar terhapus
Catatan di bagian "Pembersihan" (di bawah, dari ronde sebelumnya) mengklaim
folder `lib/screens/{home,statistics,profile,calendar}` dan
`lib/screens/{notification,settings,about}` sudah dihapus — ternyata saat
`.zip` dibongkar ulang, kedua folder itu masih ada (kosong, tidak ada file
di dalamnya, jadi tidak menyebabkan error kompilasi, tapi tetap sampah).
**Perbaikan:** benar-benar dihapus di ronde ini, diverifikasi kosong
sebelum dihapus dan diverifikasi tidak muncul lagi di `.zip` hasil akhir.

---

## 🆕 HOTFIX (setelah laporan pengguna: tombol "Simpan" macet loading di Web)

### 6. Firestore persistence bikin operasi tulis macet selamanya di Flutter Web
**Gejala yang dilaporkan:** di layar Edit Profil (dan berpotensi di semua
layar dengan tombol simpan/tambah/hapus tugas), tombol menampilkan
spinner loading yang **tidak pernah selesai** — tanpa pesan error apapun
di console.

**Akar masalah:** ini regresi dari perbaikan #3 (persistence offline) di
bagian sebelumnya. Ternyata `Settings(persistenceEnabled: true)` punya
masalah yang sudah dilaporkan resmi ke tim Firebase **khusus di Flutter
Web**:
- Harus jadi panggilan Firestore yang PERTAMA setelah app start.
- Bentrok dengan hot reload/hot restart saat development (`flutter run -d
  chrome`), memicu error "Firestore has already been started and
  persistence can no longer be enabled".
- Pada beberapa kasus (flutterfire#17643, flutterfire#12553), operasi
  `set()`/`update()` **macet selamanya tanpa melempar exception apapun** —
  persis gejala yang dilaporkan.

**Perbaikan:**
- `firestore_service.dart`: persistence sekarang hanya diaktifkan di
  platform native (`if (!kIsWeb)`), karena di mobile/desktop fitur ini
  stabil dan tidak punya masalah di atas. Web app pada praktiknya nyaris
  selalu online, jadi cache offline tidak sekritis di sana.
- `firestore_service.dart` & `auth_service.dart`: semua operasi tulis
  (`addTask`, `updateTask`, `deleteTask`, `createUserDoc`, `getUserDoc`,
  `updateUserDoc`) sekarang dibungkus `.timeout(Duration(seconds: 15))`
  sebagai pengaman tambahan — kalau SDK/backend macet karena alasan
  apapun di masa depan, UI akan tetap dapat error yang jelas dalam waktu
  wajar, bukan spinner selamanya.
- `app_exception.dart` & `failure.dart`: menambahkan penanganan khusus
  `TimeoutException` dengan pesan "Permintaan butuh waktu terlalu lama.
  Periksa koneksi internet kamu lalu coba lagi." — dan `NetworkFailure`
  sekarang bisa menerima pesan kustom (sebelumnya hardcoded satu pesan
  saja).

---

Dokumen ini berisi daftar semua bug/error yang ditemukan lewat code review
manual menyeluruh dan sudah diperbaiki di source ini.

## 🔴 Bug kritis (menyebabkan crash)

### 1. Firebase diinisialisasi dua kali (`lib/main.dart`)
**Sebelum:** `main.dart` memanggil `WidgetsFlutterBinding.ensureInitialized()`
dan `Firebase.initializeApp()` sendiri, lalu memanggil `bootstrap()` yang
melakukan hal yang sama persis sekali lagi.
**Akibat:** Firebase App default hanya boleh diinisialisasi sekali —
inisialisasi ganda melempar `FirebaseException [core/duplicate-app]` dan
**aplikasi crash setiap kali dijalankan**.
**Perbaikan:** `main.dart` sekarang hanya memanggil `await bootstrap();`.

## 🟠 Bug logika (fungsi tidak bekerja sesuai maksud)

### 2. Pesan error login/register tidak pernah muncul (`lib/core/errors/app_exception.dart`)
**Sebelum:** urutan pengecekan `if (error is FirebaseException)` diletakkan
sebelum `if (error is FirebaseAuthException)`. Karena `FirebaseAuthException`
adalah subclass dari `FirebaseException`, blok kedua tidak pernah tercapai.
**Akibat:** semua error auth (password salah, email sudah terdaftar, dll)
selalu menampilkan pesan generic "Kesalahan Firestore" alih-alih pesan
ramah berbahasa Indonesia yang sudah disiapkan.
**Perbaikan:** urutan pengecekan ditukar — `FirebaseAuthException` dicek
lebih dulu.

### 3. Cache offline dinonaktifkan padahal dimaksudkan aktif (`lib/core/services/firestore_service.dart`)
**Sebelum:** `persistenceEnabled: false`, padahal komentar di atasnya
menjelaskan tujuannya "supaya task tetap bisa dibaca saat offline".
**Akibat:** fitur offline yang didukung `ConnectivityProvider` tidak
benar-benar berfungsi — task tidak bisa dibaca saat tidak ada koneksi.
**Perbaikan:** diubah ke `persistenceEnabled: true`.

### 4. Profil tidak refresh setelah diedit (`lib/screens/profile/profile_screen.dart`)
**Sebelum:** `FutureBuilder` memanggil `authRepository.getUserProfile(uid)`
langsung di dalam `build()`, sehingga Future baru dibuat di setiap rebuild
(anti-pattern, request Firestore berulang) dan setelah kembali dari
`EditProfileScreen`, nama yang baru disimpan tidak langsung muncul.
**Perbaikan:** direfactor menjadi `StatefulWidget` dengan Future yang
disimpan di State, dan otomatis reload setelah `EditProfileScreen`
mengembalikan `true` (sukses simpan).

### 5. Detail tugas menampilkan nama enum mentah (`lib/screens/tasks/task_detail_screen.dart`)
**Sebelum:** `task.priority.name` / `task.status.name` menampilkan nilai
enum mentah (mis. `inProgress`) alih-alih label berbahasa Indonesia,
tidak konsisten dengan tampilan di layar lain.
**Perbaikan:** diganti menjadi `task.priority.label` / `task.status.label`.

## 🧹 Pembersihan (tidak mempengaruhi fungsi, tapi bagian dari "bug" struktural)

- Menghapus folder sampah `lib/screens/{home,statistics,profile,calendar}`
  dan `lib/screens/{notification,settings,about}` — sisa dari perintah
  `mkdir` dengan brace-expansion yang gagal dieksekusi.
- Menghapus 8 file stub 0-byte yang tidak pernah dipakai di manapun:
  `context_extension.dart`, `string_extension.dart`, `formatter.dart`,
  `helper.dart`, `asset_paths.dart`, `app_bar.dart`, `custom_button.dart`,
  `custom_card.dart`. Sudah diverifikasi tidak ada import yang menunjuk
  ke file-file ini.
- Menormalkan line ending CRLF → LF pada `push_notification_service.dart`,
  `task_card.dart`, dan `analysis_options.yaml`.

## ⚠️ Keterbatasan verifikasi

Environment yang saya pakai untuk mengedit tidak memiliki Flutter/Dart SDK
terpasang (dan tidak bisa mengunduhnya karena jaringan dibatasi ke domain
tertentu), sehingga saya **tidak bisa menjalankan `flutter analyze` atau
`flutter test`** untuk verifikasi otomatis. Semua temuan di atas didasarkan
pada code review manual baris-demi-baris, termasuk verifikasi silang semua
import antar file. Saya sangat menyarankan menjalankan:

```bash
flutter pub get
flutter analyze
flutter test
```

di mesin lokal Anda (yang punya Flutter SDK) sebagai langkah verifikasi
akhir sebelum build/release.

## 💡 Rekomendasi visual (belum diterapkan, sesuai catatan Anda)

Anda menyebutkan sisi visual masih kurang. Kode saat ini fungsional
sepenuhnya tapi memakai widget Material standar tanpa banyak polish
(tidak ada ilustrasi/asset kustom di `assets/icons` & `assets/illustrations`
yang saat ini kosong, tidak ada animasi transisi, dsb). Kalau Anda mau,
saya bisa lanjutkan ke perbaikan visual (spacing, warna, ilustrasi empty
state, custom app bar, dll) di percakapan berikutnya — cukup beri tahu
bagian mana yang ingin diprioritaskan.
