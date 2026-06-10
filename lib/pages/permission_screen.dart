import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/design_system.dart';
import 'login_page.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  _PermissionScreenState createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _isProcessing = false;

  Future<void> _requestPermissions() async {
    setState(() => _isProcessing = true);

    // Requesting Location, Gallery (Photos) and Notifications
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.photos,
      Permission.notification,
    ].request();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_permissions', true);

    setState(() => _isProcessing = false);

    // Proceed regardless of status (user might deny some, but we let them into login)
    // In a real app, you might want to show why certain features won't work.
    _navigateToLogin();
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: DesignSystem.glassWhite,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
                ),
                child: const Icon(Icons.security_update_good, size: 64, color: DesignSystem.primaryAccent),
              ),
              const SizedBox(height: 48),
              Text('Elite Permissions', style: DesignSystem.h1),
              const SizedBox(height: 16),
              Text(
                'To provide an elite medical experience, Clini Sync requires access to your location, gallery, and notifications.',
                textAlign: TextAlign.center,
                style: DesignSystem.bodyMain,
              ),
              const SizedBox(height: 64),
              _isProcessing
                  ? const CircularProgressIndicator(color: DesignSystem.primaryAccent)
                  : _buildPermissionItem(Icons.location_on, 'Precise Location', 'For finding elite clinics nearby'),
              const SizedBox(height: 24),
              _buildPermissionItem(Icons.photo_library, 'Gallery Access', 'To upload medical reports securely'),
              const SizedBox(height: 24),
              _buildPermissionItem(Icons.notifications_active, 'Sync Notifications', 'Stay updated on your health vitals'),
              const Spacer(),
              _buildPrimaryButton('GRANT ACCESS', _requestPermissions),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: DesignSystem.primaryAccent, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: DesignSystem.buttonText.copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(subtitle, style: DesignSystem.bodyMain.copyWith(fontSize: 12, color: DesignSystem.textSub)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: DesignSystem.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [DesignSystem.neonShadow(DesignSystem.primaryAccent)],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(text, style: DesignSystem.buttonText),
      ),
    );
  }
}
