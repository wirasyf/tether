import 'package:flutter/material.dart';
import '../../core/services/stats_service.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_card.dart';

/// Statistics screen showing touch activity and streaks
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Your Connection',
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
        listenable: StatsService.instance,
        builder: (context, _) {
          final stats = StatsService.instance.stats;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Streak card
                _buildStreakCard(stats),

                const SizedBox(height: 24),

                // Today's activity
                const Text(
                  'Today\'s Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.touch_app,
                        value: stats.todayTouches.toString(),
                        label: 'Touches',
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.favorite,
                        value: stats.todayGestures.toString(),
                        label: 'Gestures',
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Weekly chart
                const Text(
                  'This Week',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildWeeklyChart(),

                const SizedBox(height: 32),

                // All time stats
                const Text(
                  'All Time',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildAllTimeStats(stats),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStreakCard(TouchStats stats) {
    final hasStreak = stats.currentStreak > 0;

    return GlassCard(
      enableGlow: hasStreak,
      glowColor: AppColors.highFiveGold,
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: hasStreak
                  ? const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    )
                  : null,
              color: hasStreak ? null : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                hasStreak ? '🔥' : '❄️',
                style: const TextStyle(fontSize: 36),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stats.currentStreak} day${stats.currentStreak != 1 ? 's' : ''} streak',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasStreak ? 'Keep it going! 💪' : 'Start a new streak today!',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (stats.longestStreak > stats.currentStreak) ...[
                  const SizedBox(height: 8),
                  Text(
                    '🏆 Best: ${stats.longestStreak} days',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return GlassCard(
      enableGlow: false,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final data = StatsService.instance.getDailyTouchesForChart();
    final maxValue = data.fold<int>(1, (max, val) => val > max ? val : max);
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday - 1;

    return GlassCard(
      enableGlow: false,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final value = index < data.length ? data[index] : 0;
              final height = maxValue > 0 ? (value / maxValue) * 100 : 0.0;
              final isToday = index == 6;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Text(
                        value.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: isToday
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: height.clamp(8.0, 100.0),
                        decoration: BoxDecoration(
                          gradient: isToday
                              ? AppColors.primaryGradient
                              : LinearGradient(
                                  colors: [
                                    AppColors.textMuted.withValues(alpha: 0.3),
                                    AppColors.textMuted.withValues(alpha: 0.5),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        days[(today + index - 6) % 7],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isToday
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAllTimeStats(TouchStats stats) {
    return GlassCard(
      enableGlow: false,
      child: Column(
        children: [
          _buildAllTimeRow(
            icon: Icons.touch_app,
            label: 'Total Touches',
            value: _formatNumber(stats.totalTouches),
          ),
          Divider(color: AppColors.textMuted.withValues(alpha: 0.2)),
          _buildAllTimeRow(
            icon: Icons.favorite,
            label: 'Total Gestures',
            value: _formatNumber(stats.totalGestures),
          ),
          Divider(color: AppColors.textMuted.withValues(alpha: 0.2)),
          _buildAllTimeRow(
            icon: Icons.calendar_today,
            label: 'This Week',
            value: _formatNumber(stats.weekTouches),
          ),
          Divider(color: AppColors.textMuted.withValues(alpha: 0.2)),
          _buildAllTimeRow(
            icon: Icons.emoji_events,
            label: 'Longest Streak',
            value: '${stats.longestStreak} days',
          ),
        ],
      ),
    );
  }

  Widget _buildAllTimeRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 16),
          Text(
            label,
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
