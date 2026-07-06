import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/colors.dart';

class DropdownArrow extends StatelessWidget {
  const DropdownArrow({super.key});

  @override
  Widget build(BuildContext context) {
    if (MenuController.maybeIsOpenOf(context) ?? false) {
      return const Icon(Symbols.arrow_drop_up, size: 18, color: FloogleColors.grey);
    } else {
      return const Icon(Symbols.arrow_drop_down, size: 18, color: FloogleColors.grey);
    }
  }
}
