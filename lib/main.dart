import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'pages/login_page.dart';
import 'pages/landing_page.dart';
import 'layout/main_shell.dart';
import 'services/api_service.dart';
import 'services/push_notification_service.dart';
import 'theme/app_theme.dart';
import 'widgets/notification_listener.dart';
import 'services/translation_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase avec gestion d'erreur améliorée
  try {
    if (kIsWeb) {
      // Sur Web, on peut initialiser sans options si configuré dans index.html
      // Mais ici on évite le crash si les options manquent
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyAh38HT4QO0A8a6ynot-LXZoG6b2Co5UHI",
          appId: "1:727815484300:web:eb57e5d8d85f8f8f", // Placeholder, à vérifier
          messagingSenderId: "727815484300",
          projectId: "comminity-system-alert",
          storageBucket: "comminity-system-alert.firebasestorage.app",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await PushNotificationService.initialize();
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  String? token = await ApiService.getToken();
  bool isDark = await AppTheme.getIsDarkMode();
  await T.init();

  runApp(MyApp(initialLoggedIn: token != null, initialDarkMode: isDark));
}

class MyApp extends StatefulWidget {
  final bool initialLoggedIn;
  final bool initialDarkMode;

  const MyApp({super.key, required this.initialLoggedIn, required this.initialDarkMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isLoggedIn;
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = widget.initialLoggedIn;
    _isDarkMode = widget.initialDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: T.locale,
      builder: (context, lang, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Community Security Alert',
          debugShowCheckedModeBanner: false,
          theme: _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: _isLoggedIn
              ? MainShell(
                  isDarkMode: _isDarkMode,
                  onThemeChanged: (value) => setState(() => _isDarkMode = value),
                )
              : const LandingPage(),
        );
      },
    );
  }
}
