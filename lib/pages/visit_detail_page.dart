import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/design_system.dart';
import 'checkout_page.dart';

class VisitDetailPage extends StatefulWidget {
  final Map<String, dynamic> booking;

  const VisitDetailPage({super.key, required this.booking});

  @override
  State<VisitDetailPage> createState() => _VisitDetailPageState();
}

class _VisitDetailPageState extends State<VisitDetailPage> {
  late Map<String, dynamic> _booking;

  @override
  void initState() {
    super.initState();
    _booking = Map<String, dynamic>.from(widget.booking);
  }

  @override
  Widget build(BuildContext context) {
    // Extract populated fields safely
    final doctor = _booking['doctorId'];
    final clinic = _booking['orgId'];

    final doctorName = doctor is Map ? (doctor['name'] ?? 'Doctor') : 'Doctor';
    final doctorSpecialty = doctor is Map ? (doctor['specialization'] ?? 'Specialist') : 'Specialist';
    final doctorPhoto = doctor is Map ? (doctor['photoURL'] ?? '') : '';

    final clinicName = clinic is Map ? (clinic['name'] ?? 'Clinic') : 'Clinic';
    final clinicLocation = clinic is Map
        ? (clinic['locationDetails']?['fullAddress'] ?? clinic['locationDetails']?['city'] ?? 'Location')
        : 'Location';

    // Parse appointmentDate
    String formattedDate = 'Date pending';
    if (_booking['appointmentDate'] != null) {
      try {
        final parsedDate = DateTime.parse(_booking['appointmentDate']);
        formattedDate = "${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}";
      } catch (_) {}
    }

    final appointmentTime = _booking['appointmentTime'] ?? 'Timing pending';
    final status = _booking['status'] ?? 'pending';
    final patientName = _booking['name'] ?? 'Patient';
    final age = _booking['age']?.toString() ?? 'N/A';
    final gender = _booking['gender'] ?? 'N/A';
    final phone = _booking['phone'] ?? 'N/A';
    final weight = _booking['weight'] ?? 'N/A';
    final bp = _booking['bp'] ?? 'N/A';
    final issueDetails = _booking['issueDetails'] ?? 'No descriptions provided';
    final notes = _booking['notes'] ?? '';
    final paymentMode = _booking['paymentMode'] ?? 'Pay on hand';
    final paymentStatus = _booking['paymentStatus'] ?? 'pending';

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'visited':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'not_visited':
        statusColor = Colors.redAccent;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = Colors.amber.shade700;
        statusIcon = Icons.watch_later_outlined;
    }

