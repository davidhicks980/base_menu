import 'package:flutter/widgets.dart';

import '../../shared/theme.dart';

class SequoiaMenuDivider extends StatelessWidget {
  const SequoiaMenuDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: PhysicalPixelDivider(
        orientation: Axis.horizontal,
        color: Color(0x38FFFFFF),
        thickness: 2,
        crossAxisExtent: 8,
        indent: 10,
        endIndent: 10,
      ),
    );
  }
}
