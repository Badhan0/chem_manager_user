import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/design_system.dart';
import '../services/api_service.dart';
import 'booking_form_page.dart';

class ClinicDoctorsPage extends StatefulWidget {
  final String clinicId;
  final String clinicName;
  final String location;

  const ClinicDoctorsPage({
    super.key,
    required this.clinicId,
    required this.clinicName,
    required this.location,
  });

  @override
  _ClinicDoctorsPageState createState() => _ClinicDoctorsPageState();
}

class _ClinicDoctorsPageState extends State<ClinicDoctorsPage> {
  List<dynamic> _doctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    try {
      final response = await ApiService.getClinicDoctors(widget.clinicId);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _doctors = data['data'];
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching clinic doctors: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Visiting Specialists', style: DesignSystem.h2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: DesignSystem.textMain),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildClinicHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: DesignSystem.primaryAccent))
                : _doctors.isEmpty
                    ? Center(
                        child: Text(
                          'No doctors registered for this clinic.',
                          style: TextStyle(color: DesignSystem.textSub.withOpacity(0.5), fontWeight: FontWeight.bold),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: _doctors.length,
                        itemBuilder: (context, index) {
                          final doc = _doctors[index];
                          return _buildDoctorCard(doc);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: ClipRRect(
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: DesignSystem.secondaryAccent.withOpacity(0.12), shape: BoxShape.circle),
                  child: const Icon(Icons.local_hospital, color: DesignSystem.secondaryAccent, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.clinicName, style: DesignSystem.h2.copyWith(fontSize: 18)),
                      Text(widget.location, style: DesignSystem.bodyMain.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doc) {
    final List<dynamic> slots = doc['slots'] ?? [];
    final String photo = doc['photoURL'] ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DesignSystem.glassWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
            boxShadow: [DesignSystem.softShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: DesignSystem.primaryAccent.withOpacity(0.12),
                    backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                    child: photo.isEmpty ? const Icon(Icons.person, color: DesignSystem.primaryAccent, size: 24) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc['name'] ?? 'Doctor', style: DesignSystem.bodyBold),
                        Text(doc['specialty'] ?? 'General Physician', style: DesignSystem.bodyMain),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(doc['rating']?.toString() ?? '4.5', style: DesignSystem.bodyBold.copyWith(fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24, color: Colors.black12),
              Text('Visiting Timings:', style: DesignSystem.bodyBold.copyWith(fontSize: 12, color: DesignSystem.primaryAccent)),
              const SizedBox(height: 8),
              if (slots.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text('Timing schedules not set yet.', style: TextStyle(color: Colors.black38, fontSize: 12)),
                )
              else
                ...slots.map((slot) => _buildSlotRow(slot)),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: DesignSystem.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [DesignSystem.neonShadow(DesignSystem.primaryAccent)],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingFormPage(
                            doctorId: doc['id'] ?? '',
                            doctorName: doc['name'] ?? 'Doctor',
                            specialty: doc['specialty'] ?? 'General Physician',
                            doctorPhoto: photo,
                            clinicId: widget.clinicId,
                            clinicName: widget.clinicName,
                            clinicLocation: widget.location,
                            slots: slots,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text(
                      'BOOK VISIT',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotRow(Map<String, dynamic> slot) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          const Icon(Icons.circle, color: DesignSystem.primaryAccent, size: 6),
          const SizedBox(width: 8),
          Text(
            "${slot['day']}: ",
            style: DesignSystem.bodyBold.copyWith(fontSize: 12),
          ),
          Text(
            "${slot['startTime']} - ${slot['endTime']}",
            style: DesignSystem.bodyMain.copyWith(fontSize: 12),
          ),
          if (slot['maxPatients'] != null && slot['maxPatients'] != '0')
            Text(
              " (Max ${slot['maxPatients']})",
              style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}
