import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Üstünde sürekli görünen yazı etiketi olan özel harita marker'ı üretir.
/// [text] etiket yazısı, [color] pin + etiket rengi.
Future<BitmapDescriptor> createLabeledMarker({
  required String text,
  required Color color,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Yazı stilini hazırla
  final textPainter = TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  // Etiket kutusu ölçüleri
  const hPad = 16.0;
  const vPad = 9.0;
  final labelW = textPainter.width + hPad * 2;
  final labelH = textPainter.height + vPad * 2;

  // Pin (alttaki damla) ölçüleri
  const pinR = 16.0;
  const pinTail = 13.0;
  const gap = 10.0;

  final totalW = labelW > pinR * 2 ? labelW : pinR * 2;
  final totalH = labelH + gap + pinR * 2 + pinTail;

  final centerX = totalW / 2;

  // ── Etiket kutusu (üstte, yuvarlatılmış) ──
  final labelRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(centerX - labelW / 2, 0, labelW, labelH),
    const Radius.circular(9),
  );
  final labelPaint = Paint()..color = color;
  canvas.drawRRect(labelRect, labelPaint);

  // Yazıyı kutuya ortala
  textPainter.paint(
    canvas,
    Offset(centerX - textPainter.width / 2, vPad),
  );

  // ── Pin (altta daire + sivri uç) ──
  final pinCenterY = labelH + gap + pinR;
  final pinPaint = Paint()..color = color;

  // Sivri uç (üçgen)
  final tailPath = Path()
    ..moveTo(centerX - 7, pinCenterY + pinR - 3)
    ..lineTo(centerX + 7, pinCenterY + pinR - 3)
    ..lineTo(centerX, pinCenterY + pinR + pinTail)
    ..close();
  canvas.drawPath(tailPath, pinPaint);

  // Daire
  canvas.drawCircle(Offset(centerX, pinCenterY), pinR, pinPaint);
  // Daire içi beyaz nokta
  canvas.drawCircle(
      Offset(centerX, pinCenterY), pinR * 0.45, Paint()..color = Colors.white);

  // Resme çevir
  final picture = recorder.endRecording();
  final img = await picture.toImage(totalW.ceil(), totalH.ceil());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
}

/// "Test Kurye" -> "Test K." şeklinde kısaltır.
String shortName(String? full) {
  if (full == null || full.trim().isEmpty) return 'Kurye';
  final parts = full.trim().split(RegExp(r"\s+"));
  if (parts.length == 1) return parts.first;
  final first = parts.first;
  final lastInitial = parts.last.isNotEmpty ? parts.last[0] : '';
  return '$first $lastInitial.';
}
