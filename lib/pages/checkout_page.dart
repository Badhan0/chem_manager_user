import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../theme/design_system.dart';
import '../services/api_service.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, dynamic> booking;
  final String doctorName;
  final String clinicName;
  final double amount;

  const CheckoutPage({
    super.key,
    required this.booking,
    required this.doctorName,
    required this.clinicName,
    required this.amount,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _selectedMethod = 'UPI'; // 'UPI', 'Card', 'NetBanking'
  final _cardFormKey = GlobalKey<FormState>();

  // Card details
  final _cardNumberController = TextEditingController(text: '4111 2222 3333 4444');
  final _expiryController = TextEditingController(text: '12/29');
  final _cvvController = TextEditingController(text: '123');
  final _nameController = TextEditingController(text: 'John Doe');

  // UPI details
  final _upiController = TextEditingController(text: 'patient@okaxis');
  String _selectedUpiApp = 'GPay'; // 'GPay', 'PhonePe', 'Paytm', 'Other'

  // NetBanking details
  String _selectedBank = 'SBI'; // 'SBI', 'HDFC', 'ICICI', 'Axis'

  bool _isProcessing = false;
  
  // Real Razorpay SDK variables
  late Razorpay _razorpay;
  bool _useRealSDK = true;
  final String _razorpayKey = 'rzp_test_T0EUrkSdY3dOxR'; // Prefilled with validated test credentials

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRealPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRealPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleRealExternalWallet);

    // Auto-launch Razorpay immediately when the checkout screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startRealRazorpayCheckout();
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  void _handleRealPaymentSuccess(PaymentSuccessResponse response) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final bookingId = widget.booking['_id'] ?? widget.booking['id'];
      
      // Update backend booking payment status
      final apiResponse = await ApiService.updateBookingPayment(bookingId, 'paid');
      
      setState(() {
        _isProcessing = false;
      });

      if (apiResponse.statusCode == 200 || apiResponse.statusCode == 201) {
        _showSuccessAnimation();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment verification on backend failed.')),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error registering payment status: $e')),
      );
    }
  }

  void _handleRealPaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Cancelled/Failed: ${response.message ?? "Error code: ${response.code}"}'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _handleRealExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet chosen: ${response.walletName}')),
    );
  }

  void _startRealRazorpayCheckout() {
    final bookingId = widget.booking['_id'] ?? widget.booking['id'] ?? 'N/A';
    final patientName = widget.booking['name'] ?? 'Patient';

    // Retrieve clinic/organization's connected account ID for routed split payout
    final org = widget.booking['orgId'];
    String? connectedAccountId;
    if (org != null && org is Map && org['paymentDetails'] != null) {
      connectedAccountId = org['paymentDetails']['connectedAccountId'];
    }

    print('💳 [Razorpay Route] Found connectedAccountId: $connectedAccountId');
    print('📞 [Razorpay SDK] Prefilling Phone: ${widget.booking['phone']}');
    print('📧 [Razorpay SDK] Prefilling Email: ${widget.booking['email']}');
    print('👤 [Razorpay SDK] Prefilling Name: $patientName');

    var options = {
      'key': _razorpayKey,
      'amount': (widget.amount * 100).toInt(), // Razorpay expects amount in paise
      'name': widget.clinicName,
      'description': 'Appointment Payment for ${widget.doctorName}',
      'prefill': {
        'contact': widget.booking['phone'] ?? '9999999999',
        'email': widget.booking['email'] ?? 'patient@example.com',
        'name': patientName,
      },
      'readonly': {
        'contact': true,
        'email': true,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    if (connectedAccountId != null && connectedAccountId.isNotEmpty) {
      options['transfers'] = [
        {
          'account': connectedAccountId,
          'amount': (widget.amount * 100).toInt(), // Route 100% of payment (or adjust for platform fee)
          'currency': 'INR'
        }
      ];
      print('🚀 [Razorpay Route] Split transfer added for Linked Account: $connectedAccountId');
    }

    try {
      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open Razorpay SDK: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingId = widget.booking['_id'] ?? widget.booking['id'] ?? 'N/A';
    final patientName = widget.booking['name'] ?? 'Patient';

    return Scaffold(
      backgroundColor: DesignSystem.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Razorpay Secure Checkout', style: DesignSystem.h2.copyWith(fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: DesignSystem.textMain),
          onPressed: () {
            if (!_isProcessing) {
              Navigator.pop(context, false);
            }
          },
        ),
      ),
      body: Stack(
        children: [
          // Background blurs
          Positioned(
            top: -50,
            right: -50,
            child: _buildBlurCircle(180, DesignSystem.primaryAccent.withOpacity(0.15)),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildBlurCircle(220, DesignSystem.secondaryAccent.withOpacity(0.12)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Razorpay Header Brand
                  _buildRazorpayHeader(),
                  const SizedBox(height: 20),

                  // Checkout Mode Toggle Card
                  _buildModeToggleCard(),
                  const SizedBox(height: 20),

                  // Order Summary Card
                  _buildOrderSummaryCard(bookingId, patientName),
                  const SizedBox(height: 24),

                  if (!_useRealSDK) ...[
                    Text(
                      'Select Payment Method (Simulation)',
                      style: DesignSystem.bodyBold.copyWith(color: DesignSystem.primaryAccent),
                    ),
                    const SizedBox(height: 12),

                    // Payment tabs
                    _buildPaymentTabs(),
                    const SizedBox(height: 20),

                    // Selected payment form
                    _buildPaymentForm(),
                    const SizedBox(height: 32),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                      decoration: DesignSystem.glassDecoration(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 45,
                            height: 45,
                            child: CircularProgressIndicator(
                              color: DesignSystem.primaryAccent,
                              strokeWidth: 4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Launching Secure Gateway...',
                            style: DesignSystem.bodyBold.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please wait. You are being redirected to Razorpay. If the popup does not open automatically, tap the button below.',
                            textAlign: TextAlign.center,
                            style: DesignSystem.bodyMain.copyWith(fontSize: 12, color: DesignSystem.textSub, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Submit Button
                  _buildPayButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Center(
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: DesignSystem.primaryAccent,
                            strokeWidth: 5,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Securing Transaction...',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: DesignSystem.textMain,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Verifying with Razorpay node & routing payout directly to clinic.',
                            textAlign: TextAlign.center,
                            style: DesignSystem.bodyMain.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
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
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildRazorpayHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Dark slate
        borderRadius: BorderRadius.circular(16),
        boxShadow: [DesignSystem.softShadow],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.network(
                'https://cdn.razorpay.com/static/assets/logo/payment_badge.png',
                height: 24,
                errorBuilder: (context, error, stackTrace) {
                  return Text(
                    '💳 Razorpay Secure',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  );
                },
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield, color: Colors.green, size: 12),
                const SizedBox(width: 4),
                Text(
                  '100% SECURE',
                  style: GoogleFonts.inter(
                    color: Colors.green,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(String bookingId, String patientName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: DesignSystem.glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Booking Summary',
                style: DesignSystem.bodyBold.copyWith(fontSize: 14, color: DesignSystem.textSub),
              ),
              Text(
                '#${bookingId.substring(bookingId.length - 6).toUpperCase()}',
                style: GoogleFonts.sourceCodePro(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: DesignSystem.primaryAccent,
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Colors.black12),
          const SizedBox(height: 4),
          _buildSummaryRow(Icons.person_outline, 'Doctor', widget.doctorName),
          const SizedBox(height: 10),
          _buildSummaryRow(Icons.local_hospital_outlined, 'Facility', widget.clinicName),
          const SizedBox(height: 10),
          _buildSummaryRow(Icons.badge_outlined, 'Patient', patientName),
          const Divider(height: 24, color: Colors.black12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Consulting Charge', style: DesignSystem.bodyBold),
              Text(
                '₹${widget.amount.toStringAsFixed(2)}',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: DesignSystem.primaryAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: DesignSystem.textSub.withOpacity(0.7)),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: DesignSystem.bodyMain.copyWith(fontSize: 13, color: DesignSystem.textSub),
        ),
        Expanded(
          child: Text(
            value,
            style: DesignSystem.bodyBold.copyWith(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentTabs() {
    return Row(
      children: [
        Expanded(child: _buildTabButton('UPI', Icons.phone_android_rounded)),
        const SizedBox(width: 8),
        Expanded(child: _buildTabButton('Card', Icons.credit_card_rounded)),
        const SizedBox(width: 8),
        Expanded(child: _buildTabButton('NetBanking', Icons.account_balance_rounded)),
      ],
    );
  }

  Widget _buildTabButton(String method, IconData icon) {
    final bool isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? DesignSystem.primaryAccent : DesignSystem.glassWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? DesignSystem.primaryAccent : Colors.white.withOpacity(0.6),
            width: 1.5,
          ),
          boxShadow: isSelected ? [DesignSystem.neonShadow(DesignSystem.primaryAccent)] : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : DesignSystem.textSub, size: 20),
            const SizedBox(height: 6),
            Text(
              method,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : DesignSystem.textSub,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    if (_selectedMethod == 'UPI') {
      return _buildUpiForm();
    } else if (_selectedMethod == 'Card') {
      return _buildCardForm();
    } else {
      return _buildNetBankingForm();
    }
  }

  Widget _buildUpiForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: DesignSystem.glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('UPI Payment Apps', style: DesignSystem.bodyBold.copyWith(fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildUpiAppButton('GPay', 'Google Pay'),
              _buildUpiAppButton('PhonePe', 'PhonePe'),
              _buildUpiAppButton('Paytm', 'Paytm'),
              _buildUpiAppButton('Other', 'Custom VPA'),
            ],
          ),
          if (_selectedUpiApp == 'Other') ...[
            const SizedBox(height: 20),
            _buildTextField(
              controller: _upiController,
              hint: 'Enter UPI ID (e.g. user@okaxis)',
              icon: Icons.alternate_email,
              validator: (val) => val!.isEmpty || !val.contains('@') ? 'Enter a valid UPI ID' : null,
            ),
          ] else ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flash_on, color: Colors.blue, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You will receive a payment request on your $_selectedUpiApp App.',
                      style: DesignSystem.bodyMain.copyWith(fontSize: 12, color: DesignSystem.textSub),
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildUpiAppButton(String appName, String fullName) {
    final bool isSelected = _selectedUpiApp == appName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUpiApp = appName;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? DesignSystem.primaryAccent.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? DesignSystem.primaryAccent : Colors.black12,
            width: 1.5,
          ),
        ),
        child: Text(
          appName,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: isSelected ? DesignSystem.primaryAccent : DesignSystem.textSub,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: DesignSystem.glassDecoration(),
      child: Form(
        key: _cardFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Card Details', style: DesignSystem.bodyBold.copyWith(fontSize: 14)),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _cardNumberController,
              hint: 'Card Number',
              icon: Icons.credit_card,
              keyboard: TextInputType.number,
              validator: (val) => val!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _expiryController,
                    hint: 'MM/YY',
                    icon: Icons.date_range,
                    keyboard: TextInputType.datetime,
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _cvvController,
                    hint: 'CVV',
                    icon: Icons.lock_outline,
                    keyboard: TextInputType.number,
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _nameController,
              hint: 'Cardholder Name',
              icon: Icons.person_outline,
              validator: (val) => val!.isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetBankingForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: DesignSystem.glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Popular Banks', style: DesignSystem.bodyBold.copyWith(fontSize: 14)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              _buildBankCard('SBI', 'State Bank of India', Icons.account_balance),
              _buildBankCard('HDFC', 'HDFC Bank', Icons.account_balance),
              _buildBankCard('ICICI', 'ICICI Bank', Icons.account_balance),
              _buildBankCard('Axis', 'Axis Bank', Icons.account_balance),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBankCard(String bankCode, String bankName, IconData icon) {
    final bool isSelected = _selectedBank == bankCode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBank = bankCode;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? DesignSystem.primaryAccent.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? DesignSystem.primaryAccent : Colors.black12,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? DesignSystem.primaryAccent : DesignSystem.textSub, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                bankName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: isSelected ? DesignSystem.primaryAccent : DesignSystem.textMain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    required String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: DesignSystem.glassWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboard,
        style: TextStyle(color: DesignSystem.textMain),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: DesignSystem.textSub.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: DesignSystem.primaryAccent, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildPayButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: DesignSystem.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [DesignSystem.neonShadow(DesignSystem.primaryAccent)],
      ),
      child: ElevatedButton(
        onPressed: _startPaymentFlow,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          'PAY ₹${widget.amount.toStringAsFixed(2)} NOW',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  void _startPaymentFlow() {
    if (_useRealSDK) {
      _startRealRazorpayCheckout();
    } else {
      if (_selectedMethod == 'Card') {
        if (!_cardFormKey.currentState!.validate()) return;
      }
      _showOTPDialog();
    }
  }

  void _showOTPDialog() {
    final otpController = TextEditingController(text: '123456');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                backgroundColor: Colors.white,
                title: Row(
                  children: [
                    Image.network(
                      'https://cdn.razorpay.com/static/assets/logo/payment_badge.png',
                      height: 20,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.security, color: Colors.blue),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '3D Secure OTP',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter the OTP sent to your registered mobile number for verifying this payment to ${widget.doctorName}.',
                      style: DesignSystem.bodyMain.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '******',
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close OTP Dialog
                    },
                    child: Text('CANCEL', style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context); // Close OTP Dialog
                      await _completePayment();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignSystem.primaryAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text('SUBMIT OTP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _completePayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final bookingId = widget.booking['_id'] ?? widget.booking['id'];
      
      // Call Backend to update booking status to 'paid'
      final response = await ApiService.updateBookingPayment(bookingId, 'paid');
      
      setState(() {
        _isProcessing = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessAnimation();
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Payment registration failed.')),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment connection error: $e')),
      );
    }
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.white,
            content: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 80,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Payment Success!',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your payment of ₹${widget.amount.toStringAsFixed(2)} was split and routed directly to the clinic account via Razorpay.',
                    textAlign: TextAlign.center,
                    style: DesignSystem.bodyMain.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: DesignSystem.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close Success dialog
                        Navigator.pop(context, true); // Pop back true to form
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'DONE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeToggleCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: DesignSystem.glassDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                _useRealSDK ? Icons.bolt_rounded : Icons.terminal_rounded,
                color: _useRealSDK ? Colors.amber : DesignSystem.primaryAccent,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _useRealSDK ? 'Real Razorpay SDK Mode' : 'Demo Simulator Mode',
                    style: DesignSystem.bodyBold.copyWith(fontSize: 14),
                  ),
                  Text(
                    _useRealSDK ? 'Launches official payment gateway' : 'Simulates bank checkout natively',
                    style: DesignSystem.bodyMain.copyWith(fontSize: 11, color: DesignSystem.textSub),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: _useRealSDK,
            onChanged: (val) {
              setState(() {
                _useRealSDK = val;
              });
            },
            activeColor: DesignSystem.primaryAccent,
          ),
        ],
      ),
    );
  }
}
