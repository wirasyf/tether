import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Connection status bar widget
class ConnectionStatus extends StatelessWidget {
  final bool isConnected;
  final bool isPartnerOnline;
  final String? partnerName;
  final VoidCallback? onTap;
  
  const ConnectionStatus({
    super.key,
    required this.isConnected,
    required this.isPartnerOnline,
    this.partnerName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _statusColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusDot(),
            const SizedBox(width: 8),
            Text(
              _statusText,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _statusColor,
        boxShadow: [
          BoxShadow(
            color: _statusColor.withValues(alpha: 0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
  
  Color get _statusColor {
    if (!isConnected) return AppColors.error;
    if (isPartnerOnline) return AppColors.success;
    return AppColors.warning;
  }
  
  String get _statusText {
    if (!isConnected) return 'Connecting...';
    if (isPartnerOnline) {
      return partnerName != null ? '$partnerName is online' : 'Partner online';
    }
    return partnerName != null ? '$partnerName is away' : 'Partner away';
  }
}
