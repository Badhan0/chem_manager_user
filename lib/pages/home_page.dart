import 'dart:ui';
import 'package:flutter/material.dart';
import 'upcoming_visits_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/design_system.dart';
import 'login_page.dart';
import 'track_orders_page.dart';
import 'prescriptions_page.dart';
import 'clinicians_page.dart';
import 'health_wallet_page.dart';
import 'profile_page.dart';
import 'search_doctors_page.dart';
import 'search_clinics_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _userName = 'Alex';
  String _userId = 'CSU-BK291';
  String _profilePhoto = '';
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomeDashboard(onNavigateToOrders: () {}), // Will be set in initState
    const TrackOrdersPage(),
    const Center(child: Text("Notifications Flow Placeholder", style: TextStyle(color: Colors.white24))),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _pages[0] = HomeDashboard(onNavigateToOrders: () => setState(() => _selectedIndex = 1));
  }

  final List<String> _titles = [
    'CLINI SYNC',
    'TRACK ORDERS',
    'ALERTS',
    'PROFILE',
  ];

  void _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Patient';
      _userId = prefs.getString('user_id') ?? 'PATIENT_ID';
      _profilePhoto = prefs.getString('user_photo') ?? '';
    });
  }

  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.background,
      body: Stack(
        children: [
          // Dynamic BG
          Positioned(top: -50, left: -50, child: _buildOrb(300, DesignSystem.primaryAccent.withOpacity(0.1))),
          Positioned(bottom: 100, right: -50, child: _buildOrb(250, DesignSystem.secondaryAccent.withOpacity(0.1))),

          SafeArea(
            child: Column(
              children: [
                _buildModernAppBar(),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _pages,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildFuturisticNavBar(),
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_titles[_selectedIndex], style: DesignSystem.h2.copyWith(fontSize: 18, letterSpacing: 2)),
          // Profile handled in separate tab now
        ],
      ),
    );
  }

  Widget _buildOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70), child: Container(color: Colors.transparent)),
    );
  }

  Widget _buildFuturisticNavBar() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: DesignSystem.background.withOpacity(0.8),
        border: const Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_filled, "Home", 0),
          _buildNavItem(Icons.shutter_speed_rounded, "Orders", 1),
          _buildNavItem(Icons.notifications_none_rounded, "Alerts", 2),
          _buildNavItem(Icons.person_outline_rounded, "Profile", 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? DesignSystem.primaryAccent : DesignSystem.textSub, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isActive ? DesignSystem.primaryAccent : DesignSystem.textSub, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class HomeDashboard extends StatefulWidget {
  final VoidCallback onNavigateToOrders;
  const HomeDashboard({super.key, required this.onNavigateToOrders});

  @override
  _HomeDashboardState createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  String _userName = 'Patient';
  String _userId = '...';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Patient';
      _userId = prefs.getString('user_id') ?? 'PATIENT_ID';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(),
          const SizedBox(height: 32),
          _buildEliteBookingCard(),
          const SizedBox(height: 40),
          Text('Elite Services', style: DesignSystem.h2),
          const SizedBox(height: 20),
          _buildServicesGrid(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good Day,', style: DesignSystem.bodyMain),
                Text(_userName, style: DesignSystem.h1.copyWith(fontSize: 28)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: DesignSystem.primaryAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DesignSystem.primaryAccent.withOpacity(0.3)),
              ),
              child: Text(_userId, style: DesignSystem.bodyBold.copyWith(fontSize: 12, color: DesignSystem.primaryAccent)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEliteBookingCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: DesignSystem.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [DesignSystem.neonShadow(DesignSystem.primaryAccent)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(right: -20, top: -20, child: Icon(Icons.calendar_month, size: 150, color: Colors.white.withOpacity(0.1))),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Book Elite Care', style: DesignSystem.h2.copyWith(color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('Connect with world-class medical specialists instantly.', style: DesignSystem.bodyMain.copyWith(color: Colors.white70)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchDoctorsPage()));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: DesignSystem.primaryAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('DOCTORS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchClinicsPage()));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignSystem.background.withOpacity(0.5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('CLINICS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildServiceCard('Track Orders', Icons.shutter_speed_rounded, Colors.orangeAccent, () {
          widget.onNavigateToOrders();
        }),
        _buildServiceCard('Prescriptions', Icons.description_rounded, Colors.tealAccent, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const PrescriptionsPage()));
        }),
        _buildServiceCard('My Clinicians', Icons.medication_liquid_rounded, Colors.pinkAccent, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CliniciansPage()));
        }),
        _buildServiceCard('Doctor Visits', Icons.event_available_rounded, Colors.cyanAccent, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const UpcomingVisitsPage()));
        }),
      ],
    );
  }

  Widget _buildServiceCard(String title, IconData icon, Color accent, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: DesignSystem.glassWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: accent.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: accent, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title, style: DesignSystem.bodyBold.copyWith(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
