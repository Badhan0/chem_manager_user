import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/design_system.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrescriptionsPage extends StatefulWidget {
  const PrescriptionsPage({super.key});

  @override
  _PrescriptionsPageState createState() => _PrescriptionsPageState();
}

class _PrescriptionsPageState extends State<PrescriptionsPage> {
  List<dynamic> _prescriptions = [];
  bool _isLoading = true;
  String? _phone;

  @override
  void initState() {
    super.initState();
    _loadUserPhoneAndFetchRx();
  }

  Future<void> _loadUserPhoneAndFetchRx() async {
    final prefs = await SharedPreferences.getInstance();
    _phone = prefs.getString('user_phone');
    if (_phone != null) {
      _fetchPrescriptions();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPrescriptions() async {
    if (_phone == null) return;
    try {
      final response = await ApiService.getPrescriptions(_phone!);
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['success']) {
          setState(() {
            _prescriptions = resData['data'];
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching prescriptions: $e');
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
        title: Text('Prescriptions', style: DesignSystem.h2),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: DesignSystem.textMain, size: 20),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPrescriptions,
        color: DesignSystem.primaryAccent,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: DesignSystem.primaryAccent))
            : _prescriptions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _prescriptions.length,
                    itemBuilder: (context, index) {
                      final rx = _prescriptions[index];
                      return _buildRxCard(rx);
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
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: DesignSystem.primaryAccent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Prescriptions',
                style: DesignSystem.h2,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48.0),
                child: Text(
                  'Your clinical prescriptions issued by specialists will appear here.',
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

  Widget _buildRxCard(Map<String, dynamic> rx) {
    final String name = rx['medicineName'] ?? 'Medicine';
    final String dosage = rx['dosage'] ?? 'Dose';
    final String instructions = rx['instructions'] ?? '';
    final String doctorName = rx['doctorName'] ?? 'General Physician';

    // Simple alternates for colors/icons
    final color = name.hashCode % 2 == 0 ? Colors.teal : Colors.blue;
    final icon = name.hashCode % 2 == 0 ? Icons.healing_rounded : Icons.medical_services_rounded;

    return ClipRRect(
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: DesignSystem.bodyBold.copyWith(fontSize: 18)),
                    Text(dosage, style: DesignSystem.bodyMain.copyWith(fontSize: 12)),
                    if (instructions.isNotEmpty)
                      Text(instructions, style: DesignSystem.bodyMain.copyWith(fontSize: 10, color: DesignSystem.textSub)),
                    const SizedBox(height: 4),
                    Text('Prescribed by: $doctorName', style: TextStyle(color: DesignSystem.primaryAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Icon(Icons.download_rounded, color: DesignSystem.textSub.withOpacity(0.3), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
