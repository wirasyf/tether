import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/services/haptic_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/settings_service.dart';
import 'core/services/stats_service.dart';
import 'core/services/theme_service.dart';
import 'core/services/achievement_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/pairing_service.dart';
import 'features/pairing/pairing_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D0D1A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Enable edge-to-edge
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init failed, using demo mode: $e');
  }

  // Initialize essential services in parallel (faster startup)
  await Future.wait([
    StorageService.instance.initialize(),
    SettingsService.instance.initialize(),
  ]);

  // Initialize haptic after storage (needs settings)
  await HapticService.instance.initialize();

  // Pre-load pairing code (essential for app function)
  await PairingService.instance.getOrCreatePairingCode();

  runApp(const TetherApp());

  // Defer non-critical services to after first frame (faster perceived startup)
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await Future.wait([
      StatsService.instance.initialize(),
      ThemeService.instance.initialize(),
      AchievementService.instance.initialize(),
      AuthService.instance.initialize(),
    ]);
  });
}

class TetherApp extends StatelessWidget {
  const TetherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: SettingsService.instance),
      ],
      child: MaterialApp(
        title: 'Tether',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const PairingScreen(),
      ),
    );
  }
}
