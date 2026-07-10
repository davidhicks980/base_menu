import 'dart:io';
import 'dart:ui';

import 'package:base_menu_demo/floogle_docs/src/widgets/floogle_docs_logo.dart';
import 'package:flutter_test/flutter_test.dart';

// Forgive me
Future<void> main() async {
  test('Generate favicons', () async {
    final sizes = {
      'favicon.png': 32.0,
      'icons/Icon-192.png': 192.0,
      'icons/Icon-512.png': 512.0,
      'icons/Icon-maskable-192.png': 192.0,
      'icons/Icon-maskable-512.png': 512.0,
    };

    for (final entry in sizes.entries) {
      final fileName = entry.key;
      final dimension = entry.value;

      final iconWidth = dimension * 0.75;
      final iconHeight = dimension;

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      canvas.translate((dimension - iconWidth) / 2, 0);

      FloogleDocsPainter().paint(canvas, Size(iconWidth, iconHeight));

      final picture = recorder.endRecording();
      final img = await picture.toImage(dimension.toInt(), dimension.toInt());
      final byteData = await img.toByteData(format: ImageByteFormat.png);

      final file = File('web/$fileName');
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      await file.writeAsBytes(byteData!.buffer.asUint8List());
    }
  });
}
