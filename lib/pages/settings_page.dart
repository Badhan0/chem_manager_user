import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/design_system.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text('Cloud Matrix Settings', style: DesignSystem.h1),
          const SizedBox(height: 8),
          Text('Configure your elite clinical experience.', style: DesignSystem.bodyMain),
          const SizedBox(height: 48),
          
          _buildSettingsGroup('Security', [
            _buildSettingsTile('Lock Synchronization', Icons.lock_outline_rounded, true),
            _buildSettingsTile('Biometric Identity', Icons.fingerprint_rounded, true),
          ]),
          const SizedBox(height: 40),
          
          _buildSettingsGroup('Notifications', [
            _buildSettingsTile('Vital Alerts', Icons.notification_important_rounded, true),
            _buildSettingsTile('Prescription Reminders', Icons.medication_rounded, true),
          ]),
          const SizedBox(height: 40),
          
          _buildSettingsGroup('Cloud Configuration', [
            _buildSettingsTile('Data Encryption', Icons.enhanced_encryption_rounded, true),
            _buildSettingsTile('Clinical Sync Frequency', Icons.sync_rounded, false),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: DesignSystem.bodyBold.copyWith(fontSize: 12, letterSpacing: 1.5, color: DesignSystem.textSub.withOpacity(0.5))),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildSettingsTile(String title, IconData icon, bool hasSwitch) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: DesignSystem.glassWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
            boxShadow: [DesignSystem.softShadow],
          ),
          child: ListTile(
            leading: Icon(icon, color: DesignSystem.primaryAccent, size: 24),
            title: Text(title, style: DesignSystem.bodyBold),
            trailing: hasSwitch 
                ? Switch(value: true, onChanged: (v) {}, activeColor: DesignSystem.primaryAccent)
                : Icon(Icons.arrow_forward_ios, color: DesignSystem.textSub.withOpacity(0.3), size: 16),
            onTap: () {},
          ),
        ),
      ),
    );
  }
}
