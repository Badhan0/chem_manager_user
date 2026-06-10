import 'dart:convert';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'upcoming_visits_page.dart';
import 'visit_history_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/design_system.dart';
import '../services/api_service.dart';
import 'login_page.dart';
import 'track_orders_page.dart';
import 'prescriptions_page.dart';
import 'clinicians_page.dart';
import 'health_wallet_page.dart';
import 'profile_page.dart';
import 'search_doctors_page.dart';
import 'search_clinics_page.dart';

import 'alerts_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  String _userName = 'Alex';
  String _userId = 'CSU-BK291';
  String _profilePhoto = '';
  int _selectedIndex = 0;
  late AnimationController _rotationController;

  List<Widget> get _pages => [
    HomeDashboard(
      userName: _userName,
      userId: _userId,
      onNavigateToOrders: () => setState(() => _selectedIndex = 2),
    ),
    const VisitHistoryPage(isEmbedded: true),
    const UpcomingVisitsPage(isEmbedded: true),
    const AlertsTab(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _loadUserData();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  final List<String> _titles = [
    'CLINI SYNC',
    'VISIT HISTORY',
    'UPCOMING VISITS',
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

    try {
      final response = await ApiService.getProfile();
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['success'] == true && resData['data'] != null) {
          final user = resData['data'];
          final name = user['name'] ?? 'Patient';
          final customId = user['userId'] ?? user['id'] ?? user['_id'] ?? 'PATIENT_ID';
          final photo = user['photoURL'] ?? '';

          await prefs.setString('user_name', name);
          await prefs.setString('user_id', customId);
          await prefs.setString('user_photo', photo);

          if (mounted) {
            setState(() {
              _userName = name;
              _userId = customId;
              _profilePhoto = photo;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading dynamic profile data: $e');
    }
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
          Positioned(top: -50, left: -50, child: _buildOrb(300, DesignSystem.primaryAccent.withOpacity(0.15))),
          Positioned(bottom: 100, right: -50, child: _buildOrb(250, DesignSystem.secondaryAccent.withOpacity(0.15))),

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
    if (_selectedIndex == 1 || _selectedIndex == 2) {
      return const SizedBox.shrink();
    }
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
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 85, sigmaY: 85), child: Container(color: Colors.transparent)),
    );
  }

  Widget _buildFuturisticNavBar() {
    bool isCenterActive = _selectedIndex == 2;
    double upcomingSize = 80.0;

    return Container(
      height: 110,
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Glassmorphic navigation bar background
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 80,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 25,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.72),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.6),
                        width: 1.5,
                      ),
                    ),
                    child: SizedBox(
                      height: 80,
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const SizedBox(width: 24),
                                _buildNavItem(Icons.home_filled, "Home", 0),
                                const Spacer(),
                                _buildNavItem(Icons.history_rounded, "History", 1),
                                const SizedBox(width: 16),
                              ],
                            ),
                          ),
                          const SizedBox(width: 96), // Clean gap for the rotating floating button
                          Expanded(
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                _buildNavItem(Icons.notifications_none_rounded, "Alerts", 3),
                                const Spacer(),
                                _buildNavItem(Icons.person_outline_rounded, "Profile", 4),
                                const SizedBox(width: 24),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Rotating 3D floating Ball Action Button
          Positioned(
            top: -16, // Float slightly higher to show the shadow underneath
            left: MediaQuery.of(context).size.width / 2 - (upcomingSize / 2),
            child: GestureDetector(
              onTap: () => setState(() => _selectedIndex = 2),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // 0. Soft ambient contact shadow beneath the ball (creates floating 3D effect)
                  Positioned(
                    bottom: -10,
                    child: Container(
                      width: upcomingSize * 0.7,
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.elliptical(upcomingSize * 0.7, 10)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 10,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 1. Rotating 3D Ball
                  Container(
                    width: upcomingSize,
                    height: upcomingSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: DesignSystem.primaryAccent.withOpacity(isCenterActive ? 0.5 : 0.3),
                          blurRadius: isCenterActive ? 20 : 14,
                          offset: Offset(0, isCenterActive ? 8 : 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Stack(
                        children: [
                          // Deep blue background color of the ball with 3D Radial Gradient shading
                          Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: const Alignment(-0.25, -0.25),
                                radius: 0.85,
                                colors: [
                                  Colors.white,
                                  Colors.lightBlueAccent,
                                  DesignSystem.primaryAccent,
                                  const Color(0xFF060919),
                                ],
                                stops: const [0.0, 0.25, 0.65, 1.0],
                              ),
                            ),
                          ),
                          // Dynamic 3D Spherical grid lines texture (rotates with mathematical distortion)
                          AnimatedBuilder(
                            animation: _rotationController,
                            builder: (context, child) {
                              return Positioned.fill(
                                child: CustomPaint(
                                  painter: SphereTexturePainter(
                                    rotationValue: _rotationController.value,
                                    baseColor: DesignSystem.primaryAccent,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Static Specular Highlight (Bulb reflection on the glossy glass sphere)
                          Positioned(
                            left: upcomingSize * 0.18,
                            top: upcomingSize * 0.18,
                            child: Container(
                              width: upcomingSize * 0.22,
                              height: upcomingSize * 0.22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.8),
                                    Colors.white.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Ambient Rim light reflection on the bottom right edge
                          IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  center: const Alignment(0.45, 0.45),
                                  radius: 0.95,
                                  colors: [
                                    Colors.transparent,
                                    Colors.transparent,
                                    Colors.lightBlueAccent.withOpacity(0.35),
                                  ],
                                  stops: const [0.0, 0.75, 1.0],
                                ),
                              ),
                            ),
                          ),
                          // Glass gloss highlight outer outline
                          IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.38),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 2. Rotating holographic icon and label (Y-axis rotation)
                  IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _rotationController,
                      builder: (context, child) {
                        // Angle goes from 0 to -2*pi for right-to-left rotation
                        double angle = -2 * math.pi * _rotationController.value;
                        
                        // Side A (Upcoming)
                        double angleA = angle;
                        double xA = math.sin(angleA);
                        double zA = math.cos(angleA);
                        double xOffsetA = xA * (upcomingSize * 0.22);
                        double scaleA = 0.65 + 0.35 * zA;
                        double opacityA = zA > 0 ? zA : 0.0;

                        // Side B (Visits)
                        double angleB = angle + math.pi;
                        double xB = math.sin(angleB);
                        double zB = math.cos(angleB);
                        double xOffsetB = xB * (upcomingSize * 0.22);
                        double scaleB = 0.65 + 0.35 * zB;
                        double opacityB = zB > 0 ? zB : 0.0;

                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Side B (Visits)
                            if (opacityB > 0.05)
                              Transform.translate(
                                offset: Offset(xOffsetB, 0),
                                child: Transform.scale(
                                  scale: scaleB,
                                  child: Opacity(
                                    opacity: opacityB,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.calendar_month_rounded,
                                          color: Colors.white,
                                          size: isCenterActive ? 28 : 26,
                                          shadows: const [
                                            Shadow(
                                              color: Colors.black87,
                                              offset: Offset(0, 2),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 1),
                                        const Text(
                                          "Visits",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black87,
                                                offset: Offset(0, 2),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            // Side A (Upcoming)
                            if (opacityA > 0.05)
                              Transform.translate(
                                offset: Offset(xOffsetA, 0),
                                child: Transform.scale(
                                  scale: scaleA,
                                  child: Opacity(
                                    opacity: opacityA,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.event_available_rounded,
                                          color: Colors.white,
                                          size: isCenterActive ? 28 : 26,
                                          shadows: const [
                                            Shadow(
                                              color: Colors.black87,
                                              offset: Offset(0, 2),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 1),
                                        const Text(
                                          "Upcoming",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black87,
                                                offset: Offset(0, 2),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? DesignSystem.primaryAccent : DesignSystem.textSub.withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? DesignSystem.primaryAccent : DesignSystem.textSub.withOpacity(0.7),
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeDashboard extends StatefulWidget {
  final String userName;
  final String userId;
  final VoidCallback onNavigateToOrders;
  const HomeDashboard({
    super.key,
    required this.userName,
    required this.userId,
    required this.onNavigateToOrders,
  });

  @override
  _HomeDashboardState createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  @override
  void initState() {
    super.initState();
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
                Text(widget.userName, style: DesignSystem.h1.copyWith(fontSize: 28)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: DesignSystem.primaryAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DesignSystem.primaryAccent.withOpacity(0.3)),
              ),
              child: Text(widget.userId, style: DesignSystem.bodyBold.copyWith(fontSize: 12, color: DesignSystem.primaryAccent)),
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
                            backgroundColor: Colors.white.withOpacity(0.15),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: Colors.white.withOpacity(0.4)),
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
        AnimatedServiceCard(
          title: 'Upcoming Visits',
          icon: Icons.event_available_rounded,
          accent: Colors.blue,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const UpcomingVisitsPage()));
          },
        ),
        AnimatedServiceCard(
          title: 'Prescriptions',
          icon: Icons.receipt_long_rounded,
          accent: Colors.teal,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const PrescriptionsPage()));
          },
        ),
        AnimatedServiceCard(
          title: 'My Clinicians',
          icon: Icons.supervised_user_circle_rounded,
          accent: Colors.pink,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CliniciansPage()));
          },
        ),
        AnimatedServiceCard(
          title: 'Visit Histories',
          icon: Icons.history_rounded,
          accent: Colors.orange,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const VisitHistoryPage()));
          },
        ),
      ],
    );
  }
}

class AnimatedServiceCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const AnimatedServiceCard({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  State<AnimatedServiceCard> createState() => _AnimatedServiceCardState();
}

class _AnimatedServiceCardState extends State<AnimatedServiceCard> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late AnimationController _floatController;
  late Animation<double> _yOffsetAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Continuous floating animation for the icon
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _yOffsetAnimation = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) {
          _controller.forward();
          setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          _controller.reverse();
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () {
          _controller.reverse();
          setState(() => _isPressed = false);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _isPressed ? Colors.white.withOpacity(0.85) : Colors.white.withOpacity(0.55),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isPressed ? widget.accent.withOpacity(0.5) : Colors.white.withOpacity(0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.accent.withOpacity(_isPressed ? 0.25 : 0.08),
                    blurRadius: _isPressed ? 20 : 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _yOffsetAnimation.value),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.accent.withOpacity(0.35),
                                widget.accent.withOpacity(0.12),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: widget.accent.withOpacity(0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.accent.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.icon,
                            color: widget.accent,
                            size: 32,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.title,
                    style: DesignSystem.bodyBold.copyWith(
                      fontSize: 14,
                      color: DesignSystem.textMain.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SphereTexturePainter extends CustomPainter {
  final double rotationValue;
  final Color baseColor;

  SphereTexturePainter({
    required this.rotationValue,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double R = size.width / 2;
    final double H = size.height;

    // Draw latitude lines (fixed, curved to look 3D)
    final latPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Equator (flat)
    canvas.drawLine(Offset(0, H / 2), Offset(size.width, H / 2), latPaint);

    // Northern latitude (curved upwards)
    final northPath = Path()
      ..moveTo(R - R * math.cos(math.pi / 6), H * 0.28)
      ..quadraticBezierTo(
        R,
        H * 0.22,
        R + R * math.cos(math.pi / 6),
        H * 0.28,
      );
    canvas.drawPath(northPath, latPaint);

    // Southern latitude (curved downwards)
    final southPath = Path()
      ..moveTo(R - R * math.cos(math.pi / 6), H * 0.72)
      ..quadraticBezierTo(
        R,
        H * 0.78,
        R + R * math.cos(math.pi / 6),
        H * 0.72,
      );
    canvas.drawPath(southPath, latPaint);

    // Draw rotating longitude lines
    double rotationAngle = -2 * math.pi * rotationValue;
    
    // Draw 6 longitude lines
    for (int i = 0; i < 6; i++) {
      double theta = rotationAngle + (i * math.pi / 3);
      double cosTheta = math.cos(theta);
      
      // Only draw if on the front hemisphere
      if (cosTheta > 0) {
        final lonPaint = Paint()
          ..color = Colors.lightBlueAccent.withOpacity(0.35 * cosTheta)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        final path = Path()
          ..moveTo(R, 0)
          ..quadraticBezierTo(
            R + R * math.sin(theta) * 2.0,
            H / 2,
            R,
            H,
          );
        canvas.drawPath(path, lonPaint);
      }
    }

    // Draw rotating glowing data nodes
    final List<Map<String, double>> nodes = [
      {'lat': H * 0.35, 'lonOffset': 0.0},
      {'lat': H * 0.65, 'lonOffset': math.pi / 2},
      {'lat': H * 0.45, 'lonOffset': math.pi},
      {'lat': H * 0.55, 'lonOffset': 3 * math.pi / 2},
    ];

    for (var node in nodes) {
      double theta = rotationAngle + node['lonOffset']!;
      double cosTheta = math.cos(theta);
      if (cosTheta > 0) {
        double x = R + R * math.sin(theta) * math.cos(math.pi * 0.1);
        double y = node['lat']!;

        final nodePaint = Paint()
          ..color = Colors.lightBlueAccent.withOpacity(cosTheta)
          ..style = PaintingStyle.fill;
          
        final glowPaint = Paint()
          ..color = Colors.lightBlueAccent.withOpacity(0.35 * cosTheta)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(x, y), 5.0, glowPaint);
        canvas.drawCircle(Offset(x, y), 2.5, nodePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SphereTexturePainter oldDelegate) =>
      oldDelegate.rotationValue != rotationValue;
}
