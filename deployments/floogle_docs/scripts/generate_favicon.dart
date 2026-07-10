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

      double iconHeight;
      double iconWidth;
      // Scale height to 85% of the total dimension to create a margin
      if (fileName.contains("favicon")) {
        iconHeight = dimension;
        iconWidth = iconHeight * 0.75;
      } else {
        iconHeight = dimension * 0.7;
        iconWidth = iconHeight * 0.75;
      }

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // Center the icon both horizontally and vertically
      final dx = (dimension - iconWidth) / 2;
      final dy = (dimension - iconHeight) / 2;
      canvas.translate(dx, dy);

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
