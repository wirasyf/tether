import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/visual_themes.dart';
import '../../core/services/settings_service.dart';
import '../../shared/widgets/glass_card.dart';

/// Settings screen for app preferences
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<SettingsService>(
        builder: (context, settings, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Theme Section
              _buildSectionHeader('Visual Theme'),
              _buildThemeSelector(context, settings),
              
              const SizedBox(height: 24),
              
              // Preferences Section
              _buildSectionHeader('Preferences'),
              _buildToggleTile(
                icon: Icons.vibration,
                title: 'Haptic Feedback',
                subtitle: 'Vibration for touches and gestures',
                value: settings.hapticsEnabled,
                onChanged: settings.setHapticsEnabled,
              ),
              _buildToggleTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Get notified when partner touches',
                value: settings.notificationsEnabled,
                onChanged: settings.setNotificationsEnabled,
              ),
              _buildToggleTile(
                icon: Icons.schedule,
                title: 'Ghost Touch',
                subtitle: 'Save touches when partner is offline',
                value: settings.ghostTouchEnabled,
                onChanged: settings.setGhostTouchEnabled,
              ),
              
              const SizedBox(height: 24),
              
              // Partner Section
              _buildSectionHeader('Partner'),
              _buildPartnerNameTile(context, settings),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
  
  Widget _buildThemeSelector(BuildContext context, SettingsService settings) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: VisualTheme.values.length,
            itemBuilder: (context, index) {
              final theme = VisualTheme.values[index];
              final colors = VisualThemeData.getTheme(theme);
              final isSelected = settings.visualTheme == theme;
              
              return GestureDetector(
                onTap: () => settings.setVisualTheme(theme),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: colors.touchGradient,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isSelected)
                        const Icon(Icons.check, color: Colors.white, size: 20),
                      const SizedBox(height: 4),
                      Text(
                        _getThemeName(theme),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  String _getThemeName(VisualTheme theme) {
    switch (theme) {
      case VisualTheme.romantic:
        return 'Romantic';
      case VisualTheme.sakura:
        return 'Sakura';
      case VisualTheme.ocean:
        return 'Ocean';
      case VisualTheme.sunset:
        return 'Sunset';
      case VisualTheme.aurora:
        return 'Aurora';
      case VisualTheme.midnight:
        return 'Midnight';
    }
  }
  
  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Future<void> Function(bool) onChanged,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPartnerNameTile(BuildContext context, SettingsService settings) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.person_outline, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Partner Name',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  settings.partnerName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.textMuted),
            onPressed: () => _showNameDialog(context, settings),
          ),
        ],
      ),
    );
  }
  
  void _showNameDialog(BuildContext context, SettingsService settings) {
    final controller = TextEditingController(text: settings.partnerName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Partner Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Enter partner name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              settings.setPartnerName(controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