    return Scaffold(
      backgroundColor: DesignSystem.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Visit Details', style: DesignSystem.h2),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: DesignSystem.textMain, size: 20),
        ),
      ),
      body: Stack(
        children: [
          // Background Blurs
          Positioned(
            top: -100,
            right: -50,
            child: _buildBlurCircle(200, DesignSystem.primaryAccent.withOpacity(0.15)),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildBlurCircle(250, DesignSystem.secondaryAccent.withOpacity(0.12)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & Date Card
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, color: DesignSystem.primaryAccent, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  formattedDate,
                                  style: DesignSystem.bodyBold.copyWith(color: DesignSystem.primaryAccent, fontSize: 16),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, color: statusColor, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: DesignSystem.textSub, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              appointmentTime,
                              style: DesignSystem.bodyMain.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Doctor Card
                  Text('Practitioner Details', style: DesignSystem.bodyBold.copyWith(color: DesignSystem.primaryAccent)),
                  const SizedBox(height: 8),
                  _buildGlassCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: DesignSystem.primaryAccent.withOpacity(0.1),
                          backgroundImage: doctorPhoto.isNotEmpty ? NetworkImage(doctorPhoto) : null,
                          child: doctorPhoto.isEmpty ? const Icon(Icons.person, color: DesignSystem.primaryAccent, size: 30) : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(doctorName, style: DesignSystem.bodyBold.copyWith(fontSize: 18)),
                              const SizedBox(height: 4),
                              Text(doctorSpecialty, style: DesignSystem.bodyMain.copyWith(color: DesignSystem.textSub, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Clinic Card
                  Text('Facility Details', style: DesignSystem.bodyBold.copyWith(color: DesignSystem.primaryAccent)),
                  const SizedBox(height: 8),
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_hospital, color: DesignSystem.secondaryAccent, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(clinicName, style: DesignSystem.bodyBold.copyWith(fontSize: 16)),
                            ),
                          ],
                        ),
                        if (clinicLocation.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 30.0),
                            child: Text(
                              clinicLocation,
                              style: DesignSystem.bodyMain.copyWith(color: DesignSystem.textSub.withOpacity(0.8), fontSize: 13),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Patient Card
                  Text('Patient Profile', style: DesignSystem.bodyBold.copyWith(color: DesignSystem.primaryAccent)),
                  const SizedBox(height: 8),
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileRow(Icons.person_outline, 'Name', patientName),
                        const Divider(height: 16, color: Colors.black12),
                        Row(
                          children: [
                            Expanded(child: _buildProfileRow(Icons.cake_outlined, 'Age', age)),
                            Expanded(child: _buildProfileRow(Icons.face_unlock_sharp, 'Gender', gender)),
                          ],
                        ),
                        const Divider(height: 16, color: Colors.black12),
                        _buildProfileRow(Icons.phone_android, 'Phone', phone),
                        const Divider(height: 16, color: Colors.black12),
                        Row(
                          children: [
                            Expanded(child: _buildProfileRow(Icons.monitor_weight_outlined, 'Weight', weight.isNotEmpty && weight != 'N/A' ? '$weight kg' : 'N/A')),
                            Expanded(child: _buildProfileRow(Icons.biotech, 'Blood Pressure', bp)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Symptoms Card
                  Text('Symptoms & Description', style: DesignSystem.bodyBold.copyWith(color: DesignSystem.primaryAccent)),
                  const SizedBox(height: 8),
                  _buildGlassCard(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.description_outlined, color: DesignSystem.secondaryAccent, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  issueDetails,
                                  style: DesignSystem.bodyMain.copyWith(
                                    fontSize: 14,
                                    color: DesignSystem.textMain,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Doctor Notes Section
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('Medical Practitioner Notes', style: DesignSystem.bodyBold.copyWith(color: Colors.green)),
                    const SizedBox(height: 8),
                    _buildGlassCard(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.note_alt_outlined, color: Colors.green, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                notes,
                                style: DesignSystem.bodyMain.copyWith(
                                  fontSize: 14,
                                  color: DesignSystem.textMain,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Payment Details Card
                  Text('Billing Information', style: DesignSystem.bodyBold.copyWith(color: DesignSystem.primaryAccent)),
                  const SizedBox(height: 8),
                  _buildGlassCard(
                    child: Column(
                      children: [
                        _buildProfileRow(Icons.payment, 'Payment Mode', paymentMode),
                        const Divider(height: 16, color: Colors.black12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: DesignSystem.textSub, size: 18),
                                const SizedBox(width: 10),
                                Text('Payment Status', style: DesignSystem.bodyMain.copyWith(color: DesignSystem.textSub, fontSize: 13)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (paymentStatus.toLowerCase() == 'completed' || paymentStatus.toLowerCase() == 'paid')
                                    ? Colors.green.withOpacity(0.12)
                                    : Colors.amber.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                paymentStatus.toUpperCase(),
                                style: TextStyle(
                                  color: (paymentStatus.toLowerCase() == 'completed' || paymentStatus.toLowerCase() == 'paid')
                                      ? Colors.green
                                      : Colors.amber.shade800,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (paymentMode.toLowerCase() == 'online' && 
                      (paymentStatus.toLowerCase() == 'pending' || paymentStatus.toLowerCase() == 'unpaid')) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: DesignSystem.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [DesignSystem.neonShadow(DesignSystem.primaryAccent)],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          final bool? paid = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CheckoutPage(
                                booking: _booking,
                                doctorName: doctorName,
                                clinicName: clinicName,
                                amount: 500.0,
                              ),
                            ),
                          );
                          if (paid == true) {
                            setState(() {
                              _booking['paymentStatus'] = 'paid';
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payment_rounded, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'PAY ONLINE NOW (₹500)',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
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
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: DesignSystem.glassWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
            boxShadow: [DesignSystem.softShadow],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: DesignSystem.textSub, size: 18),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: DesignSystem.bodyMain.copyWith(color: DesignSystem.textSub, fontSize: 11)),
            const SizedBox(height: 2),
            Text(value, style: DesignSystem.bodyBold.copyWith(fontSize: 14)),
          ],
        ),
      ],
    );
  }
}
