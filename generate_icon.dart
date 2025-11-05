import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:io';

Future<void> generateAppIcon() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = 1024.0;
  
  // Background with rounded rectangle and gradient (matching the provided image)
  final gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF9C40FF), // Purple
      Color(0xFF4F46E5), // Indigo Blue
    ],
  );
  
  final paint = Paint()
    ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size, size));
  
  final rect = RRect.fromRectAndRadius(
    Rect.fromLTWH(0, 0, size, size),
    Radius.circular(size * 0.22), // iOS style rounded corners
  );
  
  canvas.drawRRect(rect, paint);
  
  // Draw shopping cart icon (white) - matching the provided design
  final cartPaint = Paint()
    ..color = Colors.white
    ..strokeWidth = size * 0.06
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  
  final centerX = size / 2;
  final centerY = size / 2 - size * 0.05; // Slightly higher
  final cartSize = size * 0.4;
  
  // Cart handle (curved)
  final handlePath = Path();
  handlePath.moveTo(centerX - cartSize * 0.7, centerY - cartSize * 0.4);
  handlePath.quadraticBezierTo(
    centerX - cartSize * 0.8, centerY - cartSize * 0.2,
    centerX - cartSize * 0.6, centerY - cartSize * 0.1
  );
  canvas.drawPath(handlePath, cartPaint);
  
  // Cart basket outline
  final basketPath = Path();
  basketPath.moveTo(centerX - cartSize * 0.6, centerY - cartSize * 0.1);
  basketPath.lineTo(centerX + cartSize * 0.6, centerY - cartSize * 0.1);
  basketPath.lineTo(centerX + cartSize * 0.4, centerY + cartSize * 0.4);
  basketPath.lineTo(centerX - cartSize * 0.4, centerY + cartSize * 0.4);
  basketPath.close();
  canvas.drawPath(basketPath, cartPaint);
  
  // Cart bottom line
  canvas.drawLine(
    Offset(centerX - cartSize * 0.6, centerY + cartSize * 0.5),
    Offset(centerX + cartSize * 0.5, centerY + cartSize * 0.5),
    cartPaint,
  );
  
  // Cart wheels (filled circles with white outline)
  final wheelPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;
  

      
  // Left wheel
  canvas.drawCircle(
    Offset(centerX - cartSize * 0.25, centerY + cartSize * 0.75),
    size * 0.045,
    wheelPaint,
  );
  canvas.drawCircle(
    Offset(centerX - cartSize * 0.25, centerY + cartSize * 0.75),
    size * 0.02,
    Paint()..color = Color(0xFF9C40FF)..style = PaintingStyle.fill,
  );
  
  // Right wheel
  canvas.drawCircle(
    Offset(centerX + cartSize * 0.25, centerY + cartSize * 0.75),
    size * 0.045,
    wheelPaint,
  );
  canvas.drawCircle(
    Offset(centerX + cartSize * 0.25, centerY + cartSize * 0.75),
    size * 0.02,
    Paint()..color = Color(0xFF9C40FF)..style = PaintingStyle.fill,
  );
  
  final picture = recorder.endRecording();
  final img = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  
  final file = File('assets/icons/app_icon.png');
  await file.writeAsBytes(byteData!.buffer.asUint8List());
  
  print('✅ Generated app icon successfully!');
}

void main() async {
  await generateAppIcon();
}
