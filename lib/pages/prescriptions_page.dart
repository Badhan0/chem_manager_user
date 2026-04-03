import 'package:flutter/material.dart';
import '../theme/design_system.dart';

class PrescriptionsPage extends StatelessWidget {
  const PrescriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('PRESCRIPTIONS', style: DesignSystem.h2.copyWith(fontSize: 16)),
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new, size: 20)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildRxCard('Lisinopril', '10mg Once Daily', 'Expires 21 Oct 2026', Icons.healing_rounded, Colors.tealAccent),
            const SizedBox(height: 16),
            _buildRxCard('Atorvastatin', '20mg Bedtime', 'Expires 12 Jan 2027', Icons.medical_services_rounded, Colors.cyanAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildRxCard(String name, String dose, String expiry, IconData icon, Color color) {
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
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: DesignSystem.bodyBold.copyWith(fontSize: 18)),
                Text(dose, style: DesignSystem.bodyMain.copyWith(fontSize: 12)),
                Text(expiry, style: DesignSystem.bodyMain.copyWith(fontSize: 10, color: DesignSystem.textSub)),
              ],
            ),
          ),
          const Icon(Icons.download_rounded, color: Colors.white24, size: 20),
        ],
      ),
    );
  }
}
