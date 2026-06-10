import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/design_system.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home_page.dart';
class EditProfilePage extends StatefulWidget {
  final bool isMandatoryProfileSetup;
  const EditProfilePage({super.key, this.isMandatoryProfileSetup = false});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  DateTime? _selectedDob;
  String _gender = 'Male';
  int? _calculatedAge;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCachedProfile();
  }

  void _loadCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? '';
      _phoneController.text = prefs.getString('user_phone') ?? '';
      if (_phoneController.text == 'Not Provided') {
        _phoneController.text = '';
      }
      _gender = prefs.getString('user_gender') ?? 'Male';
      
      final dobStr = prefs.getString('user_dob');
      if (dobStr != null && dobStr.isNotEmpty) {
        try {
          _selectedDob = DateTime.parse(dobStr);
          _calculatedAge = _calculateAge(_selectedDob!);
        } catch (_) {}
      }
    });
  }

  int _calculateAge(DateTime dob) {
    DateTime today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _selectDob(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 110)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: DesignSystem.primaryAccent,
              onPrimary: Colors.white,
              onSurface: DesignSystem.textMain,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
        _calculatedAge = _calculateAge(picked);
      });
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.updateProfile({
        'name': _nameController.text.trim(),
        'dob': _selectedDob?.toIso8601String() ?? '',
        'gender': _gender,
        'phone': _phoneController.text.trim(),
      });

      final resData = jsonDecode(response.body);
      setState(() => _isLoading = false);

      if (response.statusCode == 200 && resData['success']) {
        final prefs = await SharedPreferences.getInstance();
        final user = resData['user'];
        await prefs.setString('user_name', user['name'] ?? '');
        if (user['dob'] != null) {
          await prefs.setString('user_dob', user['dob']);
        }
        if (user['gender'] != null) {
          await prefs.setString('user_gender', user['gender']);
        }
        if (user['phone'] != null) {
          await prefs.setString('user_phone', user['phone']);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully.')),
        );
        
        if (widget.isMandatoryProfileSetup) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        } else {
          Navigator.pop(context, true); // Go back and refresh profile
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resData['message'] ?? 'Failed to update profile.')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dobDisplay = _selectedDob == null
        ? 'Select Date of Birth'
        : "${_selectedDob!.day.toString().padLeft(2, '0')}/${_selectedDob!.month.toString().padLeft(2, '0')}/${_selectedDob!.year}";

    return PopScope(
      canPop: !widget.isMandatoryProfileSetup,
      child: Scaffold(
        backgroundColor: DesignSystem.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Edit Profile Details', style: DesignSystem.h2),
          automaticallyImplyLeading: !widget.isMandatoryProfileSetup,
          leading: widget.isMandatoryProfileSetup
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: DesignSystem.textMain),
                  onPressed: () => Navigator.pop(context),
                ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      'Demographic Details',
                      style: DesignSystem.bodyBold.copyWith(color: DesignSystem.primaryAccent),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(_nameController, 'Full Name', Icons.person, (val) => val!.isEmpty ? 'Name required' : null),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _phoneController,
                      'Phone Number (Mandatory)',
                      Icons.phone,
                      (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Phone number is mandatory';
                        }
                        final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
                        if (!phoneRegex.hasMatch(val.trim())) {
                          return 'Enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDateButton(dobDisplay),
                  if (_calculatedAge != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        'Calculated Age: $_calculatedAge years old',
                        style: TextStyle(color: DesignSystem.primaryAccent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildGenderDropdown(),
                  const SizedBox(height: 40),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator(color: DesignSystem.primaryAccent)),
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon,
    String? Function(String?)? validator,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: DesignSystem.glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
        boxShadow: [DesignSystem.softShadow],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        style: TextStyle(color: DesignSystem.textMain),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: DesignSystem.textSub.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: DesignSystem.primaryAccent),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDateButton(String display) {
    return GestureDetector(
      onTap: () => _selectDob(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DesignSystem.glassWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
          boxShadow: [DesignSystem.softShadow],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.cake, color: DesignSystem.primaryAccent),
                const SizedBox(width: 12),
                Text(display, style: DesignSystem.bodyBold),
              ],
            ),
            const Icon(Icons.arrow_drop_down, color: DesignSystem.textSub),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: DesignSystem.glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
        boxShadow: [DesignSystem.softShadow],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _gender,
          decoration: const InputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(Icons.wc, color: DesignSystem.primaryAccent),
          ),
          onChanged: (String? val) {
            if (val != null) setState(() => _gender = val);
          },
          items: const [
            DropdownMenuItem(value: 'Male', child: Text('Male')),
            DropdownMenuItem(value: 'Female', child: Text('Female')),
            DropdownMenuItem(value: 'Other', child: Text('Other')),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: DesignSystem.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [DesignSystem.neonShadow(DesignSystem.primaryAccent)],
      ),
      child: ElevatedButton(
        onPressed: _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text(
          'SAVE PROFILE',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1),
        ),
      ),
    );
  }
}
