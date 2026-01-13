import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/socket_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/animated_background.dart';
import '../../shared/widgets/glass_card.dart';
import '../canvas/touch_canvas_screen.dart';

/// Premium pairing screen to connect with partner
class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen>
    with TickerProviderStateMixin {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  String? _myCode;
  bool _isConnecting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    _generateMyCode();
    _checkExistingPairing();
  }

  void _generateMyCode() {
    final uuid = const Uuid().v4();
    _myCode = uuid.substring(0, 6).toUpperCase();
  }

  Future<void> _checkExistingPairing() async {
    final roomId = StorageService.instance.getRoomId();
    if (roomId != null) {
      await _connectToRoom(roomId);
    }
  }

  Future<void> _connectToRoom(String roomId) async {
    setState(() {
      _isConnecting = true;
      _error = null;
    });

    try {
      await SocketService.instance.connect(roomId: roomId);
      await StorageService.instance.setRoomId(roomId);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const TouchCanvasScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Connection failed. Please try again.';
        _isConnecting = false;
      });
      HapticFeedback.heavyImpact();
    }
  }

  void _joinPartnerCode() {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length < 4) {
      setState(() => _error = 'Please enter a valid code');
      HapticFeedback.mediumImpact();
      return;
    }
    HapticFeedback.lightImpact();
    _connectToRoom(code);
  }

  void _useMyCode() {
    if (_myCode != null) {
      HapticFeedback.lightImpact();
      _connectToRoom(_myCode!);
    }
  }

  void _copyCode() {
    if (_myCode != null) {
      Clipboard.setData(ClipboardData(text: _myCode!));
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Code copied to clipboard!'),
          backgroundColor: AppColors.primary.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          const Positioned.fill(child: AnimatedBackground()),

          // Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _buildHeader(),
                    const SizedBox(height: 48),
                    _buildMyCodeSection(),
                    const SizedBox(height: 32),
                    _buildDivider(),
                    const SizedBox(height: 32),
                    _buildJoinSection(),
                    if (_error != null) _buildError(),
                    const SizedBox(height: 40),
                    _buildDemoButton(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_isConnecting) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Simple icon
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final opacity = 0.6 + 0.4 * _pulseController.value;
            return Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.favorite_rounded,
                color: AppColors.primary.withValues(alpha: opacity),
                size: 32,
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        // App name - simple
        const Text(
          'Tether',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 8),

        // Tagline
        Text(
          'Connect with your partner',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildMyCodeSection() {
    return GlassCard(
      enableGlow: true,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.qr_code_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Your Unique Code',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Code display with glow
          GestureDetector(
            onTap: _copyCode,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < (_myCode?.length ?? 0); i++) ...[
                  CodeBox(character: _myCode![i], isActive: true),
                  if (i < (_myCode!.length - 1)) const SizedBox(width: 8),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tap to copy hint
          GestureDetector(
            onTap: _copyCode,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: AppColors.textMuted.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
                Text(
                  'Tap to copy • Share with your partner',
                  style: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Start button
          GradientButton(
            onPressed: _useMyCode,
            isLoading: _isConnecting,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow_rounded, size: 22),
                SizedBox(width: 8),
                Text('Start Session'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.textMuted.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.textMuted.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            'OR',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.textMuted.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJoinSection() {
    return GlassCard(
      enableGlow: false,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Join Partner\'s Room',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Code input field
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: TextField(
              controller: _codeController,
              focusNode: _focusNode,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 10,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'ENTER CODE',
                hintStyle: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                  letterSpacing: 4,
                  fontSize: 18,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                counterText: '',
              ),
              maxLength: 6,
              onSubmitted: (_) => _joinPartnerCode(),
            ),
          ),

          const SizedBox(height: 20),

          // Join button
          GradientOutlineButton(
            onPressed: _joinPartnerCode,
            gradientColors: const [AppColors.secondary, AppColors.primary],
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.login_rounded, size: 20),
                SizedBox(width: 8),
                Text('Join Room'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              _error!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoButton() {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final isSignedIn = AuthService.instance.isSignedIn;
        final displayName = AuthService.instance.displayName;

        if (isSignedIn) {
          return Column(
            children: [
              Text(
                'Signed in as',
                style: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayName ?? 'User',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'by wirawrr',
                style: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            TextButton(
              onPressed: () async {
                HapticFeedback.lightImpact();
                await AuthService.instance.signInWithGoogle();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                backgroundColor: AppColors.surface.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: AppColors.textMuted.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.login, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Sign in with Google',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'by wirawrr',
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: AppColors.background.withValues(alpha: 0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Connecting...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
