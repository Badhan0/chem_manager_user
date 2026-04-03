import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/permission_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Note: Firebase.initializeApp() requires valid google-services.json/GoogleService-Info.plist
  // If not present, this will throw. I'll wrap it for safety in dev.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  final bool hasSeenPermissions = prefs.getBool('has_seen_permissions') ?? false;

  runApp(MyApp(
    isLoggedIn: token != null, 
    hasSeenPermissions: hasSeenPermissions
  ));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool hasSeenPermissions;

  const MyApp({super.key, required this.isLoggedIn, required this.hasSeenPermissions});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Clini Sync User',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        textTheme: GoogleFonts.outfitTextTheme(
          Theme.of(context).textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF06B6D4),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: isLoggedIn 
          ? const HomePage() 
          : (hasSeenPermissions ? const LoginPage() : const PermissionScreen()),
    );
  }
}
