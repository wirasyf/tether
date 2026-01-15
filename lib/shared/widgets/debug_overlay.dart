import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/socket_service.dart';
import '../../core/services/storage_service.dart';
import '../../models/touch_event.dart';

/// Debug overlay for testing and verifying sync functionality
/// Only visible in debug mode
class DebugOverlay extends StatefulWidget {
  final Widget child;

  const DebugOverlay({super.key, required this.child});

  @override
  State<DebugOverlay> createState() => _DebugOverlayState();
}

class _DebugOverlayState extends State<DebugOverlay> {
  bool _showDebugPanel = false;

  @override
  Widget build(BuildContext context) {
    // Only show debug features in debug mode
    if (!kDebugMode) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,

        // Floating debug button
        Positioned(
          top: 100,
          right: 0,
          child: GestureDetector(
            onTap: () => setState(() => _showDebugPanel = !_showDebugPanel),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.8),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
              ),
              child: Icon(
                _showDebugPanel ? Icons.close : Icons.bug_report,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),

        // Debug panel
        if (_showDebugPanel)
          Positioned(top: 140, right: 8, child: const DebugPanel()),
      ],
    );
  }
}

/// Debug panel showing sync status and connection info
class DebugPanel extends StatefulWidget {
  const DebugPanel({super.key});

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel> {
  Timer? _refreshTimer;
  int _sentTouches = 0;
  int _receivedTouches = 0;
  int _sentGestures = 0;
  int _receivedGestures = 0;
  DateTime? _lastSyncTime;
  StreamSubscription? _touchSub;
  StreamSubscription? _gestureSub;

  @override
  void initState() {
    super.initState();
    // Refresh every second
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    // Count incoming events
    _touchSub = SocketService.instance.incomingTouches.listen((_) {
      _receivedTouches++;
      _lastSyncTime = DateTime.now();
      if (mounted) setState(() {});
    });

    _gestureSub = SocketService.instance.incomingGestures.listen((_) {
      _receivedGestures++;
      _lastSyncTime = DateTime.now();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _touchSub?.cancel();
    _gestureSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socketService = SocketService.instance;
    final storageService = StorageService.instance;

    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.bug_report, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Debug Panel',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                'v1.0.0',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          ),

          const Divider(color: Colors.orange, height: 16),

          // Connection Status
          _buildSection('Connection', [
            _buildStatusRow(
              'Socket',
              socketService.isConnected ? 'Connected' : 'Disconnected',
              socketService.isConnected ? Colors.green : Colors.red,
            ),
            _buildStatusRow(
              'Partner',
              socketService.isPartnerOnline ? 'Online' : 'Offline',
              socketService.isPartnerOnline ? Colors.green : Colors.amber,
            ),
            _buildStatusRow(
              'Mode',
              socketService.isDemoMode ? 'Demo' : 'Firebase',
              socketService.isDemoMode ? Colors.amber : Colors.green,
            ),
          ]),

          const SizedBox(height: 8),

          // Room Info
          _buildSection('Room Info', [
            _buildInfoRow('Room ID', storageService.getRoomId() ?? 'None'),
            _buildInfoRow('User ID', _truncate(storageService.getUserId())),
            _buildInfoRow('Pairing', storageService.getPairingCode() ?? 'None'),
          ]),

          const SizedBox(height: 8),

          // Sync Stats
          _buildSection('Sync Stats', [
            _buildInfoRow('Sent Touch', '$_sentTouches'),
            _buildInfoRow('Recv Touch', '$_receivedTouches'),
            _buildInfoRow('Sent Gesture', '$_sentGestures'),
            _buildInfoRow('Recv Gesture', '$_receivedGestures'),
            _buildInfoRow('Last Sync', _formatTime(_lastSyncTime)),
          ]),

          const SizedBox(height: 12),

          // Test Actions
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Send Test',
                  Icons.send,
                  _sendTestTouch,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton('Clear', Icons.refresh, _clearStats),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        ...children,
      ],
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.orange, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _truncate(String? value) {
    if (value == null) return 'None';
    if (value.length <= 8) return value;
    return '${value.substring(0, 8)}...';
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'Never';
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  void _sendTestTouch() {
    _sentTouches++;
    setState(() {});

    // Send a test gesture
    SocketService.instance.sendTouch(
      TouchEvent.create(x: 0.5, y: 0.5, type: TouchType.tap),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test touch sent!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _clearStats() {
    setState(() {
      _sentTouches = 0;
      _receivedTouches = 0;
      _sentGestures = 0;
      _receivedGestures = 0;
      _lastSyncTime = null;
    });
  }
}
