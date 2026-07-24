import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/auth_service.dart';
import '../core/services/firestore_service.dart';
import '../core/services/notification_service.dart';
import '../providers/auth_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import '../repositories/auth_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/task_repository.dart';
import '../screens/splash/splash_screen.dart';
import 'routes.dart';
import 'theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // --- Services (panggilan mentah ke Firebase) ---
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<NotificationService>(create: (_) => NotificationService()),

        // --- Repositories (translate Model <-> Map, error -> Failure) ---
        ProxyProvider<AuthService, AuthRepository>(
          update: (_, service, __) => AuthRepositoryImpl(service),
        ),
        ProxyProvider<FirestoreService, TaskRepository>(
          update: (_, service, __) => TaskRepositoryImpl(service),
        ),
        ProxyProvider<NotificationService, NotificationRepository>(
          update: (_, service, __) => NotificationRepositoryImpl(service),
        ),

        // --- Providers (state yang dibaca UI) ---
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<ConnectivityProvider>(
          create: (_) => ConnectivityProvider(),
        ),
        ChangeNotifierProxyProvider<AuthRepository, AuthProvider>(
          create: (context) => AuthProvider(context.read<AuthRepository>()),
          update: (_, repository, previous) => previous ?? AuthProvider(repository),
        ),
        ChangeNotifierProxyProvider<TaskRepository, TaskProvider>(
          create: (context) => TaskProvider(context.read<TaskRepository>()),
          update: (_, repository, previous) => previous ?? TaskProvider(repository),
        ),
        ChangeNotifierProxyProvider<NotificationRepository, NotificationProvider>(
          create: (context) => NotificationProvider(context.read<NotificationRepository>()),
          update: (_, repository, previous) => previous ?? NotificationProvider(repository),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'EduTrack',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeProvider.mode,
          routes: AppRoutes.routes,
          // SplashScreen = AuthGate: mutusin ke Login atau layar utama
          // berdasarkan AuthProvider.status. Tidak ada lagi uid hardcode.
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
