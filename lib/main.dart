import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/permission_screen.dart';
import 'pages/profile/edit_profile_page.dart';
import 'theme/design_system.dart';

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
  final phone = prefs.getString('user_phone');
  final bool hasSeenPermissions = prefs.getBool('has_seen_permissions') ?? false;
  final bool isProfileIncomplete = token != null && (phone == null || phone.isEmpty || phone == 'Not Provided');

  runApp(MyApp(
    isLoggedIn: token != null, 
    isProfileIncomplete: isProfileIncomplete,
    hasSeenPermissions: hasSeenPermissions
  ));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool isProfileIncomplete;
  final bool hasSeenPermissions;

  const MyApp({
    super.key, 
    required this.isLoggedIn, 
    required this.isProfileIncomplete, 
    required this.hasSeenPermissions
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Clini Sync User',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: DesignSystem.background,
        textTheme: GoogleFonts.outfitTextTheme(
          Theme.of(context).textTheme.apply(
            bodyColor: DesignSystem.textMain,
            displayColor: DesignSystem.textMain,
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: DesignSystem.primaryAccent,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: isLoggedIn 
          ? (isProfileIncomplete 
              ? const EditProfilePage(isMandatoryProfileSetup: true) 
              : const HomePage())
          : (hasSeenPermissions ? const LoginPage() : const PermissionScreen()),
    );
  }
}
