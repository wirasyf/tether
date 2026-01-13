import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/theme_service.dart';
import '../../core/services/stats_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/socket_service.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_card.dart';
import '../stats/stats_screen.dart';
import '../profile/profile_screen.dart';
import '../love_notes/love_notes_screen.dart';
import '../special_dates/special_dates_screen.dart';
import '../achievements/achievements_screen.dart';
import '../pairing/pairing_screen.dart';

/// Settings screen with personalization options
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListenableBuilder(
        listenable: ThemeService.instance,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick access buttons
                _buildSectionTitle('Quick Access'),
                const SizedBox(height: 16),
                _buildQuickAccessGrid(context),

                const SizedBox(height: 32),

                // Theme section
                _buildSectionTitle('Appearance'),
                const SizedBox(height: 16),
                _buildThemePicker(),

                const SizedBox(height: 32),

                // Touch color section
                _buildSectionTitle('Touch Color'),
                const SizedBox(height: 16),
                _buildTouchColorPicker(),

                const SizedBox(height: 32),

                // Preferences section
                _buildSectionTitle('Preferences'),
                const SizedBox(height: 16),
                _buildPreferences(),

                const SizedBox(height: 32),

                // Actions section
                _buildSectionTitle('Actions'),
                const SizedBox(height: 16),
                _buildActions(context),

                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context) {
    return GlassCard(
      enableGlow: false,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _buildQuickAccessButton(
                context,
                icon: Icons.person,
                label: 'Profile',
                color: AppColors.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
              ),
              const SizedBox(width: 12),
              _buildQuickAccessButton(
                context,
                icon: Icons.favorite,
                label: 'Love Notes',
                color: AppColors.loveRed,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoveNotesScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildQuickAccessButton(
                context,
                icon: Icons.calendar_today,
                label: 'Special Dates',
                color: AppColors.highFiveGold,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SpecialDatesScreen()),
                ),
              ),
              const SizedBox(width: 12),
              _buildQuickAccessButton(
                context,
                icon: Icons.emoji_events,
                label: 'Achievements',
                color: Colors.purple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AchievementsScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildQuickAccessButton(
            context,
            icon: Icons.bar_chart,
            label: 'Connection Stats',
            color: AppColors.calmBlue,
            fullWidth: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    final button = GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );

    // When fullWidth is true, this button is a direct child of a Column,
    // so we can't use Expanded (it requires bounded constraints).
    // When fullWidth is false, it's inside a Row, so Expanded works fine.
    return fullWidth ? button : Expanded(child: button);
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildThemePicker() {
    final currentTheme = ThemeService.instance.theme;

    return GlassCard(
      enableGlow: false,
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: AppThemeType.values.map((theme) {
          final isSelected = theme == currentTheme;
          final color = Color(theme.primaryColorValue);

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ThemeService.instance.setTheme(theme);
            },
            child: Container(
              width: 90,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.2)
                    : AppColors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? color
                      : Colors.white.withValues(alpha: 0.1),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(theme.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 6),
                  Text(
                    theme.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? color : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTouchColorPicker() {
    final currentColor = ThemeService.instance.touchColor;

    return GlassCard(
      enableGlow: false,
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: TouchColorOption.values.map((option) {
          final isSelected = option == currentColor;
          final color = Color(option.colorValue);

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ThemeService.instance.setTouchColor(option);
            },
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.1),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: option == TouchColorOption.rainbow
                          ? const LinearGradient(
                              colors: [
                                Colors.red,
                                Colors.orange,
                                Colors.yellow,
                                Colors.green,
                                Colors.blue,
                                Colors.purple,
                              ],
                            )
                          : null,
                      color: option != TouchColorOption.rainbow ? color : null,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    option.displayName.split(' ').first,
                    style: TextStyle(
                      fontSize: 9,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPreferences() {
    return GlassCard(
      enableGlow: false,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.auto_awesome,
            title: 'Background Particles',
            subtitle: 'Floating particles in the background',
            value: ThemeService.instance.showParticles,
            onChanged: (v) => ThemeService.instance.setShowParticles(v),
          ),
          Divider(color: AppColors.textMuted.withValues(alpha: 0.2)),
          _buildSwitchTile(
            icon: Icons.vibration,
            title: 'Haptic Feedback',
            subtitle: 'Vibrate on touch and gestures',
            value: ThemeService.instance.hapticFeedback,
            onChanged: (v) => ThemeService.instance.setHapticFeedback(v),
          ),
          Divider(color: AppColors.textMuted.withValues(alpha: 0.2)),
          _buildSwitchTile(
            icon: Icons.volume_up,
            title: 'Sound Effects',
            subtitle: 'Play sounds on gestures',
            value: ThemeService.instance.soundEffects,
            onChanged: (v) => ThemeService.instance.setSoundEffects(v),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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

  Widget _buildActions(BuildContext context) {
    return GlassCard(
      enableGlow: false,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.logout,
            title: 'Leave Room',
            subtitle: 'Disconnect from current partner',
            color: AppColors.warning,
            onTap: () => _showLeaveRoomDialog(context),
          ),
          Divider(color: AppColors.textMuted.withValues(alpha: 0.2)),
          _buildActionTile(
            icon: Icons.delete_outline,
            title: 'Reset Statistics',
            subtitle: 'Clear all your activity data',
            color: AppColors.error,
            onTap: () => _showResetStatsDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showLeaveRoomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Leave Room?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'You will be disconnected from your partner. You can reconnect anytime with a new code.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Disconnect from socket first
              SocketService.instance.disconnect();
              // Clear all room data
              await StorageService.instance.clearRoomId();
              // Navigate to PairingScreen and remove all previous routes
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const PairingScreen()),
                  (route) => false,
                );
              }
            },
            child: Text('Leave', style: TextStyle(color: AppColors.warning)),
          ),
        ],
      ),
    );
  }

  void _showResetStatsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Reset Statistics?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'This will clear all your touch statistics and streak data. This cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await StatsService.instance.resetStats();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Statistics reset'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            child: Text('Reset', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
