import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/constants/app_messages.dart';
import 'core/widgets/app_notifier.dart';
import 'screens/login_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'widgets/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  await NotificationService.initNotification();
  await _scheduleSavedReminder();
  runApp(const TraemoApp());
}

Future<void> _scheduleSavedReminder() async {
  final prefs = await SharedPreferences.getInstance();
  final enabled = prefs.getBool('reminder_enabled') ?? true;
  final time = prefs.getString('reminder_time') ?? '20:00';
  final parts = time.split(':');
  final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 20 : 20;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

  if (enabled) {
    await NotificationService.scheduleDailyReminder(
      hour: hour,
      minute: minute,
    );
  } else {
    await NotificationService.cancelReminder();
  }
}

class TraemoApp extends StatefulWidget {
  const TraemoApp({super.key});

  @override
  State<TraemoApp> createState() => _TraemoAppState();
}

class _TraemoAppState extends State<TraemoApp> {
  bool _loggedIn = false;
  ThemeMode _themeMode = ThemeMode.light;
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme');
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    if (!mounted) return;
    setState(() {
      _loggedIn = isLoggedIn;
      _themeMode = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
      _prefsLoaded = true;
    });
  }

  Future<void> _persistTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', mode == ThemeMode.dark ? 'dark' : 'light');
  }

  void _toggleTheme() {
    final next =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setState(() => _themeMode = next);
    _persistTheme(next);
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear saved auth session so the next app start returns to login.
    await prefs.clear();

    if (!mounted) return;
    AppNotifier.showSuccess(
      context,
      message: AppMessages.logoutSuccess,
    );
    setState(() => _loggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    final light = AppTheme.light();
    final dark = AppTheme.dark();

    if (!_prefsLoaded) {
      return MaterialApp(
        title: 'Traemo',
        debugShowCheckedModeBanner: false,
        theme: light,
        darkTheme: dark,
        themeMode: ThemeMode.light,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'Traemo',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: AppNotifier.messengerKey,
      theme: light,
      darkTheme: dark,
      themeMode: _themeMode,
      home: _loggedIn
          ? MainShell(
              isDark: _themeMode == ThemeMode.dark,
              onToggleTheme: _toggleTheme,
              onLogout: _handleLogout,
            )
          : LoginScreen(onLogin: () => setState(() => _loggedIn = true)),
    );
  }
}
