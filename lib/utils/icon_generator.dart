import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

class IconGenerator {
  static Future<Uint8List> generateIcon() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = 1024.0;
    
    // Background gradient (purple to blue)
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF8B5CF6), // Purple
        Color(0xFF06B6D4), // Cyan
      ],
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size, size));
    
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size, size),
      Radius.circular(size * 0.22), // Rounded corners
    );
    
    canvas.drawRRect(rect, paint);
    
    // Draw shopping cart icon (white)
    final cartPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = size * 0.06
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    final centerX = size / 2;
    final centerY = size / 2;
    final cartSize = size * 0.4;
    
    // Cart body
    final path = Path();
    path.moveTo(centerX - cartSize / 2, centerY - cartSize / 4);
    path.lineTo(centerX - cartSize / 3, centerY - cartSize / 4);
    path.lineTo(centerX + cartSize / 3, centerY - cartSize / 4);
    path.lineTo(centerX + cartSize / 2.5, centerY + cartSize / 4);
    path.lineTo(centerX - cartSize / 4, centerY + cartSize / 4);
    path.close();
    
    canvas.drawPath(path, cartPaint);
    
    // Cart handle
    canvas.drawLine(
      Offset(centerX - cartSize / 2, centerY - cartSize / 4),
      Offset(centerX - cartSize / 1.5, centerY - cartSize / 2),
      cartPaint,
    );
    
    // Cart wheels
    final wheelPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
      
    canvas.drawCircle(
      Offset(centerX - cartSize / 8, centerY + cartSize / 2.5),
      size * 0.03,
      wheelPaint,
    );
    
    canvas.drawCircle(
      Offset(centerX + cartSize / 4, centerY + cartSize / 2.5),
      size * 0.03,
      wheelPaint,
    );
    
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
