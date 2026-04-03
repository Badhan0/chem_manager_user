import 'dart:ui';
import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../theme/design_system.dart';
import 'home_page.dart';
import 'otp_screen.dart';

class SignupPage extends StatefulWidget {
  final String? initialEmail;
  final String? initialName;
  final String? photoURL;

  const SignupPage({
    super.key, 
    this.initialEmail, 
    this.initialName,
    this.photoURL,
  });

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final AuthController _authController = AuthController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
    _emailController.text = widget.initialEmail ?? '';
  }

  void _handleSignup() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _phoneController.text.isEmpty) {
      _showErrorSnackBar("Essential details missing. Please complete your profile.");
      return;
    }

    setState(() => _isLoading = true);
    final result = await _authController.signup(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.isEmpty ? 'GOOGLE_LOGIN_SECURE_TOKEN' : _passwordController.text.trim(),
      phone: _phoneController.text.trim(),
      photoURL: widget.photoURL,
    );
    setState(() => _isLoading = false);

    if (result['success']) {
      if (!mounted) return;
      if (result['requiresVerification'] == true) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OTPScreen(email: result['email'])),
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      }
    } else if (result['error'] == 'ACCESS_DENIED_PROFESSIONAL') {
      _showAccessDeniedDialog(result['message']);
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
          title: Text("Exclusive Registration", style: DesignSystem.h2),
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

  void _handleGoogleSignup() async {
    setState(() => _isLoading = true);
    final result = await _authController.googleLogin();
    setState(() => _isLoading = false);

    if (result['success']) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    } else if (result['error'] == 'ACCESS_DENIED_PROFESSIONAL') {
      _showAccessDeniedDialog(result['message']);
    } else if (result['error'] == 'not_found' || result['message'] == 'User not found') {
      // User doesn't exist, proceed to create account automatically with Google info
      final signupResult = await _authController.signup(
        name: result['name'] ?? 'Google User',
        email: result['email'] ?? '',
        password: 'GOOGLE_LOGIN_SECURE_TOKEN_${DateTime.now().millisecondsSinceEpoch}',
        phone: 'Not Provided',
        photoURL: result['photoURL'],
        isGoogleSignup: true,
      );

      if (signupResult['success']) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      } else if (signupResult['error'] == 'ACCESS_DENIED_PROFESSIONAL') {
        _showAccessDeniedDialog(signupResult['message']);
      } else {
        _showErrorSnackBar(signupResult['message'] ?? "Signup failed.");
      }
    } else {
      _showErrorSnackBar(result['message'] ?? "Connection failed.");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.background,
      body: Stack(
        children: [
          Positioned(top: -100, left: -50, child: _buildBlurCircle(300, DesignSystem.secondaryAccent.withOpacity(0.1))),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 10),
                  Text('Elite Care Registration', style: DesignSystem.h1.copyWith(fontSize: 28)),
                  const SizedBox(height: 4),
                  Text('Start your journey to personalised excellence.', style: DesignSystem.bodyMain),

                  const SizedBox(height: 24),
                  _buildGlassField(_nameController, 'Full Identity Name', Icons.person_outline),
                  const SizedBox(height: 20),
                  _buildGlassField(_emailController, 'Verified Contact Email', Icons.email_outlined),
                  const SizedBox(height: 20),
                  _buildGlassField(_phoneController, 'Contact Sequence (Phone)', Icons.phone_android_outlined),
                  const SizedBox(height: 20),
                  if (widget.initialEmail == null)
                    _buildGlassField(_passwordController, 'Create Security Passphrase', Icons.lock_outline, isPassword: true),

                  const SizedBox(height: 30),
                  _isLoading
                    ? const Center(child: CircularProgressIndicator(color: DesignSystem.primaryAccent))
                    : Column(
                        children: [
                          _buildPrimaryButton('INITIALISE ACCOUNT', _handleSignup),
                          const SizedBox(height: 24),
                          _buildGoogleButton(),
                        ],
                      ),
                  
                  const SizedBox(height: 32),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Existing Elite Member? Sign In', style: DesignSystem.bodyMain.copyWith(color: DesignSystem.primaryAccent)),
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

  Widget _buildBlurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50), child: Container(color: Colors.transparent)),
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
        onPressed: _handleGoogleSignup,
        icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1024px-Google_%22G%22_logo.svg.png', height: 24),
        label: Text('Signup with Google', style: DesignSystem.buttonText.copyWith(fontSize: 14)),
      ),
    );
  }
}
