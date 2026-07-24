import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  // 1. Wajib dipanggil sebelum melakukan async operation sebelum runApp
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Safe loading untuk mencegah aplikasi Force Close
  try {
    await dotenv.load(fileName: "assets/env.txt");
  } catch (e) {
    debugPrint("Gagal memuat file env: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('EduTrack Running...'),
        ),
      ),
    );
  }
}
