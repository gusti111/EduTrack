import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';
import 'firebase_options.dart';

/// Menangani semua inisialisasi berat & error handling global,
/// supaya main.dart tetap tipis dan mudah dibaca.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // TODO: kirim ke Crashlytics kalau sudah dipasang.
  };

  // Config sensitif (bukan Firebase key — itu aman di firebase_options.dart)
  // dibaca dari .env yang tidak ikut di-commit.
  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const App());
}
