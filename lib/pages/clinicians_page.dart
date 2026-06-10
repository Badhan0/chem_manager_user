import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/design_system.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CliniciansPage extends StatefulWidget {
  const CliniciansPage({super.key});

  @override
  _CliniciansPageState createState() => _CliniciansPageState();
}

class _CliniciansPageState extends State<CliniciansPage> {
  List<dynamic> _clinicians = [];
  bool _isLoading = true;
  String? _phone;

  @override
  void initState() {
    super.initState();
    _loadUserPhoneAndFetchClinicians();
  }

  Future<void> _loadUserPhoneAndFetchClinicians() async {
    final prefs = await SharedPreferences.getInstance();
    _phone = prefs.getString('user_phone');
    if (_phone != null) {
      _fetchClinicians();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchClinicians() async {
    if (_phone == null) return;
    try {
      final response = await ApiService.getMyClinicians(_phone!);
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['success']) {
          setState(() {
            _clinicians = resData['data'];
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching clinicians: $e');
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
        title: Text('My Clinicians', style: DesignSystem.h2),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: DesignSystem.textMain, size: 20),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchClinicians,
        color: DesignSystem.primaryAccent,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: DesignSystem.primaryAccent))
            : _clinicians.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _clinicians.length,
                    itemBuilder: (context, index) {
                      final doc = _clinicians[index];
                      return _buildDrCard(doc);
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
                  Icons.people_outline_rounded,
                  size: 64,
                  color: DesignSystem.primaryAccent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Clinicians Linked',
                style: DesignSystem.h2,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48.0),
                child: Text(
                  'Once you schedule appointment consultations with our specialists, they will be registered here.',
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

  Widget _buildDrCard(Map<String, dynamic> doc) {
    final String name = doc['name'] ?? 'Doctor';
    final String specialty = doc['specialty'] ?? 'General Practitioner';
    final String status = doc['status'] ?? 'Active Case';
    final String photo = doc['photoURL'] ?? '';

    final color = name.hashCode % 2 == 0 ? Colors.pink : Colors.blue;

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
              CircleAvatar(
                radius: 26,
                backgroundColor: color.withOpacity(0.12),
                backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                child: photo.isEmpty ? Icon(Icons.person, color: color, size: 28) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: DesignSystem.bodyBold.copyWith(fontSize: 18)),
                    Text(specialty, style: DesignSystem.bodyMain.copyWith(fontSize: 12)),
                    Text(status, style: DesignSystem.bodyMain.copyWith(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Icon(Icons.forum_rounded, color: DesignSystem.textSub.withOpacity(0.3), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
