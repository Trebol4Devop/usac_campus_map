import 'package:flutter/material.dart';
import '../../models/building_3d_model.dart';
import '../themes/usac_map_theme.dart';

class Building3DViewer extends StatefulWidget {
  final Building3DModel model;
  final UsacMapTheme theme;
  final double initialRotation;
  final double initialTilt;
  final double initialScale;

  const Building3DViewer({
    super.key,
    required this.model,
    this.theme = const UsacMapTheme(),
    this.initialRotation = 45.0,
    this.initialTilt = 30.0,
    this.initialScale = 2.5,
  });

  @override
  State<Building3DViewer> createState() => _Building3DViewerState();
}

class _Building3DViewerState extends State<Building3DViewer> {
  late double _rotation;
  late double _tilt;
  late double _scale;

  @override
  void initState() {
    super.initState();
    _rotation = widget.initialRotation;
    _tilt = widget.initialTilt;
    _scale = widget.initialScale;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleUpdate: (details) {
        setState(() {
          _rotation += details.focalPointDelta.dx * 0.6;
          _tilt = (_tilt - details.focalPointDelta.dy * 0.4).clamp(5.0, 85.0);
          if (details.scale != 1.0) {
            _scale = (_scale * details.scale).clamp(0.8, 8.0);
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: widget.theme.primaryColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Stack(
          children: [
            CustomPaint(
              size: Size.infinite,
              painter: _Building3DPainter(
                model: widget.model,
                theme: widget.theme,
                rotationAngle: _rotation,
                tiltAngle: _tilt,
                scale: _scale,
              ),
            ),
            Positioned(
              left: 16.0,
              top: 16.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.model.buildingName,
                    style: TextStyle(
                      color: widget.theme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    '${widget.model.floors} niveles • ${widget.model.heightMeters.toStringAsFixed(1)} m de altura',
                    style: TextStyle(
                      color: widget.theme.primaryColor.withValues(alpha: 0.7),
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12.0,
              bottom: 12.0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.zoom_in, size: 20.0),
                    onPressed: () {
                      setState(() {
                        _scale = (_scale * 1.2).clamp(0.8, 8.0);
                      });
                    },
                  ),
                  const SizedBox(width: 8.0),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.zoom_out, size: 20.0),
                    onPressed: () {
                      setState(() {
                        _scale = (_scale / 1.2).clamp(0.8, 8.0);
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Building3DPainter extends CustomPainter {
  final Building3DModel model;
  final UsacMapTheme theme;
  final double rotationAngle;
  final double tiltAngle;
  final double scale;

  _Building3DPainter({
    required this.model,
    required this.theme,
    required this.rotationAngle,
    required this.tiltAngle,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2.0, size.height / 2.0 + 30.0);

    final wallPaint = Paint()
      ..color = theme.primaryColor.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final wallBorderPaint = Paint()
      ..color = theme.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final roofPaint = Paint()
      ..color = theme.accentColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final roofBorderPaint = Paint()
      ..color = theme.accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final face in model.wallFaces) {
      final offsets = face.toScreenOffsets(
        rotationAngle: rotationAngle,
        tiltAngle: tiltAngle,
        scale: scale,
        origin: origin,
      );

      if (offsets.length < 3) continue;

      final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
      for (var i = 1; i < offsets.length; i++) {
        path.lineTo(offsets[i].dx, offsets[i].dy);
      }
      path.close();

      canvas.drawPath(path, wallPaint);
      canvas.drawPath(path, wallBorderPaint);
    }

    final roofOffsets = model.roofFace.toScreenOffsets(
      rotationAngle: rotationAngle,
      tiltAngle: tiltAngle,
      scale: scale,
      origin: origin,
    );

    if (roofOffsets.length >= 3) {
      final roofPath = Path()
        ..moveTo(roofOffsets.first.dx, roofOffsets.first.dy);
      for (var i = 1; i < roofOffsets.length; i++) {
        roofPath.lineTo(roofOffsets[i].dx, roofOffsets[i].dy);
      }
      roofPath.close();

      canvas.drawPath(roofPath, roofPaint);
      canvas.drawPath(roofPath, roofBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _Building3DPainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.tiltAngle != tiltAngle ||
        oldDelegate.scale != scale ||
        oldDelegate.model != model;
  }
}
