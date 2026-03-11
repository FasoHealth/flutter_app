import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'layout/main_shell.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? token = await ApiService.getToken();
  bool isDark = await AppTheme.getIsDarkMode();

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
    return MaterialApp(
      title: 'Community Security Alert',
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: _isLoggedIn
          ? MainShell(
              isDarkMode: _isDarkMode,
              onThemeChanged: (value) => setState(() => _isDarkMode = value),
            )
          : LoginPage(
              onLoginSuccess: () => setState(() => _isLoggedIn = true),
            ),
    );
  }
}
