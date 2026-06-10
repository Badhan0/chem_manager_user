import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/design_system.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'visit_detail_page.dart';

class VisitHistoryPage extends StatefulWidget {
  final bool isEmbedded;
  const VisitHistoryPage({super.key, this.isEmbedded = false});

  @override
  _VisitHistoryPageState createState() => _VisitHistoryPageState();
}

class _VisitHistoryPageState extends State<VisitHistoryPage> {
  List<dynamic> _historyBookings = [];
  bool _isLoading = true;
  String? _phone;

  @override
  void initState() {
    super.initState();
    _loadUserPhoneAndFetchBookings();
  }

  Future<void> _loadUserPhoneAndFetchBookings() async {
    final prefs = await SharedPreferences.getInstance();
    _phone = prefs.getString('user_phone');
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getBookings(phone: _phone);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // Filter only visited and not_visited bookings
        final history = data.where((booking) {
          final status = (booking['status'] ?? 'pending').toString().toLowerCase();
          return status == 'visited' || status == 'not_visited';
        }).toList();

        setState(() {
          _historyBookings = history;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching booking history: $e');
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
        title: Text('Visit History', style: DesignSystem.h2),
        leading: widget.isEmbedded
            ? null
            : IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new, color: DesignSystem.textMain, size: 20),
              ),
        automaticallyImplyLeading: !widget.isEmbedded,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchBookings,
        color: DesignSystem.primaryAccent,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: DesignSystem.primaryAccent))
            : _historyBookings.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _historyBookings.length,
                    itemBuilder: (context, index) {
                      final booking = _historyBookings[index];
                      return _buildVisitCard(booking);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: DesignSystem.primaryAccent.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history_toggle_off_rounded,
                  size: 64,
                  color: DesignSystem.primaryAccent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Past Visits',
                style: DesignSystem.h2,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48.0),
                child: Text(
                  'Your completed and cancelled appointment histories will appear here.',
                  textAlign: TextAlign.center,
                  style: DesignSystem.bodyMain.copyWith(color: DesignSystem.textSub.withOpacity(0.6)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisitCard(Map<String, dynamic> booking) {
    // Extract populated fields safely
    final doctor = booking['doctorId'];
    final clinic = booking['orgId'];

    final doctorName = doctor is Map ? (doctor['name'] ?? 'Doctor') : 'Doctor';
    final doctorSpecialty = doctor is Map ? (doctor['specialization'] ?? 'Specialist') : 'Specialist';
    final doctorPhoto = doctor is Map ? (doctor['photoURL'] ?? '') : '';

    final clinicName = clinic is Map ? (clinic['name'] ?? 'Clinic') : 'Clinic';
    final clinicLocation = clinic is Map
        ? (clinic['locationDetails']?['fullAddress'] ?? clinic['locationDetails']?['city'] ?? 'Location')
        : 'Location';

    // Parse appointmentDate
    String formattedDate = 'Date pending';
    if (booking['appointmentDate'] != null) {
      try {
        final parsedDate = DateTime.parse(booking['appointmentDate']);
        formattedDate = "${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}";
      } catch (_) {}
    }

    final appointmentTime = booking['appointmentTime'] ?? 'Timing pending';
    final status = booking['status'] ?? 'pending';
    final patientName = booking['name'] ?? 'Patient';

    Color statusColor;
    IconData statusIcon;
    switch (status.toLowerCase()) {
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

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VisitDetailPage(booking: booking),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: DesignSystem.glassWhite,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
              boxShadow: [DesignSystem.softShadow],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: DesignSystem.primaryAccent.withOpacity(0.1),
                      backgroundImage: doctorPhoto.isNotEmpty ? NetworkImage(doctorPhoto) : null,
                      child: doctorPhoto.isEmpty ? const Icon(Icons.person, color: DesignSystem.primaryAccent) : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doctorName, style: DesignSystem.bodyBold.copyWith(fontSize: 16)),
                          Text(doctorSpecialty, style: DesignSystem.bodyMain.copyWith(fontSize: 12, color: DesignSystem.textSub)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: Colors.black12),
                Row(
                  children: [
                    const Icon(Icons.local_hospital, color: DesignSystem.secondaryAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        clinicName,
                        style: DesignSystem.bodyBold.copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                if (clinicLocation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 24.0),
                    child: Text(
                      clinicLocation,
                      style: DesignSystem.bodyMain.copyWith(fontSize: 12, color: DesignSystem.textSub.withOpacity(0.7)),
                    ),
                  ),
                ],
                const Divider(height: 24, color: Colors.black12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, color: DesignSystem.primaryAccent, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "$formattedDate  |  $appointmentTime",
                          style: TextStyle(
                            color: DesignSystem.primaryAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "For: $patientName",
                      style: TextStyle(
                        color: DesignSystem.textSub.withOpacity(0.8),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
