import 'dart:ui';
import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../theme/design_system.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with TickerProviderStateMixin {
  final AuthController _authController = AuthController();

  // Step tracking: 1 = email, 2 = OTP, 3 = new password
  int _step = 1;
  bool _isLoading = false;

  // Controllers
  final _emailController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Data to carry between steps
  String _email = '';
  String _resetToken = '';

  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _emailController.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _animateToNextStep() {
    _slideController.reset();
    _slideController.forward();
  }

  String get _otpValue => _otpControllers.map((c) => c.text).join();

  // ────────────────────────────── Step handlers ──────────────────────────────

  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnack('Please enter a valid email address.');
      return;
    }
    setState(() => _isLoading = true);
    final result = await _authController.forgotPassword(email);
    setState(() => _isLoading = false);

    if (result['success']) {
      _email = email;
      setState(() => _step = 2);
      _animateToNextStep();
    } else {
      _showSnack(result['message']);
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpValue;
    if (otp.length != 6) {
      _showSnack('Please enter the complete 6-digit OTP.');
      return;
    }
    setState(() => _isLoading = true);
    final result = await _authController.verifyResetOtp(_email, otp);
    setState(() => _isLoading = false);

    if (result['success']) {
      _resetToken = result['resetToken'];
      setState(() => _step = 3);
      _animateToNextStep();
    } else {
      _showSnack(result['message']);
    }
  }

  Future<void> _handleResetPassword() async {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (newPass.isEmpty || newPass.length < 6) {
      _showSnack('Password must be at least 6 characters.');
      return;
    }
    if (newPass != confirmPass) {
      _showSnack('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);
    final result = await _authController.resetPassword(_email, _resetToken, newPass);
    setState(() => _isLoading = false);

    if (result['success']) {
      _showSuccessAndPop();
    } else {
      _showSnack(result['message']);
    }
  }

  void _showSuccessAndPop() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: AlertDialog(
          backgroundColor: DesignSystem.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: DesignSystem.primaryGradient,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              Text('Password Reset!', style: DesignSystem.h2),
              const SizedBox(height: 10),
              Text(
                'Your password has been reset successfully. You can now log in with your new password.',
                style: DesignSystem.bodyMain,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildPrimaryButton('Back to Login', () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.redAccent.withOpacity(0.85),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ────────────────────────────── Build ──────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.background,
      body: Stack(
        children: [
          // Background accents
          Positioned(
            top: -80,
            right: -60,
            child: _blurCircle(180, DesignSystem.primaryAccent.withOpacity(0.18)),
          ),
          Positioned(
            bottom: -40,
            left: -60,
            child: _blurCircle(220, DesignSystem.secondaryAccent.withOpacity(0.12)),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildTopBar(),
                  _buildStepIndicator(),
                  Expanded(
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: _buildCurrentStep(),
                      ),
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

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (_step > 1) {
                setState(() => _step--);
                _animateToNextStep();
              } else {
                Navigator.pop(context);
              }
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DesignSystem.glassWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: DesignSystem.textMain, size: 18),
            ),
          ),
          const Spacer(),
          Text('Reset Password', style: DesignSystem.h2.copyWith(fontSize: 18)),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = _step >= i + 1;
          final isCurrent = _step == i + 1;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: isActive ? DesignSystem.primaryGradient : null,
                      color: isActive ? null : Colors.white.withOpacity(0.15),
                    ),
                  ),
                ),
                if (i < 2) const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 1:
        return _buildEmailStep();
      case 2:
        return _buildOtpStep();
      case 3:
        return _buildNewPasswordStep();
      default:
        return _buildEmailStep();
    }
  }

  // ─── Step 1: Email ───

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: DesignSystem.primaryGradient,
              boxShadow: [DesignSystem.neonShadow(DesignSystem.primaryAccent)],
            ),
            child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 44),
          ),
        ),
        const SizedBox(height: 28),
        Text('Forgot Password?', style: DesignSystem.h1.copyWith(fontSize: 26)),
        const SizedBox(height: 8),
        Text(
          'Enter your registered email address. We\'ll send a one-time password to verify your identity.',
          style: DesignSystem.bodyMain,
        ),
        const SizedBox(height: 36),
        _buildGlassField(_emailController, 'Email Address', Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 32),
        _isLoading
            ? const Center(child: CircularProgressIndicator(color: DesignSystem.primaryAccent))
            : _buildPrimaryButton('Send OTP', _handleSendOtp),
      ],
    );
  }

  // ─── Step 2: OTP ───

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: DesignSystem.primaryGradient,
              boxShadow: [DesignSystem.neonShadow(DesignSystem.primaryAccent)],
            ),
            child: const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 44),
          ),
        ),
        const SizedBox(height: 28),
        Text('Check Your Email', style: DesignSystem.h1.copyWith(fontSize: 26)),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: DesignSystem.bodyMain,
            children: [
              const TextSpan(text: 'We sent a 6-digit OTP to '),
              TextSpan(
                text: _email,
                style: TextStyle(
                  color: DesignSystem.primaryAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) => _buildOtpBox(i)),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _isLoading ? null : () async {
              setState(() => _isLoading = true);
              await _authController.forgotPassword(_email);
              setState(() => _isLoading = false);
              _showSnack('OTP resent to $_email');
              for (final c in _otpControllers) c.clear();
              _otpFocusNodes[0].requestFocus();
            },
            child: Text(
              'Resend OTP',
              style: TextStyle(
                color: DesignSystem.primaryAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _isLoading
            ? const Center(child: CircularProgressIndicator(color: DesignSystem.primaryAccent))
            : _buildPrimaryButton('Verify OTP', _handleVerifyOtp),
      ],
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 46,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          color: DesignSystem.glassWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
        ),
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _otpFocusNodes[index],
          maxLength: 1,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: DesignSystem.textMain,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (val) {
            if (val.isNotEmpty && index < 5) {
              _otpFocusNodes[index + 1].requestFocus();
            } else if (val.isEmpty && index > 0) {
              _otpFocusNodes[index - 1].requestFocus();
            }
          },
        ),
      ),
    );
  }

  // ─── Step 3: New Password ───

  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: DesignSystem.primaryGradient,
              boxShadow: [DesignSystem.neonShadow(DesignSystem.primaryAccent)],
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 44),
          ),
        ),
        const SizedBox(height: 28),
        Text('New Password', style: DesignSystem.h1.copyWith(fontSize: 26)),
        const SizedBox(height: 8),
        Text(
          'Create a strong password with at least 6 characters.',
          style: DesignSystem.bodyMain,
        ),
        const SizedBox(height: 36),
        _buildGlassField(
          _newPasswordController,
          'New Password',
          Icons.lock_outline_rounded,
          isPassword: true,
          showPassword: _showNewPassword,
          onTogglePassword: () => setState(() => _showNewPassword = !_showNewPassword),
        ),
        const SizedBox(height: 20),
        _buildGlassField(
          _confirmPasswordController,
          'Confirm Password',
          Icons.lock_person_outlined,
          isPassword: true,
          showPassword: _showConfirmPassword,
          onTogglePassword: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
        ),
        const SizedBox(height: 32),
        _isLoading
            ? const Center(child: CircularProgressIndicator(color: DesignSystem.primaryAccent))
            : _buildPrimaryButton('Reset Password', _handleResetPassword),
        const SizedBox(height: 20),
      ],
    );
  }

  // ──────────────────────── Reusable widgets ──────────────────────────────────

  Widget _buildGlassField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
    bool showPassword = false,
    VoidCallback? onTogglePassword,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: DesignSystem.glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !showPassword,
        keyboardType: keyboardType,
        style: TextStyle(color: DesignSystem.textMain),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: DesignSystem.primaryAccent, size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: DesignSystem.textSub.withOpacity(0.6),
                    size: 20,
                  ),
                  onPressed: onTogglePassword,
                )
              : null,
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
      height: 58,
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

  Widget _blurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
