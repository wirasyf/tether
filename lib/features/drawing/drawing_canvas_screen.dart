import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
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
  Future<void> _saveCanvas() async {
    try {
      if (DrawingService.instance.strokes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Canvas is empty!')));
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saving drawing...')));
      }

      // Create a picture recorder and canvas
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = context.size ?? const Size(1080, 1920);

      // Draw white background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white,
      );

      // Draw strokes
      final painter = _DrawingPainter(strokes: DrawingService.instance.strokes);
      painter.paint(canvas, size);

      // End recording and convert to image
      final picture = recorder.endRecording();
      final img = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );
      final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

      if (pngBytes != null) {
        if (kIsWeb) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Save to Gallery is only available on mobile devices',
                ),
              ),
            );
          }
          return;
        }

        final dir = await getTemporaryDirectory();
        final file = File(
          '${dir.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await file.writeAsBytes(pngBytes.buffer.asUint8List());

        // Save to gallery
        await Gal.putImage(file.path);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved to Gallery! 🖼️')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving drawing: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Pick a Color',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: DrawingService.instance.currentColor,
            onColorChanged: (color) {
              DrawingService.instance.setColor(color);
            },
            paletteType: PaletteType.hueWheel,
            enableAlpha: false,
            labelTypes: const [],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
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
            icon: Icon(Icons.download_rounded, color: AppColors.primary),
            onPressed: () {
              HapticFeedback.lightImpact();
              _saveCanvas();
            },
            tooltip: 'Save to Gallery',
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
                Row(
                  children: [
                    // Color Picker
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _showColorPicker();
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: currentColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: currentColor.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Slider
                    Expanded(
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: currentColor.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: currentColor,
                                  inactiveTrackColor: currentColor.withValues(
                                    alpha: 0.3,
                                  ),
                                  thumbColor: Colors.white,
                                  trackHeight: 2, // Thinner track
                                ),
                                child: Slider(
                                  value: strokeWidth,
                                  min: 2,
                                  max: 30,
                                  onChanged: (value) {
                                    DrawingService.instance.setStrokeWidth(
                                      value,
                                    );
                                  },
                                ),
                              ),
                            ),
                            // Preview circle
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              child: Container(
                                width: strokeWidth, // Real-time preview size
                                height: strokeWidth,
                                decoration: BoxDecoration(
                                  color: currentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Undo Button
                    IconButton(
                      icon: const Icon(Icons.undo_rounded),
                      color: AppColors.textSecondary,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        DrawingService.instance.undoLastStroke();
                      },
                    ),

                    // Clear Button
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: AppColors.error,
                      onPressed: _showClearDialog,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
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
