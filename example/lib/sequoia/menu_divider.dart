import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class SequoiaMenuDivider extends StatelessWidget {
  const SequoiaMenuDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final physicalPixel = 2.0 / View.of(context).devicePixelRatio;

    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0),
        child: Container(height: physicalPixel, color: const Color(0x38FFFFFF)),
      ),
    );
  }
}
