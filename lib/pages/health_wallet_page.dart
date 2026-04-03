import 'package:flutter/material.dart';
import '../theme/design_system.dart';

class HealthWalletPage extends StatelessWidget {
  const HealthWalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('HEALTH WALLET', style: DesignSystem.h2.copyWith(fontSize: 16)),
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new, size: 20)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: DesignSystem.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [DesignSystem.neonShadow(DesignSystem.primaryAccent)],
              ),
              child: Column(
                children: [
                  Text('CREDIT BALANCE', style: DesignSystem.bodyMain.copyWith(color: Colors.white70, letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  Text('\$42,850.50', style: DesignSystem.h1.copyWith(fontSize: 36, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('Elite Tier Verified', style: DesignSystem.bodyBold.copyWith(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildWalletTile('Digital Health ID', 'Elite-4821-X', Icons.qr_code_2_rounded),
            _buildWalletTile('Insurance Coverage', 'LUV-882103', Icons.beach_access_rounded),
            _buildWalletTile('Billing History', 'Last activity: Oct 12', Icons.receipt_long_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletTile(String title, String val, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignSystem.glassWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: DesignSystem.primaryAccent, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: DesignSystem.bodyBold),
                Text(val, style: DesignSystem.bodyMain.copyWith(fontSize: 12, color: DesignSystem.textSub)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
        ],
      ),
    );
  }
}
