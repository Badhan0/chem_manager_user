import 'dart:ui';
import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../theme/design_system.dart';
import 'signup_page.dart';
import 'home_page.dart';
import 'otp_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final AuthController _authController = AuthController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorSnackBar("Please enter your credentials to synchronise.");
      return;
    }

    setState(() => _isLoading = true);
    final result = await _authController.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    setState(() => _isLoading = false);

    if (result['success']) {
      _navigateToHome();
    } else if (result['error'] == 'ACCESS_DENIED_PROFESSIONAL') {
      _showAccessDeniedDialog(result['message']);
    } else if (result['error'] == 'USER_NOT_FOUND') {
      _showAccountNotFoundDialog();
    } else if (result['requiresVerification'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OTPScreen(email: result['email'])),
      );
    } else {
      _showErrorSnackBar(result['message']);
    }
  }

  void _showAccessDeniedDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: DesignSystem.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text("Exclusive Portal", style: DesignSystem.h2),
          content: Text(
            message,
            style: DesignSystem.bodyMain,
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                gradient: DesignSystem.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("UNDERSTOOD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountNotFoundDialog() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: DesignSystem.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text("Identity Not Found", style: DesignSystem.h2),
          content: Text(
            "You don't have any account. Signup first to access the elite care portal.",
            style: DesignSystem.bodyMain,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Later", style: TextStyle(color: DesignSystem.textSub)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: DesignSystem.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupPage()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("SIGNUP NOW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    final result = await _authController.googleLogin();
    setState(() => _isLoading = false);

    if (result['success']) {
      _navigateToHome();
    } else if (result['error'] == 'ACCESS_DENIED_PROFESSIONAL') {
      _showAccessDeniedDialog(result['message']);
    } else if (result['error'] == 'not_found' || result['message'] == 'User not found') {
      _showAccountNotFoundDialog();
    } else {
      _showErrorSnackBar(result['message'] ?? "Connection failed.");
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.background,
      body: Stack(
        children: [
          // Futuristic Background Accents
          Positioned(
            top: -100,
            right: -50,
            child: _buildBlurCircle(200, DesignSystem.primaryAccent.withOpacity(0.2)),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildBlurCircle(250, DesignSystem.secondaryAccent.withOpacity(0.15)),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 170),
                    // Logo & Brand
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: DesignSystem.glassWhite,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white12),
                            ),
                            child: const Icon(Icons.auto_awesome, size: 48, color: DesignSystem.primaryAccent),
                          ),
                          const SizedBox(height: 20),
                          Text('Clini Sync', style: DesignSystem.h1),
                          Text(
                            'Your Health, Synchronised',
                            style: DesignSystem.bodyMain.copyWith(color: DesignSystem.primaryAccent),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text('Elite Login', style: DesignSystem.h2),
                    const SizedBox(height: 10),
                    Text('Access your premium medical portal', style: DesignSystem.bodyMain),
                    const SizedBox(height: 32),

                    _buildGlassField(_emailController, 'Email Address', Icons.alternate_email),
                    const SizedBox(height: 20),
                    _buildGlassField(_passwordController, 'Security Token / Password', Icons.security, isPassword: true),
                    
                    const SizedBox(height: 40),
                    _isLoading 
                      ? const Center(child: CircularProgressIndicator(color: DesignSystem.primaryAccent))
                      : Column(
                          children: [
                            _buildPrimaryButton('SYNCHRONISE', _handleLogin),
                            const SizedBox(height: 24),
                            _buildGoogleButton(),
                          ],
                        ),
                    
                    const SizedBox(height: 40),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupPage())),
                        child: RichText(
                          text: TextSpan(
                            style: DesignSystem.bodyMain,
                            children: [
                              const TextSpan(text: "New here? "),
                              TextSpan(
                                text: "Join the Elite Care",
                                style: TextStyle(color: DesignSystem.primaryAccent, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildGlassField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: DesignSystem.glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: DesignSystem.primaryAccent, size: 20),
          hintText: label,
          hintStyle: TextStyle(color: DesignSystem.textSub.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
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

  Widget _buildGoogleButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: DesignSystem.glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: TextButton.icon(
        onPressed: _handleGoogleLogin,
        icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1024px-Google_%22G%22_logo.svg.png', height: 24),
        label: Text('Continue with Google', style: DesignSystem.buttonText.copyWith(fontSize: 14)),
      ),
    );
  }
}
