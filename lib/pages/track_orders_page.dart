import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/design_system.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrackOrdersPage extends StatefulWidget {
  final VoidCallback? onBack;
  const TrackOrdersPage({super.key, this.onBack});

  @override
  _TrackOrdersPageState createState() => _TrackOrdersPageState();
}

class _TrackOrdersPageState extends State<TrackOrdersPage> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _phone;

  @override
  void initState() {
    super.initState();
    _loadUserPhoneAndFetchOrders();
  }

  Future<void> _loadUserPhoneAndFetchOrders() async {
    final prefs = await SharedPreferences.getInstance();
    _phone = prefs.getString('user_phone');
    if (_phone != null) {
      _fetchOrders();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchOrders() async {
    if (_phone == null) return;
    try {
      final response = await ApiService.getOrders(_phone!);
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['success']) {
          setState(() {
            _orders = resData['data'];
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching orders: $e');
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
        title: Text('Track Orders', style: DesignSystem.h2),
        leading: widget.onBack != null
            ? IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_ios_new, color: DesignSystem.textMain, size: 20),
              )
            : (Navigator.canPop(context)
                ? IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: DesignSystem.textMain, size: 20),
                  )
                : null),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        color: DesignSystem.primaryAccent,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: DesignSystem.primaryAccent))
            : _orders.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      return _buildOrderCard(order);
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
                  Icons.local_shipping_outlined,
                  size: 64,
                  color: DesignSystem.primaryAccent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Active Orders',
                style: DesignSystem.h2,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48.0),
                child: Text(
                  'Your medicine order synchronisations will appear here once processed.',
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

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final String id = order['orderId'] ?? 'Order';
    final String status = order['status'] ?? 'Processing';
    final String details = order['details'] ?? '';

    Color color;
    IconData icon;

    switch (status) {
      case 'In Transit':
        color = Colors.orange;
        icon = Icons.local_shipping_rounded;
        break;
      case 'Delivered':
        color = Colors.green;
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'Cancelled':
        color = Colors.red;
        icon = Icons.cancel_rounded;
        break;
      default: // Processing
        color = Colors.blue;
        icon = Icons.hourglass_bottom_rounded;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
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
                decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(id, style: DesignSystem.bodyBold),
                    Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                    if (details.isNotEmpty)
                      Text(details, style: DesignSystem.bodyMain.copyWith(fontSize: 10, color: DesignSystem.textSub)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: DesignSystem.textSub.withOpacity(0.3), size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
