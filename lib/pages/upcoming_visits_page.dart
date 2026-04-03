import 'package:flutter/material.dart';
import '../theme/design_system.dart';

class UpcomingVisitsPage extends StatelessWidget {
  const UpcomingVisitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('UPCOMING VISITS', style: DesignSystem.h2.copyWith(fontSize: 16)),
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new, size: 20)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildVisitCard(
              'Dr. Sarah Mitchell',
              'Cardiology Center',
              'Oct 15, 2026 - 10:30 AM',
              Icons.calendar_month_rounded,
              Colors.pinkAccent,
            ),
            const SizedBox(height: 16),
            _buildVisitCard(
              'Dr. James Wilson',
              'Primary Care Hub',
              'Oct 22, 2026 - 02:00 PM',
              Icons.medical_services_rounded,
              Colors.blueAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitCard(String name, String location, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignSystem.glassWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: DesignSystem.bodyBold.copyWith(fontSize: 18)),
                Text(location, style: DesignSystem.bodyMain.copyWith(fontSize: 14, color: DesignSystem.textSub)),
                const SizedBox(height: 8),
                Text(time, style: TextStyle(color: DesignSystem.secondaryAccent, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.info_outline_rounded, color: Colors.white24, size: 20),
        ],
      ),
    );
  }
}
