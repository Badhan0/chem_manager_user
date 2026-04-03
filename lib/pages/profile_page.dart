import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/design_system.dart';
import '../services/api_service.dart';
import 'login_page.dart';
import 'profile/medical_history_page.dart';
import 'profile/health_reports_page.dart';
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _userName = 'Patient';
  String _email = 'patient@clinisync.com';
  String _profilePhoto = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Patient';
      _email = prefs.getString('user_email') ?? 'patient@clinisync.com';
      _profilePhoto = prefs.getString('user_photo') ?? '';
    });

    // Fetch updated data from backend
    try {
      final response = await ApiService.get('/patient-users/profile');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final user = data['data'];
          setState(() {
            _userName = user['name'] ?? _userName;
            _email = user['email'] ?? _email;
            _profilePhoto = user['photoURL'] ?? _profilePhoto;
          });
          // Update cache
          await prefs.setString('user_name', _userName);
          await prefs.setString('user_email', _email);
          if (_profilePhoto.isNotEmpty) await prefs.setString('user_photo', _profilePhoto);
        }
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
  }

  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      await ApiService.post('/patient-users/logout', {});
    } catch (e) {
      print('Error during backend logout: $e');
    }

    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: DesignSystem.glassWhite,
                  backgroundImage: _profilePhoto.isNotEmpty ? NetworkImage(_profilePhoto) : null,
                  child: _profilePhoto.isEmpty ? const Icon(Icons.person, color: Colors.white24, size: 60) : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DesignSystem.primaryAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: DesignSystem.background, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(_userName, style: DesignSystem.h1.copyWith(fontSize: 28)),
          Text(_email, style: DesignSystem.bodyMain.copyWith(color: DesignSystem.textSub)),
          const SizedBox(height: 40),
          _buildProfileTile('Medical History', Icons.history_rounded, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MedicalHistoryPage()));
          }),
          _buildProfileTile('Health Reports', Icons.description_rounded, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const HealthReportsPage()));
          }),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text('DE-SYNCHRONISE (LOGOUT)', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileTile(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DesignSystem.glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        leading: Icon(icon, color: DesignSystem.primaryAccent, size: 24),
        title: Text(title, style: DesignSystem.bodyBold),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
        onTap: onTap,
      ),
    );
  }
}
