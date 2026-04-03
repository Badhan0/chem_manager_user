import 'package:flutter/material.dart';
import '../theme/design_system.dart';
import 'dart:ui';

class TrialOrderPage extends StatelessWidget {
  const TrialOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text('Elite Trial Phase', style: DesignSystem.h1),
          const SizedBox(height: 12),
          Text(
            'Experience our premium medication synchronisation with a risk-free trial order.',
            style: DesignSystem.bodyMain,
          ),
          const SizedBox(height: 40),
          _buildTrialCard(
            context,
            'Exclusive Starter Kit',
            'Full premium synchronisation for 7 days.',
            '\$0.00',
            Icons.card_giftcard_rounded,
          ),
          const SizedBox(height: 24),
          _buildTrialCard(
            context,
            'Premium Care Trial',
            '30 days of elite clinical monitoring.',
            '\$4.99',
            Icons.verified_user_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTrialCard(BuildContext context, String title, String desc, String price, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DesignSystem.glassWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DesignSystem.primaryAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: DesignSystem.primaryAccent, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: DesignSystem.bodyBold.copyWith(fontSize: 18)),
                const SizedBox(height: 4),
                Text(desc, style: DesignSystem.bodyMain.copyWith(fontSize: 12, color: DesignSystem.textSub)),
                const SizedBox(height: 12),
                Text(price, style: DesignSystem.h2.copyWith(fontSize: 20, color: DesignSystem.secondaryAccent)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 20),
          ),
        ],
      ),
    );
  }
}
