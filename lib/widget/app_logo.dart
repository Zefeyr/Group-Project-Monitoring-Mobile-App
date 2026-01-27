import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';

class AppLogo extends StatelessWidget {
  final double size;
  final double progress;

  const AppLogo({
    super.key,
    this.size = 120,
    this.progress = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: SizedBox(
          width: size, 
          height: size,
          child: CustomPaint(
            painter: LogoPainter(progress),
          ),
        ),
      ),
    );
  }
}

class LogoPainter extends CustomPainter {
  final double progress;

  LogoPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * 0.05 // Scale stroke with size
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2; 

    Path path = Path();

    // 1. Hexagon Vertices (Pointy top)
    List<Offset> hexPoints = [];
    for (int i = 0; i < 6; i++) {
       double angle = -math.pi / 2 + (math.pi / 3 * i);
       hexPoints.add(Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
       ));
    }

    // 2. Inner Triangle Vertices
    List<Offset> innerPoints = [];
    for (int i = 0; i < 3; i++) {
        double angle = (-math.pi / 2 + math.pi/3) + (2 * math.pi / 3 * i); 
        innerPoints.add(Offset(
           center.dx + (radius * 0.4) * math.cos(angle),
           center.dy + (radius * 0.4) * math.sin(angle),
        ));
    }

    // -- DRAWING SEQUENCE --
    // Make it a single continuous path for cool animation if needed, 
    // or just append shapes.

    // Hexagon
    path.moveTo(hexPoints[0].dx, hexPoints[0].dy);
    for(int i=1; i<6; i++) path.lineTo(hexPoints[i].dx, hexPoints[i].dy);
    path.close();

    // Inner Triangle
    path.moveTo(innerPoints[0].dx, innerPoints[0].dy);
    path.lineTo(innerPoints[1].dx, innerPoints[1].dy);
    path.lineTo(innerPoints[2].dx, innerPoints[2].dy);
    path.close();

    // Connections
    path.moveTo(innerPoints[0].dx, innerPoints[0].dy); path.lineTo(hexPoints[0].dx, hexPoints[0].dy);
    path.moveTo(innerPoints[0].dx, innerPoints[0].dy); path.lineTo(hexPoints[1].dx, hexPoints[1].dy);
    path.moveTo(innerPoints[0].dx, innerPoints[0].dy); path.lineTo(hexPoints[2].dx, hexPoints[2].dy);

    path.moveTo(innerPoints[1].dx, innerPoints[1].dy); path.lineTo(hexPoints[2].dx, hexPoints[2].dy);
    path.moveTo(innerPoints[1].dx, innerPoints[1].dy); path.lineTo(hexPoints[3].dx, hexPoints[3].dy);
    path.moveTo(innerPoints[1].dx, innerPoints[1].dy); path.lineTo(hexPoints[4].dx, hexPoints[4].dy);

    path.moveTo(innerPoints[2].dx, innerPoints[2].dy); path.lineTo(hexPoints[4].dx, hexPoints[4].dy);
    path.moveTo(innerPoints[2].dx, innerPoints[2].dy); path.lineTo(hexPoints[5].dx, hexPoints[5].dy);
    path.moveTo(innerPoints[2].dx, innerPoints[2].dy); path.lineTo(hexPoints[0].dx, hexPoints[0].dy);

    // -- RENDER --
    PathMetrics pathMetrics = path.computeMetrics();
    for (PathMetric pathMetric in pathMetrics) {
      double extractPathLength = pathMetric.length * progress;
      Path extractPath = pathMetric.extractPath(0.0, extractPathLength);
      canvas.drawPath(extractPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant LogoPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
