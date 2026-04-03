import 'package:flutter/material.dart';
import '../theme/design_system.dart';

class TrackOrdersPage extends StatelessWidget {
  const TrackOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text('Active Synchronisations', style: DesignSystem.h1),
          const SizedBox(height: 8),
          Text('Monitor your elite medical delivery sequence.', style: DesignSystem.bodyMain),
          const SizedBox(height: 40),
          _buildOrderCard('Order #ORD-8821', 'In Transit', 'Delivery expected by 4:00 PM', Icons.local_shipping_rounded, Colors.orangeAccent),
          const SizedBox(height: 16),
          _buildOrderCard('Order #ORD-7712', 'Processing', 'Clinical validation in progress', Icons.hourglass_bottom_rounded, Colors.cyanAccent),
        ],
      ),
    );
  }

  Widget _buildOrderCard(String id, String status, String eta, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignSystem.glassWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(id, style: DesignSystem.bodyBold),
                Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                Text(eta, style: DesignSystem.bodyMain.copyWith(fontSize: 10, color: DesignSystem.textSub)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
        ],
      ),
    );
  }
}
