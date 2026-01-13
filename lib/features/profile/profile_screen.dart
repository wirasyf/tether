import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/partner_profile_service.dart';
import '../../shared/widgets/glass_card.dart';

/// Profile screen for managing user and viewing partner profile
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();

  final List<String> _avatars = [
    '💕',
    '❤️',
    '💖',
    '💗',
    '💓',
    '💘',
    '💝',
    '💞',
    '🥰',
    '😍',
    '🌹',
    '🌸',
    '🦋',
    '✨',
    '🌟',
    '💫',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = PartnerProfileService.instance.myProfile?.name ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
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
        listenable: PartnerProfileService.instance,
        builder: (context, _) {
          final myProfile = PartnerProfileService.instance.myProfile;
          final partnerProfile = PartnerProfileService.instance.partnerProfile;
          final daysTogether = PartnerProfileService.instance.daysTogether;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Days together counter
                if (daysTogether > 0)
                  Center(
                    child: GlassCard(
                      enableGlow: true,
                      glowColor: AppColors.loveRed,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Text('💕', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 12),
                          Text(
                            '$daysTogether',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'days together',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // My profile section
                const Text(
                  'My Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Avatar
                      GestureDetector(
                        onTap: () => _showAvatarPicker(),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              myProfile?.avatarEmoji ?? '💕',
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to change',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Name input
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: 'Your name',
                          hintStyle: TextStyle(color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            PartnerProfileService.instance.updateName(
                              value.trim(),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Partner profile section
                const Text(
                  'Partner',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: partnerProfile != null
                      ? Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(
                                  alpha: 0.2,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  partnerProfile.avatarEmoji ?? '💕',
                                  style: const TextStyle(fontSize: 30),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    partnerProfile.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: partnerProfile.isOnline
                                              ? AppColors.success
                                              : AppColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        partnerProfile.isOnline
                                            ? 'Online'
                                            : 'Offline',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Text(
                            'Partner profile will appear once connected',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                ),

                const SizedBox(height: 32),

                // Set relationship start date
                const Text(
                  'Relationship',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                GestureDetector(
                  onTap: _pickRelationshipStart,
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            PartnerProfileService.instance.relationshipStart !=
                                    null
                                ? 'Started ${_formatDate(PartnerProfileService.instance.relationshipStart!)}'
                                : 'Set when you started dating',
                            style: TextStyle(
                              color:
                                  PartnerProfileService
                                          .instance
                                          .relationshipStart !=
                                      null
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAvatarPicker() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Avatar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _avatars.map((emoji) {
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    PartnerProfileService.instance.updateAvatar(emoji);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _pickRelationshipStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          PartnerProfileService.instance.relationshipStart ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      PartnerProfileService.instance.setRelationshipStart(date);
    }
  }
}
