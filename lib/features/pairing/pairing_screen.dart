import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/socket_service.dart';
import '../../core/services/storage_service.dart';
import '../../shared/widgets/animated_background.dart';
import '../../shared/widgets/glass_card.dart';
import '../canvas/touch_canvas_screen.dart';

/// Pairing screen to connect with partner
class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen>
    with SingleTickerProviderStateMixin {
  final _codeController = TextEditingController();
  late AnimationController _pulseController;
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
    
    _generateMyCode();
    _checkExistingPairing();
  }
  
  void _generateMyCode() {
    // Generate a simple 6-character room code
    final uuid = const Uuid().v4();
    _myCode = uuid.substring(0, 6).toUpperCase();
  }
  
  Future<void> _checkExistingPairing() async {
    final roomId = StorageService.instance.getRoomId();
    if (roomId != null) {
      // Already paired, connect and go to canvas
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
          MaterialPageRoute(
            builder: (context) => const TouchCanvasScreen(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to connect. Please try again.';
        _isConnecting = false;
      });
    }
  }
  
  void _joinPartnerCode() {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length < 4) {
      setState(() => _error = 'Please enter a valid code');
      return;
    }
    _connectToRoom(code);
  }
  
  void _useMyCode() {
    if (_myCode != null) {
      _connectToRoom(_myCode!);
    }
  }
  
  @override
  void dispose() {
    _codeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          const Positioned.fill(
            child: AnimatedBackground(),
          ),
          
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  
                  // Logo and title
                  _buildHeader(),
                  
                  const SizedBox(height: 48),
                  
                  // My code section
                  _buildMyCodeSection(),
                  
                  const SizedBox(height: 32),
                  
                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.textMuted.withValues(alpha: 0.3))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.textMuted.withValues(alpha: 0.3))),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Join partner code
                  _buildJoinSection(),
                  
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  
                  const Spacer(flex: 2),
                  
                  // Demo mode button
                  _buildDemoButton(),
                ],
              ),
            ),
          ),
          
          // Loading overlay
          if (_isConnecting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = 1.0 + 0.1 * _pulseController.value;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Tether',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Feel each other\'s touch, anywhere',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMyCodeSection() {
    return GlassCard(
      child: Column(
        children: [
          const Text(
            'Your Code',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < (_myCode?.length ?? 0); i++) ...[
                Container(
                  width: 40,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _myCode![i],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                if (i < (_myCode!.length - 1)) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Share this code with your partner',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _useMyCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Start with my code'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildJoinSection() {
    return GlassCard(
      child: Column(
        children: [
          const Text(
            'Join Partner\'s Room',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'ENTER CODE',
              hintStyle: TextStyle(
                color: AppColors.textMuted,
                letterSpacing: 4,
              ),
            ),
            maxLength: 6,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _joinPartnerCode,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondary,
              side: const BorderSide(color: AppColors.secondary),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Join Room'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDemoButton() {
    return TextButton(
      onPressed: () {
        SocketService.instance.setDemoMode(true);
        _connectToRoom('demo-$_myCode');
      },
      child: const Text(
        'Try Demo Mode (Single Device)',
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
      ),
    );
  }
}
