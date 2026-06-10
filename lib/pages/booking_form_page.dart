import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/design_system.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingFormPage extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String specialty;
  final String doctorPhoto;
  final String clinicId;
  final String clinicName;
  final String clinicLocation;
  final List<dynamic> slots;

  const BookingFormPage({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.doctorPhoto,
    required this.clinicId,
    required this.clinicName,
    required this.clinicLocation,
    required this.slots,
  });

  @override
  _BookingFormPageState createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<BookingFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _bpController = TextEditingController();
  final TextEditingController _issueController = TextEditingController();

  String _gender = 'Male';
  DateTime? _selectedDate;
  String? _selectedSlot;
  bool _isLoading = false;

  List<dynamic> _availableSlots = [];
  Map<String, int> _slotOccupancy = {};
  bool _isLoadingOccupancy = false;

  @override
  void initState() {
    super.initState();
    _loadPatientDefaultData();
  }

  void _loadPatientDefaultData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? '';
      _phoneController.text = prefs.getString('user_phone') ?? '';
      
      final savedGender = prefs.getString('user_gender');
      if (savedGender != null && (savedGender == 'Male' || savedGender == 'Female' || savedGender == 'Other')) {
        _gender = savedGender;
      }
      
      final dobStr = prefs.getString('user_dob');
      if (dobStr != null && dobStr.isNotEmpty) {
        try {
          final dob = DateTime.parse(dobStr);
          DateTime today = DateTime.now();
          int age = today.year - dob.year;
          if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
            age--;
          }
          _ageController.text = age.toString();
        } catch (_) {}
      }
    });
  }

  Future<void> _fetchSlotOccupancy(DateTime date) async {
    setState(() {
      _isLoadingOccupancy = true;
      _slotOccupancy.clear();
    });

    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    try {
      final response = await ApiService.getSlotOccupancy(widget.doctorId, widget.clinicId, dateStr);
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['success']) {
          final Map<String, dynamic> data = resData['data'] ?? {};
          final Map<String, int> parsed = {};
          data.forEach((k, v) {
            parsed[k] = int.tryParse(v.toString()) ?? 0;
          });
          setState(() {
            _slotOccupancy = parsed;
          });
        }
      }
    } catch (e) {
      print('Error loading slot occupancy: $e');
    } finally {
      setState(() {
        _isLoadingOccupancy = false;
      });
    }
  }

  // Find slots matching the selected day of the week
  void _updateSlotsForDate(DateTime date) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    String selectedDay = weekdays[date.weekday - 1];

    setState(() {
      _availableSlots = widget.slots.where((s) => s['day'] == selectedDay).toList();
      _selectedSlot = null; // Reset selection
    });

    _fetchSlotOccupancy(date);
  }

  DateTime _findFirstSelectableDate() {
    final Map<int, String> weekdaysMap = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };
    
    DateTime date = DateTime.now();
    // Check up to 90 days ahead
    for (int i = 0; i < 90; i++) {
      final String? dayName = weekdaysMap[date.weekday];
      final bool visitsOnThisDay = widget.slots.any((s) => s['day'] == dayName);
      if (visitsOnThisDay) {
        return date;
      }
      date = date.add(const Duration(days: 1));
    }
    return DateTime.now().add(const Duration(days: 1));
  }

  Future<void> _selectDate(BuildContext context) async {
    final Map<int, String> weekdaysMap = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };

    final DateTime initial = _findFirstSelectableDate();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      selectableDayPredicate: (DateTime date) {
        if (widget.slots.isEmpty) return true;
        final String? dayName = weekdaysMap[date.weekday];
        return widget.slots.any((s) => s['day'] == dayName);
      },
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

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _updateSlotsForDate(picked);
    }
  }

  void _submitBooking(String paymentMode) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an appointment date.')),
      );
      return;
    }
    if (_availableSlots.isNotEmpty && _selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dateStr = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";

      final response = await ApiService.createBooking({
        'orgId': widget.clinicId,
        'doctorId': widget.doctorId,
        'name': _nameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'gender': _gender,
        'phone': _phoneController.text.trim(),
        'weight': _weightController.text.trim(),
        'bp': _bpController.text.trim(),
        'appointmentDate': dateStr,
        'appointmentTime': _selectedSlot ?? '',
        'issueDetails': _issueController.text.trim(),
        'paymentMode': paymentMode,
        'paymentStatus': 'pending',
      });

      final data = jsonDecode(response.body);

      setState(() => _isLoading = false);

      if (response.statusCode == 201) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Booking failed.')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: $e')),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: DesignSystem.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 8),
              Text('Booking Confirmed', style: DesignSystem.h2),
            ],
          ),
          content: Text(
            'Your slot has been registered. You can review and track your visit in the Doctor Visits tab on your dashboard.',
            style: DesignSystem.bodyMain,
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                gradient: DesignSystem.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close form page
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('DISMISS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateDisplay = _selectedDate == null
        ? 'Select Appointment Date'
        : "${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}";

    return Scaffold(
      backgroundColor: DesignSystem.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Schedule Appointment', style: DesignSystem.h2),
        leading: IconButton(
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
                  _buildSummaryHeader(),
                  const SizedBox(height: 28),
                  Text('Patient Specifications', style: DesignSystem.bodyBold.copyWith(color: DesignSystem.primaryAccent)),
                  const SizedBox(height: 12),
                  _buildTextField(_nameController, 'Patient Full Name', Icons.person, (val) => val!.isEmpty ? 'Name required' : null),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(_ageController, 'Age', Icons.calendar_today, (val) => val!.isEmpty ? 'Age required' : null, keyboard: TextInputType.number),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _buildGenderDropdown()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(_phoneController, 'Phone Number', Icons.phone, (val) => val!.isEmpty ? 'Phone required' : null, keyboard: TextInputType.phone),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(_weightController, 'Weight (e.g. 72 kg)', Icons.line_weight, null),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(_bpController, 'BP (e.g. 120/80)', Icons.speed, null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Booking Details', style: DesignSystem.bodyBold.copyWith(color: DesignSystem.primaryAccent)),
                  const SizedBox(height: 12),
                  _buildDateButton(dateDisplay),
                  if (_selectedDate != null) ...[
                    const SizedBox(height: 16),
                    Text('Available Slots', style: DesignSystem.bodyBold),
                    const SizedBox(height: 8),
                    _buildSlotsSection(),
                  ],
                  const SizedBox(height: 16),
                  _buildTextField(_issueController, 'Symptoms / Reasons for Visit', Icons.notes, null, maxLines: 3),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                  const SizedBox(height: 40),
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
    );
  }

  Widget _buildSummaryHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DesignSystem.glassWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
            boxShadow: [DesignSystem.softShadow],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: DesignSystem.primaryAccent.withOpacity(0.12),
                    backgroundImage: widget.doctorPhoto.isNotEmpty ? NetworkImage(widget.doctorPhoto) : null,
                    child: widget.doctorPhoto.isEmpty ? const Icon(Icons.person, color: DesignSystem.primaryAccent) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.doctorName, style: DesignSystem.bodyBold),
                        Text(widget.specialty, style: DesignSystem.bodyMain),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: Colors.black12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: DesignSystem.secondaryAccent.withOpacity(0.12), shape: BoxShape.circle),
                    child: const Icon(Icons.local_hospital, color: DesignSystem.secondaryAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.clinicName, style: DesignSystem.bodyBold.copyWith(fontSize: 13)),
                        Text(widget.clinicLocation, style: DesignSystem.bodyMain.copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon,
    String? Function(String?)? validator, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
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
        keyboardType: keyboard,
        maxLines: maxLines,
        style: TextStyle(color: DesignSystem.textMain),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: DesignSystem.textSub.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: DesignSystem.primaryAccent),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget _buildDateButton(String display) {
    return GestureDetector(
      onTap: () => _selectDate(context),
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
                const Icon(Icons.date_range, color: DesignSystem.primaryAccent),
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

  Widget _buildSlotsSection() {
    if (_isLoadingOccupancy) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(color: DesignSystem.primaryAccent),
        ),
      );
    }

    if (_availableSlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Doctor does not visit this clinic on the selected weekday. Please choose a different date.',
          style: TextStyle(color: Colors.orange.shade800, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _availableSlots.length,
      itemBuilder: (context, index) {
        final slot = _availableSlots[index];
        final slotText = "${slot['startTime']} - ${slot['endTime']}";
        final maxPatients = int.tryParse(slot['maxPatients']?.toString() ?? '') ?? 0;
        final bookedCount = _slotOccupancy[slotText] ?? 0;
        
        final bool isSelected = _selectedSlot == slotText;
        final bool isFull = maxPatients > 0 && bookedCount >= maxPatients;
        final slotsLeft = maxPatients - bookedCount;

        Color cardBorderColor = Colors.white.withOpacity(0.6);
        Color cardBgColor = DesignSystem.glassWhite;
        Color textColor = DesignSystem.textMain;

        if (isFull) {
          cardBgColor = Colors.red.withOpacity(0.05);
          cardBorderColor = Colors.red.withOpacity(0.2);
          textColor = Colors.red.shade400;
        } else if (isSelected) {
          cardBgColor = DesignSystem.primaryAccent.withOpacity(0.12);
          cardBorderColor = DesignSystem.primaryAccent;
          textColor = DesignSystem.primaryAccent;
        }

        return GestureDetector(
          onTap: isFull
              ? null
              : () {
                  setState(() {
                    _selectedSlot = slotText;
                  });
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorderColor, width: 1.5),
              boxShadow: isSelected ? [DesignSystem.softShadow] : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: isFull ? Colors.red.shade300 : DesignSystem.primaryAccent,
                    ),
                    if (maxPatients > 0)
                      Text(
                        isFull ? "FULL" : "$slotsLeft left",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isFull ? Colors.red.shade600 : Colors.green.shade700,
                        ),
                      )
                    else
                      Text(
                        "Available",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    slotText,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPaymentSelectorSheet() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an appointment date.')),
      );
      return;
    }
    if (_availableSlots.isNotEmpty && _selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot.')),
      );
      return;
    }

    String selectedPaymentMethod = 'hand'; // Default

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 32, bottom: 40),
                decoration: BoxDecoration(
                  color: DesignSystem.cardBackground.withOpacity(0.95),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: DesignSystem.textSub.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Payment Method',
                      style: DesignSystem.h2,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select how you would like to pay for your doctor visit.',
                      style: DesignSystem.bodyMain.copyWith(color: DesignSystem.textSub),
                    ),
                    const SizedBox(height: 24),
                    
                    // Online Payment Option
                    GestureDetector(
                      onTap: () {
                        setSheetState(() {
                          selectedPaymentMethod = 'online';
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Online payment gateway will be integrated later. Please select Pay on Hand.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: selectedPaymentMethod == 'online'
                              ? DesignSystem.primaryAccent.withOpacity(0.08)
                              : DesignSystem.glassWhite,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selectedPaymentMethod == 'online'
                                ? DesignSystem.primaryAccent
                                : Colors.white.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.credit_card_rounded, color: Colors.blue),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Online Payment',
                                    style: DesignSystem.bodyBold,
                                  ),
                                  Text(
                                    'Pay via UPI, Cards, or NetBanking',
                                    style: DesignSystem.bodyMain.copyWith(
                                      fontSize: 12,
                                      color: DesignSystem.textSub,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Radio<String>(
                              value: 'online',
                              groupValue: selectedPaymentMethod,
                              activeColor: DesignSystem.primaryAccent,
                              onChanged: (val) {
                                if (val != null) {
                                  setSheetState(() {
                                    selectedPaymentMethod = val;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Pay on Hand Option
                    GestureDetector(
                      onTap: () {
                        setSheetState(() {
                          selectedPaymentMethod = 'hand';
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: selectedPaymentMethod == 'hand'
                              ? DesignSystem.primaryAccent.withOpacity(0.08)
                              : DesignSystem.glassWhite,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selectedPaymentMethod == 'hand'
                                ? DesignSystem.primaryAccent
                                : Colors.white.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.payments_rounded, color: Colors.green),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pay on Hand',
                                    style: DesignSystem.bodyBold,
                                  ),
                                  Text(
                                    'Pay in cash/hand directly at the clinic',
                                    style: DesignSystem.bodyMain.copyWith(
                                      fontSize: 12,
                                      color: DesignSystem.textSub,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Radio<String>(
                              value: 'hand',
                              groupValue: selectedPaymentMethod,
                              activeColor: DesignSystem.primaryAccent,
                              onChanged: (val) {
                                if (val != null) {
                                  setSheetState(() {
                                    selectedPaymentMethod = val;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Proceed Button
                    Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: DesignSystem.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          DesignSystem.neonShadow(DesignSystem.primaryAccent)
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close sheet
                          if (selectedPaymentMethod == 'hand') {
                            _submitBooking('hand');
                          } else {
                            // Prompt warning and proceed with hand payment
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Online payments are unavailable. Proceeding with Pay on Hand instead.'),
                              ),
                            );
                            _submitBooking('hand');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          selectedPaymentMethod == 'hand'
                              ? 'PROCEED & BOOK'
                              : 'INTEGRATE LATER & BOOK',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: DesignSystem.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [DesignSystem.neonShadow(DesignSystem.primaryAccent)],
      ),
      child: ElevatedButton(
        onPressed: _showPaymentSelectorSheet,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text(
          'CONFIRM & PAY',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1),
        ),
      ),
    );
  }
}
