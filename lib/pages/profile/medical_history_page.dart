import 'package:flutter/material.dart';
import '../../theme/design_system.dart';

class MedicalHistoryPage extends StatelessWidget {
  const MedicalHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Medical History', style: DesignSystem.h2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Past Conditions'),
            _buildHistoryItem('Asthma', 'Diagnosed in 2015', Icons.air),
            _buildHistoryItem('Seasonal Allergies', 'Ongoing', Icons.bug_report),
            const SizedBox(height: 24),
            _buildSectionTitle('Surgical History'),
            _buildHistoryItem('Appendectomy', 'June 2018', Icons.healing),
            const SizedBox(height: 24),
            _buildSectionTitle('Vaccinations'),
            _buildHistoryItem('COVID-19 Booster', 'Jan 2024', Icons.vaccines),
            _buildHistoryItem('Influenza', 'Oct 2023', Icons.vaccines),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: DesignSystem.bodyBold.copyWith(color: DesignSystem.primaryAccent)),
    );
  }

  Widget _buildHistoryItem(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DesignSystem.glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: DesignSystem.primaryAccent.withOpacity(0.1),
          child: Icon(icon, color: DesignSystem.primaryAccent, size: 20),
        ),
        title: Text(title, style: DesignSystem.bodyBold),
        subtitle: Text(subtitle, style: DesignSystem.bodyMain),
      ),
    );
  }
}
