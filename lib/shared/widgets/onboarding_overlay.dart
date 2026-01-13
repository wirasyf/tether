import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Onboarding tutorial overlay for first-time users
class OnboardingOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingOverlay({super.key, required this.onComplete});

  /// Check if onboarding has been shown
  static Future<bool> hasShownOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_shown_onboarding') ?? false;
  }

  /// Mark onboarding as shown
  static Future<void> markAsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_shown_onboarding', true);
  }

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  int _currentPage = 0;

  final List<_OnboardingStep> _steps = [
    _OnboardingStep(
      emoji: '💕',
      title: 'Welcome to Tether',
      description: 'Feel your partner\'s touch, no matter the distance.',
      color: AppColors.loveRed,
    ),
    _OnboardingStep(
      emoji: '👆',
      title: 'Touch to Connect',
      description:
          'Tap, swipe, or draw on the canvas. Your partner feels every touch in real-time.',
      color: AppColors.primary,
    ),
    _OnboardingStep(
      emoji: '🎭',
      title: 'Express Yourself',
      description:
          'Use gestures like hugs, kisses, and heartbeats to show how you feel.',
      color: Colors.purple,
    ),
    _OnboardingStep(
      emoji: '💬',
      title: 'Quick Messages',
      description: 'Send preset or custom messages with beautiful animations.',
      color: AppColors.calmBlue,
    ),
    _OnboardingStep(
      emoji: '🏆',
      title: 'Grow Together',
      description:
          'Earn achievements, track streaks, and level up your relationship.',
      color: AppColors.highFiveGold,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _complete();
    }
  }

  void _complete() {
    HapticFeedback.mediumImpact();
    OnboardingOverlay.markAsShown();
    _fadeController.reverse().then((_) => widget.onComplete());
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeController,
      child: Material(
        color: Colors.black.withValues(alpha: 0.9),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _complete,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  itemCount: _steps.length,
                  itemBuilder: (context, index) {
                    final step = _steps[index];
                    return _OnboardingPage(step: step);
                  },
                ),
              ),

              // Page indicators
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _steps.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? _steps[index].color
                            : AppColors.textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

              // Next/Start button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: GestureDetector(
                  onTap: _nextPage,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _steps[_currentPage].color,
                          _steps[_currentPage].color.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _steps[_currentPage].color.withValues(
                            alpha: 0.4,
                          ),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      _currentPage == _steps.length - 1
                          ? 'Get Started'
                          : 'Next',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingStep {
  final String emoji;
  final String title;
  final String description;
  final Color color;

  _OnboardingStep({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingStep step;

  const _OnboardingPage({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated emoji with glow
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  step.color.withValues(alpha: 0.3),
                  step.color.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
            child: Center(
              child: Text(step.emoji, style: const TextStyle(fontSize: 72)),
            ),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            step.description,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
