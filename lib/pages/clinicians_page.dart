import 'package:flutter/material.dart';
import '../theme/design_system.dart';

class CliniciansPage extends StatelessWidget {
  const CliniciansPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('MY CLINICIANS', style: DesignSystem.h2.copyWith(fontSize: 16)),
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new, size: 20)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildDrCard('Dr. Sarah Mitchell', 'Cardiologist', 'Active Case', Icons.face_retouching_natural_rounded, Colors.pinkAccent),
            const SizedBox(height: 16),
            _buildDrCard('Dr. James Wilson', 'General Practitioner', 'Primary Consultant', Icons.face_rounded, Colors.blueAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildDrCard(String name, String specialty, String status, IconData icon, Color color) {
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
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: DesignSystem.bodyBold.copyWith(fontSize: 18)),
                Text(specialty, style: DesignSystem.bodyMain.copyWith(fontSize: 12)),
                Text(status, style: DesignSystem.bodyMain.copyWith(fontSize: 10, color: color)),
              ],
            ),
          ),
          const Icon(Icons.forum_rounded, color: Colors.white24, size: 20),
        ],
      ),
    );
  }
}
