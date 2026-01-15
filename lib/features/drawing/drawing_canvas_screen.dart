import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/drawing_service.dart';
import '../../shared/widgets/glass_card.dart';

/// Shared drawing canvas screen
class DrawingCanvasScreen extends StatefulWidget {
  const DrawingCanvasScreen({super.key});

  @override
  State<DrawingCanvasScreen> createState() => _DrawingCanvasScreenState();
}

class _DrawingCanvasScreenState extends State<DrawingCanvasScreen> {
  final List<Color> _colorOptions = [
    const Color(0xFFFF6B9D), // Pink
    const Color(0xFFFF4757), // Red
    const Color(0xFFFFA502), // Orange
    const Color(0xFFFFD93D), // Yellow
    const Color(0xFF6BCB77), // Green
    const Color(0xFF4ECDC4), // Teal
    const Color(0xFF45AAF2), // Blue
    const Color(0xFFA55EEA), // Purple
    const Color(0xFFFFFFFF), // White
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Text('✏️ ', style: TextStyle(fontSize: 20)),
            Text(
              'Draw Together',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.undo, color: AppColors.textSecondary),
            onPressed: () {
              HapticFeedback.lightImpact();
              DrawingService.instance.undoLastStroke();
            },
            tooltip: 'Undo',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppColors.textSecondary),
            onPressed: _showClearDialog,
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: Column(
        children: [
          // Canvas area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ListenableBuilder(
                  listenable: DrawingService.instance,
                  builder: (context, _) {
                    return GestureDetector(
                      onPanStart: (details) {
                        HapticFeedback.selectionClick();
                        DrawingService.instance.startStroke(
                          details.localPosition,
                        );
                      },
                      onPanUpdate: (details) {
                        DrawingService.instance.addPoint(details.localPosition);
                      },
                      onPanEnd: (_) {
                        DrawingService.instance.endStroke();
                      },
                      child: CustomPaint(
                        painter: _DrawingPainter(
                          strokes: DrawingService.instance.strokes,
                          currentStroke: DrawingService.instance.currentStroke,
                        ),
                        size: Size.infinite,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Tools bar
          _buildToolsBar(),
        ],
      ),
    );
  }

  Widget _buildToolsBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: ListenableBuilder(
          listenable: DrawingService.instance,
          builder: (context, _) {
            final currentColor = DrawingService.instance.currentColor;
            final strokeWidth = DrawingService.instance.currentStrokeWidth;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Color picker
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _colorOptions.map((color) {
                    final isSelected = currentColor.value == color.value;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        DrawingService.instance.setColor(color);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isSelected ? 36 : 28,
                        height: isSelected ? 36 : 28,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Stroke width slider
                Row(
                  children: [
                    Icon(Icons.lens, size: 8, color: AppColors.textMuted),
                    Expanded(
                      child: Slider(
                        value: strokeWidth,
                        min: 2,
                        max: 20,
                        activeColor: currentColor,
                        inactiveColor: AppColors.textMuted.withValues(
                          alpha: 0.3,
                        ),
                        onChanged: (value) {
                          DrawingService.instance.setStrokeWidth(value);
                        },
                      ),
                    ),
                    Icon(Icons.lens, size: 20, color: AppColors.textMuted),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Clear Canvas',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'This will clear all drawings. Are you sure?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              DrawingService.instance.clearCanvas();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400]),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for drawing strokes
class _DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;

  _DrawingPainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw all completed strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    // Draw current stroke being drawn
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }
  }

  void _drawStroke(Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.length < 2) return;

    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(stroke.points.first.dx, stroke.points.first.dy);

    for (int i = 1; i < stroke.points.length; i++) {
      final p0 = stroke.points[i - 1];
      final p1 = stroke.points[i];

      // Use quadratic bezier for smoother lines
      final midPoint = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, midPoint.dx, midPoint.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    return oldDelegate.strokes.length != strokes.length ||
        oldDelegate.currentStroke != currentStroke;
  }
}
