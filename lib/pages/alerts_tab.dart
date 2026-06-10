import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/design_system.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlertsTab extends StatefulWidget {
  const AlertsTab({super.key});

  @override
  _AlertsTabState createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab> {
  List<dynamic> _alerts = [];
  bool _isLoading = true;
  String? _phone;

  @override
  void initState() {
    super.initState();
    _loadUserPhoneAndFetchAlerts();
  }

  Future<void> _loadUserPhoneAndFetchAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    _phone = prefs.getString('user_phone');
    if (_phone != null) {
      _fetchAlerts();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAlerts() async {
    if (_phone == null) return;
    try {
      final response = await ApiService.getAlerts(_phone!);
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['success']) {
          setState(() {
            _alerts = resData['data'];
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching alerts: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchAlerts,
      color: DesignSystem.primaryAccent,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: DesignSystem.primaryAccent))
          : _alerts.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  itemCount: _alerts.length,
                  itemBuilder: (context, index) {
                    final alert = _alerts[index];
                    return _buildAlertCard(alert);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
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
                  Icons.notifications_off_outlined,
                  size: 64,
                  color: DesignSystem.primaryAccent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No New Alerts',
                style: DesignSystem.h2,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48.0),
                child: Text(
                  'We will notify you here when there are updates to your bookings, prescriptions, or orders.',
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

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final String title = alert['title'] ?? 'Notification';
    final String body = alert['body'] ?? '';
    final String type = alert['type'] ?? 'general';

    Color color;
    IconData icon;

    switch (type) {
      case 'booking':
        color = Colors.amber.shade700;
        icon = Icons.calendar_month_rounded;
        break;
      case 'prescription':
        color = Colors.teal;
        icon = Icons.receipt_long_rounded;
        break;
      case 'order':
        color = Colors.orange;
        icon = Icons.local_shipping_rounded;
        break;
      default: // general
        color = Colors.blue;
        icon = Icons.notifications_active_rounded;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DesignSystem.glassWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
            boxShadow: [DesignSystem.softShadow],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: DesignSystem.bodyBold.copyWith(fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(body, style: DesignSystem.bodyMain.copyWith(fontSize: 12, color: DesignSystem.textSub)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
